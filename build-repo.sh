#!/bin/sh

set -e

aportsdir_base=${APORTSDIR}
repodir_base=${REPODIR}

repo=${1:-backports}


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

cp -r ${SRCDIR}/* ${aportsdir_base}
mkdir -p ${APORTSDIR}/${repo}
mkdir -p ${REPODIR}

sudo apk update

(cd ${basedir} && buildrepo ${repo} -d ${REPODIR} -a ${APORTSDIR})


# Re-sign packages

index=$(find ${REPODIR}/${repo} -name APKINDEX.tar.gz || true)
if [ ! -f "${index}" ]; then
  exit 1
fi
rm -f ${index}
apk index -o ${index} `find $(dirname ${index}) -name '*.apk'`
abuild-sign -k /home/builder/.abuild/*.rsa ${index}
