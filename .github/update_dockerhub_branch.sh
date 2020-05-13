#!/bin/bash

set -eu

BRANCH=dockerhub
ROS_DISTROS="kinetic melodic noetic"

function alpine_version() {
  case $1 in
    kinetic)
      echo "3.7";;
    melodic)
      echo "3.8";;
    noetic)
      echo "3.11";;
    *)
      echo "Unknown ROS_DISTRO" >&2;
      exit 1;;
  esac
}

git checkout dockerhub
git pull origin dockerhub

git checkout master Dockerfile update-checksum.sh build-repo.sh

for ros_distro in ${ROS_DISTROS}
do
  echo "Updating ${ros_distro}"
  mkdir -p ${ros_distro}
  alpine_version=$(alpine_version ${ros_distro})
  echo "- Alpine version: ${alpine_version}"

  cp Dockerfile update-checksum.sh build-repo.sh ${ros_distro}/
  sed "s/^\(ARG ALPINE_VERSION=\).*$/\1${alpine_version}/" -i ${ros_distro}/Dockerfile
done

rm Dockerfile update-checksum.sh build-repo.sh

git add .
if git diff --cached --exit-code
then
  echo "Up-to-date"
  exit 0
fi

master_hash=$(git show-ref --hash=7 --heads master | head -n1)
git commit -m "Update (${master_hash})"

git push origin ${BRANCH}

git checkout master
