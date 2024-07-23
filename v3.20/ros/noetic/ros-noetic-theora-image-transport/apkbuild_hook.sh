apkbuild_hook() {
  test ${pkgver} = 1.14.0
  pkgver=1.15.0
  rosinstall="- git:
      local-name: ${_pkgname}
      uri: https://github.com/ros-gbp/image_transport_plugins-release.git
      version: release/noetic/${_pkgname}/1.15.0-1
  "
}
