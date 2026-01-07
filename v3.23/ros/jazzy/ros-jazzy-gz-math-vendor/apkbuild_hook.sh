apkbuild_hook() {
  export LDFLAGS="${LDFLAGS} -Wl,-rpath,/usr/ros/jazzy/opt/gz_math_vendor/lib"
}
