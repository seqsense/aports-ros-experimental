#!/bin/bash

set -eu

BRANCH=dockerhub
ROS_DISTROS="kinetic melodic noetic"

. ./alpine_version_from_ros_distro.sh

master_hash=$(git show-ref --hash=8 --heads | head -n1)

if ! git config --get user.email
then
  git config user.name "Alpine ROS aports builder bot"
  git config user.email "noreply@seqsense.com"
fi

echo "Checkout dockerhub branch"
git checkout dockerhub
git pull origin dockerhub

git checkout ${master_hash} Dockerfile update-checksum.sh build-repo.sh

for ros_distro in ${ROS_DISTROS}
do
  echo "Updating ${ros_distro}"
  mkdir -p ${ros_distro}
  alpine_version=$(alpine_version_from_ros_distro ${ros_distro})
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

git commit -m "Update (${master_hash})"

git push origin ${BRANCH}

echo "Note: you are still in dockerhub branch"
