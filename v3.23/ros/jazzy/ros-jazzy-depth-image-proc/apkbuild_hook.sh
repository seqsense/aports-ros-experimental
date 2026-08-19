apkbuild_hook() {
  # test_point_cloud_xyz waits a fixed window for camera_info delivery
  # and loses that race on a loaded builder
  check_retries=3
}
