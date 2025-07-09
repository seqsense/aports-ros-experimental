apkbuild_hook() {
  makedepends="${makedepends} ros-jazzy-launch-ros"
  export MAKEFLAGS="-j1 -l1"
}
