#!/bin/sh

set -e

aportsdir_base=${APORTSDIR}
repodir_base=${REPODIR}

repo=${1:-backports}


BUILD_REPO_OPTIONS=
case "${PURGE_OBSOLETE:-no}" in
  "y" | "yes" | "Yes" | "on" | "ON" ) BUILD_REPO_OPTIONS="-p";;
esac


# Disable stack protection to improve performance

CFLAGS="-fno-stack-protector -fomit-frame-pointer -march=x86-64 -mtune=generic -Os"
sudo sed -i "s/export CFLAGS=\".*\"/export CFLAGS=\"${CFLAGS}\"/" /etc/abuild.conf

echo "/etc/abuild.conf:"
head -n4 /etc/abuild.conf


# Overwrite make setting if provided

if [ ! -z "${JOBS}" ]; then
  sudo sed -i "s/export JOBS=.*/export JOBS=${JOBS}/" /etc/abuild.conf
fi

echo "/etc/abuild.conf:"
grep CFLAGS /etc/abuild.conf
grep JOBS /etc/abuild.conf
echo


# Normalize directory variables

basedir=.
if [ ${repo} != $(basename ${repo}) ]; then
  APORTSDIR=${APORTSDIR}/$(dirname ${repo})
  REPODIR=${REPODIR}/$(dirname ${repo})
  basedir=$(dirname ${repo})
  repo=$(basename ${repo})
fi
echo "APORTSDIR: ${APORTSDIR}"
echo "REPODIR: ${REPODIR}"
echo "target repository: ${repo}"
echo "base directory: ${basedir}"
echo

if [ ! -d ${SRCDIR}/${basedir}/${repo} ]; then
  echo "${repo} is not present. Skipping."
  exit 0;
fi


# Store previous APKINDEX sum

index_sum=
index=$(find ${REPODIR}/${repo} -name APKINDEX.tar.gz || true)
if [ -f "${index}" ]; then
  index_sum=$(sha512sum ${index})
fi


# Generate temporary private key if not present

if [ ! -f ${PACKAGER_PRIVKEY} ]; then
  abuild-keygen -a -i -n

  # Re-sign packages if private key is updated
  index=$(find ${REPODIR} -name APKINDEX.tar.gz || true)
  if [ -f "${index}" ]; then
    rm -f ${index}
    apk index -o ${index} `find $(dirname ${index}) -name '*.apk'`
    abuild-sign -k /home/builder/.abuild/*.rsa ${index}
  fi
fi


# Register existing local repositories

find ${repodir_base} -name APKINDEX.tar.gz | while read path; do
  arch_path=$(dirname ${path})
  repo_path=$(dirname ${arch_path})
  echo "${repo_path}" | sudo tee -a /etc/apk/repositories
done


# Build packages

mkdir -p ${aportsdir_base}
mkdir -p ${REPODIR}
cp -r ${SRCDIR}/* ${aportsdir_base}

sed -e 's/arch="noarch"/arch="all"/' -i $(find ${aportsdir_base} -name APKBUILD)
sed -e 's/:noarch//' -i $(find ${aportsdir_base} -name APKBUILD)


# Remove python2 builds on new environments

ALPINE_VERSION_MAJOR=$(echo ${ALPINE_VERSION} | cut -f1 -d.)
ALPINE_VERSION_MINOR=$(echo ${ALPINE_VERSION} | cut -f2 -d.)

echo "ALPINE_VERSION: major(${ALPINE_VERSION_MAJOR}) minor(${ALPINE_VERSION_MINOR})"

ls ${APORTSDIR}
if [ ${ALPINE_VERSION_MAJOR} -eq 3 -a ${ALPINE_VERSION_MINOR} -ge 11 ]; then
  echo "Removing py2 from v3.11 aports"
  py_apkbuilds=$(find $(find ${APORTSDIR}/backports/ -name "py-*" -type d) -name APKBUILD)
  if [ ! -z "${py_apkbuilds}" ]; then
    echo "${py_apkbuilds}" | xargs -r -n1 echo "-"
    sed "s/\<python2-dev\>//g" -i ${py_apkbuilds}              # Remove python2-dev dep
    sed "s/\<py2-\${pkgname#py-}:_py2\>//g" -i ${py_apkbuilds} # Remove py2- subpackage
    sed "s/^\s*python2\s/#\0/g" -i ${py_apkbuilds}             # Remove python2 commands
  else
    echo "Skipping py2 removal"
  fi
fi


echo
echo "Checking version constraint setting"
find ${aportsdir_base} -name ENABLE_ON | while read path; do
  echo -n "$(basename $(dirname $path))"
  if grep -q -s "v${ALPINE_VERSION}" "${path}"; then
    echo ": enabled"
  else
    echo ": disabled"
    rm -rf $(dirname ${path})
  fi
done
echo

sudo apk update

(cd ${basedir} && \
  set -o pipefail && \
  buildrepo ${repo} -d ${REPODIR} -a ${APORTSDIR} ${BUILD_REPO_OPTIONS} 2>&1 | \
    grep --line-buffered \
      -v -e "([0-9]*/[0-9]*) Purging " \
      -v -e "([0-9]*/[0-9]*) Installing " \
      -v -e "remote: Counting objects: " \
      -v -e "remote: Compressing objects: " \
      -v -e "Receiving objects: " \
      -v -e "Resolving deltas: ")


# Re-sign packages if there is a change

index=$(find ${REPODIR}/${repo} -name APKINDEX.tar.gz || true)
if [ ! -f "${index}" ]; then
  exit 1
fi

index_sum2=$(sha512sum ${index})
if [ "${index_sum}" != "${index_sum2}" ]; then
  echo "Previous index: ${index_sum}"
  echo "New index:      ${index_sum2}"
  rm -f ${index}
  apk index -o ${index} `find $(dirname ${index}) -name '*.apk'`
  abuild-sign -k /home/builder/.abuild/*.rsa ${index}
fi
