apkbuild_hook() {
  makedepends=$(echo "${makedepends}" | sed "s|ros-humble-rmw-connextdds\s||g")
  depends="${depends} ros-humble-rmw-fastrtps-cpp ros-humble-rmw-fastrtps-dynamic-cpp"
}
