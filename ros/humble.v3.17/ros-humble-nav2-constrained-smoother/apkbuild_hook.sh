apkbuild_hook() {
  makedepends="${makedepends} blas-dev glog-dev lapack-dev libtbb-dev metis metis-dev suitesparse-dev xtl"
  depends="${depends} blas-dev glog-dev lapack-dev libtbb-dev metis suitesparse-dev xtl"
}
