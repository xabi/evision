cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
project(evision)

if(EVISION_PREFER_PRECOMPILED STREQUAL "true")
    message(STATUS "EVISION_PREFER_PRECOMPILED is true: try to download and use the precompiled library")

    string(TOLOWER "${CMAKE_SYSTEM_NAME}" PRECOMPILED_SYSTEM_NAME)
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" PRECOMPILED_PROCESSOR_ARCH)
    set(PRECOMPILE_PKG_NAME "evision-${PRECOMPILED_SYSTEM_NAME}-${PRECOMPILED_PROCESSOR_ARCH}-${EVISION_PRECOMPILED_VERSION}")
    set(PRECOMPILE_PKG_FILENAME "${PRECOMPILE_PKG_NAME}.tar.gz")
    set(PRECOMPILE_PKG_URL "https://github.com/cocoa-xu/evision/releases/download/${EVISION_PRECOMPILED_VERSION}/${PRECOMPILE_PKG_FILENAME}")
    set(PRECOMPILE_PKG_CACHE_FILE "${EVISION_PRECOMPILED_CACHE_DIR}/${PRECOMPILE_PKG_FILENAME}")
    set(PRECOMPILE_PKG_PRIV_DIR "${EVISION_PRECOMPILED_CACHE_DIR}/${PRECOMPILE_PKG_NAME}/priv")
    set(PRECOMPILE_PKG_GENERATED_ELIXIR_SRC_DIR "${EVISION_PRECOMPILED_CACHE_DIR}/${PRECOMPILE_PKG_NAME}/generated")
    set(EVISION_SO_FILE "${PRIV_DIR}/evision.so")

    set(PRECOMPILE_PKG_NEEDS_DOWNLOAD YES)
    set(PRECOMPILE_PKG_NEEDS_UNARCHIVE YES)
    set(PRECOMPILE_PKG_NEEDS_COPY YES)

    # remove failed downloads (i.e., filesize is 0)
    if(WIN32)
        execute_process(COMMAND powershell -command "if (Test-Path \"${PRECOMPILE_PKG_CACHE_FILE}\") { if ((Get-Item \"${PRECOMPILE_PKG_CACHE_FILE}\").length -eq 0) { Remove-Item \"${PRECOMPILE_PKG_CACHE_FILE}\" -Force } }")
    else()
        execute_process(COMMAND bash -c "find \"${EVISION_PRECOMPILED_CACHE_DIR}\" -name \"${PRECOMPILE_PKG_FILENAME}\" -size 0 -delete")
    endif()

    if(EXISTS "${GENERATED_ELIXIR_SRC_DIR}")
        if(EXISTS "${EVISION_SO_FILE}")
            set(PRECOMPILE_PKG_NEEDS_DOWNLOAD NO)
            set(PRECOMPILE_PKG_NEEDS_UNARCHIVE NO)
            set(PRECOMPILE_PKG_NEEDS_COPY NO)
        endif()
    endif()

    if(EXISTS "${PRECOMPILE_PKG_CACHE_FILE}")
        set(PRECOMPILE_PKG_NEEDS_DOWNLOAD NO)
    endif()

    if(EXISTS "${EVISION_PRECOMPILED_CACHE_DIR}/${PRECOMPILE_PKG_NAME}")
        set(PRECOMPILE_PKG_NEEDS_UNARCHIVE NO)
    endif()

    # skip download if "${GENERATED_ELIXIR_SRC_DIR}" and "${EVISION_SO_FILE}" exist
    if(PRECOMPILE_PKG_NEEDS_COPY AND PRECOMPILE_PKG_NEEDS_DOWNLOAD)
        if(EXISTS "${PRECOMPILE_PKG_CACHE_FILE}")
            file(SHA512 ${PRECOMPILE_PKG_CACHE_FILE} PRECOMPILE_PKG_FILE_SHA512)
            message("PRECOMPILE_PKG_FILE_SHA512: ${PRECOMPILE_PKG_FILE_SHA512}")
        else()
            message(STATUS "precompiled tarball URL: ${PRECOMPILE_PKG_URL}")
            message(STATUS "precompiled tarball cache file: ${PRECOMPILE_PKG_CACHE_FILE}")
            file(DOWNLOAD ${PRECOMPILE_PKG_URL} "${PRECOMPILE_PKG_CACHE_FILE}" SHOW_PROGRESS STATUS DOWNLOAD_STATUS)
            list(GET DOWNLOAD_STATUS 0 DOWNLOAD_STATUS_CODE)
            if(DOWNLOAD_STATUS_CODE EQUAL 0)
                file(SHA512 ${PRECOMPILE_PKG_CACHE_FILE} PRECOMPILE_PKG_FILE_SHA512)
                message("PRECOMPILE_PKG_FILE_SHA512: ${PRECOMPILE_PKG_FILE_SHA512}")
            else()
                # remove failed downloads
                if(WIN32)
                    execute_process(COMMAND powershell -command "if (Test-Path \"${PRECOMPILE_PKG_CACHE_FILE}\") { Remove-Item \"${PRECOMPILE_PKG_CACHE_FILE}\" -Force }")
                else()
                    execute_process(COMMAND bash -c "rm -f \"${PRECOMPILE_PKG_CACHE_FILE}\"")
                endif()

                list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR_MSG)
                message(FATAL_ERROR "Cannot download precompiled package from ${PRECOMPILE_PKG_URL}: ${DOWNLOAD_ERROR_MSG}\nYou may download it manually and put it in ${PRIV_DIR}/${PRECOMPILE_PKG_NAME}")
            endif()
        endif()
    endif()

    # skip unarchive if "${GENERATED_ELIXIR_SRC_DIR}" and "${EVISION_SO_FILE}" exist
    if(PRECOMPILE_PKG_NEEDS_COPY AND PRECOMPILE_PKG_NEEDS_UNARCHIVE)
        if(WIN32)
            execute_process(COMMAND powershell -command "cd ${EVISION_PRECOMPILED_CACHE_DIR}; tar -xf ${PRECOMPILE_PKG_CACHE_FILE}" RESULT_VARIABLE UNARCHIVE_STATUS)
        else()
            execute_process(COMMAND bash -c "cd ${EVISION_PRECOMPILED_CACHE_DIR} && tar xzf ${PRECOMPILE_PKG_CACHE_FILE}" RESULT_VARIABLE UNARCHIVE_STATUS)
        endif()
        if(UNARCHIVE_STATUS STREQUAL "0")
            message("Successfully unarchived precompiled package")
        else()
            message(FATAL_ERROR "Failed to unarchive precompiled package: ${PRECOMPILE_PKG_FILEPATH}")
        endif()
    endif()

    if(PRECOMPILE_PKG_NEEDS_COPY)
        if(WIN32)
            execute_process(COMMAND powershell -command "Copy-Item -Path ${PRECOMPILE_PKG_PRIV_DIR}/* ${PRIV_DIR} -Recurse -Force; if (Test-Path \"${GENERATED_ELIXIR_SRC_DIR}\") { Remove-Item \"${GENERATED_ELIXIR_SRC_DIR}\" -Recurse -Force }; Copy-Item -Path \"${PRECOMPILE_PKG_GENERATED_ELIXIR_SRC_DIR}\" \"${GENERATED_ELIXIR_SRC_DIR}\" -Recurse -Force" RESULT_VARIABLE COPY_STATUS)
        else()
            execute_process(COMMAND bash -c "cp -a ${PRECOMPILE_PKG_PRIV_DIR}/* ${PRIV_DIR} && rm -rf ${GENERATED_ELIXIR_SRC_DIR} && cp -a ${PRECOMPILE_PKG_GENERATED_ELIXIR_SRC_DIR} ${GENERATED_ELIXIR_SRC_DIR}" RESULT_VARIABLE COPY_STATUS)
        endif()
        if(COPY_STATUS STREQUAL "0")
            message(STATUS "Successfully restored precompiled library")
        else()
            message(FATAL_ERROR "Failed to copy precompiled files:\n - from ${PRECOMPILE_PKG_PRIV_DIR}/* to ${PRIV_DIR}\n - from ${PRECOMPILE_PKG_GENERATED_ELIXIR_SRC_DIR} to ${GENERATED_ELIXIR_SRC_DIR}")
        endif()
    endif()
else()
    find_package(OpenCV REQUIRED PATHS "${PRIV_DIR}/" NO_DEFAULT_PATH)
    include_directories("${OpenCV_INCLUDE_DIRS}")

    if(WIN32)
        execute_process(COMMAND "rmdir ${GENERATED_ELIXIR_SRC_DIR} /s /q && mkdir ${GENERATED_ELIXIR_SRC_DIR}")
        message("enabled modules: ${ENABLED_CV_MODULES}")
        execute_process(COMMAND python3.exe "${PY_SRC}\\gen2.py" "${C_SRC}" "${GENERATED_ELIXIR_SRC_DIR}" "${C_SRC}/headers.txt" "${ENABLED_CV_MODULES}" RESULT_VARIABLE STATUS)
    else()
        execute_process(COMMAND bash -c "rm -rf ${GENERATED_ELIXIR_SRC_DIR} && mkdir -p ${GENERATED_ELIXIR_SRC_DIR}")
        message("enabled modules: ${ENABLED_CV_MODULES}")
        execute_process(COMMAND bash -c "python3 ${PY_SRC}/gen2.py ${C_SRC} ${GENERATED_ELIXIR_SRC_DIR} ${C_SRC}/headers.txt ${ENABLED_CV_MODULES}" RESULT_VARIABLE STATUS)
    endif()
    if(STATUS STREQUAL "0")
        message("Successfully generated Erlang/Elixir bindings")
    else()
        message(FATAL_ERROR "Failed to generate Erlang/Elixir bindings")
    endif()

    if(WIN32)
        string(REPLACE "\\" "/" C_SRC "${C_SRC}")
    endif()
    file(GLOB evision_bindings_main "${C_SRC}/*.hpp" "${C_SRC}/*.h" "${C_SRC}/*.cpp")
    file(GLOB evision_custom_headers "${C_SRC}/evision_custom_headers/*.hpp")
    file(GLOB evision_modules "${C_SRC}/modules/*.hpp" "${C_SRC}/modules/*.h")

    add_library(evision SHARED
        ${evision_bindings_main}
        ${evision_custom_headers}
        ${evision_modules}
    )
    target_link_libraries(evision "${OpenCV_LIBS}")
    set_property(TARGET evision PROPERTY CXX_STANDARD 14)
    set_target_properties(evision PROPERTIES PREFIX "")
    set_target_properties(evision PROPERTIES SUFFIX ".so")

    if(${CMAKE_VERSION} VERSION_GREATER "3.9")
        cmake_policy(SET CMP0068 NEW)
    endif()
    set_target_properties(evision PROPERTIES
        INSTALL_RPATH_USE_LINK_PATH TRUE
        BUILD_WITH_INSTALL_RPATH TRUE
    )

    if(UNIX AND NOT APPLE)
        set_target_properties(evision PROPERTIES INSTALL_RPATH "\$ORIGIN/lib")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-but-set-variable")
    elseif(UNIX AND APPLE)
        # Although the compiler complains about not using these,
        # things only work with them set
        set(CMAKE_SHARED_LINKER_FLAGS "-flat_namespace -undefined suppress -undefined dynamic_lookup")
        set_target_properties(evision PROPERTIES INSTALL_RPATH "@loader_path/lib")
    endif()

    include_directories(${ERTS_INCLUDE_DIR})
    if(WIN32)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj /wd4996 /wd4267 /wd4068")
    else()
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -O3 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wno-deprecated-declarations -Wno-unused-but-set-variable")
    endif()
endif()
