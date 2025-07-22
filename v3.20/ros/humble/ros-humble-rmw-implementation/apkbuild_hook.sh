apkbuild_hook() {
  depends="${depends} ros-humble-rmw-fastrtps-cpp ros-humble-rmw-cyclonedds-cpp"
  makedepends="${makedepends} !ros-humble-rmw-connextdds !ros-humble-rmw-connextdds-dev"
  depends_dev="${depends_dev} ros-humble-ament-index-cpp-dev ros-humble-rmw-fastrtps-cpp-dev ros-humble-rmw-cyclonedds-cpp-dev"
}
