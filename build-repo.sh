#!/bin/sh

set -e

mkdir -p /cache/apk /cache/ccache

ALPINE_VERSION=${ALPINE_VERSION:-$(cat /etc/alpine-release | cut -d. -f1-2)}

aportsdir_base=${APORTSDIR}
repodir_base=${REPODIR}

BUILD_REPO_OPTIONS=
case "${PURGE_OBSOLETE:-no}" in
  "y" | "yes" | "Yes" | "on" | "ON" ) BUILD_REPO_OPTIONS="-p";;
esac

#BUILD_REPO_OPTIONS="${BUILD_REPO_OPTIONS} -k"


# Disable stack protection to improve performance

CFLAGS="-fomit-frame-pointer -march=x86-64 -mtune=generic -Os"
case "${STACK_PROTECTOR:-yes}" in
  "n" | "no" | "No" | "off" | "OFF" )
    CFLAGS="${CFLAGS} -fno-stack-protector"
    echo "Stack protector is disabled"
    ;;
esac
sudo sed -i "s/export CFLAGS=\".*\"/export CFLAGS=\"${CFLAGS}\"/" /etc/abuild.conf

echo "/etc/abuild.conf:"
head -n4 /etc/abuild.conf


# Overwrite make setting if provided

if [ ! -z "${JOBS}" ]; then
  sudo sed -i "s/export JOBS=.*/export JOBS=${JOBS}/" /etc/abuild.conf
fi

sudo sed -i 's/export MAKEFLAGS=.*/export MAKEFLAGS="-j$JOBS -l$JOBS"/' /etc/abuild.conf

echo "/etc/abuild.conf:"
grep CFLAGS /etc/abuild.conf
grep JOBS /etc/abuild.conf
echo


# Generate temporary private key if not present

if [ ! -f ${PACKAGER_PRIVKEY} ]; then
  echo "======== WARN: PACKAGER_PRIVKEY is not present ======="
  abuild-keygen -a -i -n
  sudo cp ${HOME}/.abuild/*.pub /etc/apk/keys/
  RESIGN=true
fi

if ${RESIGN:-false}
then
  # Re-sign packages if private key is updated
  for index in $(find ${REPODIR} -name APKINDEX.tar.gz || true)
  do
    rm -f ${index}
    apk index -o ${index} $(find $(dirname ${index})/../ -name '*.apk')
    abuild-sign -k /home/builder/.abuild/*.rsa ${index}
  done
fi


for repo in $@
do
  # Normalize directory variables

  basedir=.
  if [ ${repo} != $(basename ${repo}) ]; then
    APORTSDIR=${APORTSDIR}/$(dirname ${repo})
    REPODIR=${REPODIR}/$(dirname ${repo})
    basedir=$(dirname ${repo})
    repo=$(basename ${repo})
  fi
  repo_out=${repo%.v*}
  echo "APORTSDIR: ${APORTSDIR}"
  echo "REPODIR: ${REPODIR}"
  echo "target repository: ${repo}"
  echo "base directory: ${basedir}"
  echo

  if [ ! -d ${SRCDIR}/${basedir}/${repo} ]; then
    echo "${repo} is not present. Skipping."
    exit 0
  fi


  # Copy noarch pkgs

  sudo cp -p ${REPODIR}/${repo_out}/noarch/* ${REPODIR}/${repo_out}/x86_64/ || true


  # Register existing local repositories

  find ${repodir_base} -name APKINDEX.tar.gz | while read path; do
    arch_path=$(dirname ${path})
    repo_path=$(dirname ${arch_path})
    echo "${repo_path}" | sudo tee -a /etc/apk/repositories
  done


  # Build packages

  mkdir -p ${aportsdir_base}/${basedir}
  mkdir -p ${REPODIR}
  cp -r ${SRCDIR}/${basedir}/${repo} ${aportsdir_base}/${basedir}/${repo_out}

  sed -e 's/arch="noarch.*"/arch="all"/' -i $(find ${aportsdir_base} -name APKBUILD)
  sed -e 's/:noarch//' -i $(find ${aportsdir_base} -name APKBUILD)


  # Remove python2 builds on new environments

  ALPINE_VERSION_MAJOR=$(echo ${ALPINE_VERSION} | cut -f1 -d.)
  ALPINE_VERSION_MINOR=$(echo ${ALPINE_VERSION} | cut -f2 -d.)

  echo "ALPINE_VERSION: major(${ALPINE_VERSION_MAJOR}) minor(${ALPINE_VERSION_MINOR})"

  ls ${APORTSDIR}
  if [ ${ALPINE_VERSION_MAJOR} -eq 3 -a ${ALPINE_VERSION_MINOR} -ge 11 ]; then
    echo "Removing py2 from >=v3.11 aports"
    py_apkbuilds=$(find ${APORTSDIR}/backports/ -name APKBUILD 2> /dev/null || true)
    if [ ! -z "${py_apkbuilds}" ]; then
      echo "${py_apkbuilds}" | xargs -r -n1 echo "-"
      sed 's/\<python2-dev\>//g' -i ${py_apkbuilds}             # Remove python2-dev dep
      sed 's/\<py2-${pkgname#py-}:_py2\>//g' -i ${py_apkbuilds} # Remove py2- subpackage
      sed 's/\<py2-$\S*pkgname:_py2\>//g' -i ${py_apkbuilds}    # Remove py2- subpackage
      sed 's/^\s*python2\s/#\0/g' -i ${py_apkbuilds}            # Remove python2 commands
      sed '/depends/s/\<py2-\S*\>//g' -i ${py_apkbuilds}        # Remove py2- dependencies
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

  set +e
  (cd ${basedir} && \
    set -o pipefail && \
    echo "buildrepo ${repo_out} -d ${REPODIR} -a ${APORTSDIR} ${BUILD_REPO_OPTIONS}"; \
    time buildrepo ${repo_out} -d ${REPODIR} -a ${APORTSDIR} ${BUILD_REPO_OPTIONS} 2>&1 | \
      grep --line-buffered \
        -v -e "remote: Counting objects: " \
        -v -e "remote: Compressing objects: " \
        -v -e "Receiving objects: " \
        -v -e "Resolving deltas: ")
  exit_code=$?
  set -e

  # Generate package index

  index=${REPODIR}/${repo_out}/x86_64/APKINDEX.tar.gz
  apk index -o ${index} \
    $(find $(dirname ${index}) -name '*.apk')

  tmpdir=$(mktemp -d)
  (cd ${tmpdir} && tar xzf ${index} && ls -la)


  # Move noarch packages

  rm ${REPODIR}/${repo_out}/noarch/*.apk || true
  cat ${tmpdir}/APKINDEX \
    | sed -n '/^P:/{s/^\S:\(.*\)$/\1 ARCH/p; {:l; n; /^A:/{s/^\S://p; d;}; b l;}};' \
    | sed -n '/ARCH$/{N; s/ARCH\n//p;}' \
    | while read apk; do
    pkg=$(echo ${apk} | cut -f1 -d" ")
    arch=$(echo ${apk} | cut -f2 -d" ")
    if [ "${arch}" = "noarch" ]; then
      echo "${pkg} is noarch"
      mkdir -p ${REPODIR}/${repo_out}/noarch/
      mv ${REPODIR}/${repo_out}/x86_64/${pkg}-* ${REPODIR}/${repo_out}/noarch/
    fi
  done

  rm -rf ${tmpdir}


  # Re-sign

  rm -f ${index}
  apk index -o ${index} \
    $(find $(dirname ${index})/../ -name '*.apk')
  abuild-sign -k /home/builder/.abuild/*.rsa ${index}

  if [ ${exit_code} -ne 0 ]; then
    exit ${exit_code}
  fi


  # Test dependencies

  touch /tmp/local_pkgs
  find ${REPODIR}/${repo_out} -name APKINDEX.tar.gz | while read path; do
    arch_path=$(dirname ${path})
    repo_path=$(dirname ${arch_path})

    tmpdir=$(mktemp -d)
    (cd ${tmpdir} && tar xzfv ${path})
    cat ${tmpdir}/APKINDEX | sed -n "/^P:/s/^P://p" >> /tmp/local_pkgs
    rm -rf ${tmpdir}
  done

  echo
  echo "Installing all local packages for dependency check"
  sudo apk add --virtual .install-test --force-overwrite $(cat /tmp/local_pkgs)
  sudo apk del .install-test
done
