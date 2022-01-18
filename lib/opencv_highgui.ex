defmodule OpenCV.Gui do
  @moduledoc false

  def imshow(winname, mat) when is_binary(winname) do
    :erl_cv_nif.evision_cv_imshow(winname: winname, mat: mat)
  end

  def waitkey(delay) when is_integer(delay) do
    :erl_cv_nif.evision_cv_waitkey(delay: delay)
  end

  def destroy_window(winname) when is_binary(winname) do
    :erl_cv_nif.evision_cv_destroy_window(winname: winname)
  end

  def destroy_all_windows do
    :erl_cv_nif.evision_cv_destroy_all_windows()
  end
end