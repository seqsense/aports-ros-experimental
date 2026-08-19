apkbuild_hook() {
  depends_dev="${depends_dev} ros-jazzy-rmw-implementation-cmake ros-jazzy-rmw-implementation-cmake-dev"
  # discovery-dependent tests (test_graph, test_subscription, ...) flake
  # when other builder containers share the docker bridge
  check_retries=3
}
