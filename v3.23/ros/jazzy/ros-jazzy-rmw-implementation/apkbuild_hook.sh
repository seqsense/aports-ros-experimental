apkbuild_hook() {
  depends="${depends} ros-jazzy-rmw-fastrtps-cpp ros-jazzy-rmw-cyclonedds-cpp"
  makedepends="${makedepends} !ros-jazzy-rmw-connextdds !ros-jazzy-rmw-connextdds-dev"
  depends_dev="${depends} ros-jazzy-ament-index-cpp-dev ros-jazzy-rmw-fastrtps-cpp-dev ros-jazzy-rmw-cyclonedds-cpp-dev"
}
