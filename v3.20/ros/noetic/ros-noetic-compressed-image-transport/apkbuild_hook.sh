apkbuild_hook() {
  test ${pkgver} = 1.14.0
  pkgver=1.15.0
  pkgrel=0
  depends="ros-noetic-cv-bridge ros-noetic-dynamic-reconfigure ros-noetic-image-transport"
  makedepends="chrpath libjpeg-turbo-dev py3-rosdep py3-rosinstall-generator py3-setuptools py3-vcstool ros-noetic-catkin ros-noetic-catkin-dev ros-noetic-cv-bridge ros-noetic-cv-bridge-dev ros-noetic-dynamic-reconfigure ros-noetic-dynamic-reconfigure-dev ros-noetic-image-transport ros-noetic-image-transport-dev ros-noetic-rostest ros-noetic-rostest-dev"
  depends_dev="libjpeg-turbo-dev ros-noetic-cv-bridge-dev ros-noetic-dynamic-reconfigure-dev ros-noetic-image-transport ros-noetic-image-transport-dev"

}
