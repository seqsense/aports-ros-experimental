apkbuild_hook() {
  export LDFLAGS="${LDFLAGS} -Wl,-rpath,/usr/ros/jazzy/opt/rviz_ogre_vendor/lib -Wl,-rpath,/usr/ros/jazzy/opt/rviz_ogre_vendor/lib/OGRE"
}
