#!/bin/sh

set -e

ALPINE_VERSION=${ALPINE_VERSION:-$(cat /etc/alpine-release | cut -d. -f1-2)}


# Register local repositories

touch /local_pkgs
find /packages -name APKINDEX.tar.gz | while read path; do
  arch_path=$(dirname ${path})
  repo_path=$(dirname ${arch_path})
  echo "${repo_path}" | tee -a /etc/apk/repositories

  tmpdir=$(mktemp -d)
  (cd ${tmpdir} && tar xzfv ${path})
  cat ${tmpdir}/APKINDEX | sed -n "/^P:/s/^P://p" >> /local_pkgs
  rm -rf ${tmpdir}
done

SEPARATED_PKGS="
  ros-${ROS_DISTRO}-rosbridge-server"

for pkg in ${SEPARATED_PKGS}; do
  sed "/^${pkg}\$/d" -i /local_pkgs
done

apk update

echo
echo "Installing packages"
apk add --virtual .test ${SEPARATED_PKGS}
echo "Removing packages"
apk del .test

echo
echo "Installing all local packages"
exec apk add $(cat /local_pkgs)
