apkbuild_hook() {
  # cmake-extras is required to find system installed GMock
  depends="${depends} cmake-extras"
}
