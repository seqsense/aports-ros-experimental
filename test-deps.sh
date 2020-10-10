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

# py2-backports.ssl_match_hostname conflicts with py2-backports_functools_lru_cache
SEPARATED_PKGS="
  py[23]\{0,1\}-matplotlib
  py2-backports_functools_lru_cache
  ros-${ROS_DISTRO}-rqtplot"

touch /separated_pkgs
for pkg in ${SEPARATED_PKGS}; do
  sed -n "/^${pkg}\$/p" /local_pkgs >> /separated_pkgs
  sed "/^${pkg}\$/d" -i /local_pkgs
done

apk update

echo
echo "Installing packages"
apk add --virtual .test $(cat /separated_pkgs)
echo "Removing packages"
apk del .test

echo
echo "Installing all local packages"
exec apk add $(cat /local_pkgs)
