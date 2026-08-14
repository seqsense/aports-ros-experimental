apkbuild_hook() {
  # qt_gui_cpp_shiboken's shiboken_helper.cmake requires
  # find_package(Python3 COMPONENTS Development)
  makedepends="${makedepends} python3-dev"
}
