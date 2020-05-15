function alpine_version_from_ros_distro() {
  case "$(basename ${1})" in
    kinetic ) echo 3.7;;
    melodic ) echo 3.8;;
    noetic) echo 3.11;;
    * ) return 1;;
  esac
}
