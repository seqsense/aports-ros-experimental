#!/bin/bash

set -e

origfile=$(mktemp)
cp $1 ${origfile}

. $1

cwd=$(pwd)

if [ $(echo "${source}" | wc -w) -ne 1 ]; then
  source=$(echo "${source}" | xargs -n1 echo 2> /dev/null | head -n1)
fi

url=${source}
if echo ${source} | grep "::" > /dev/null; then
  url=$(echo ${source} | cut -f3- -d":")
fi

echo "archive url: ${url}"

tmpdir=$(mktemp -d)
wget -q -O ${tmpdir}/archive ${url}
cd ${tmpdir}
tar xf archive
rm archive

if [ $(ls -1 | wc -l) -eq 1 ]; then
  cd *
fi

echo
echo "license files:"
license="$(find * -type f -iname "*license*")"
license+=" $(find * -type f -iname "gpl*")"
license+=" $(find * -type f -iname "lgpl*")"
license+=" $(find * -type f -iname "*copying*")"
license+=" $(find * -type f -iname "*copyright*")"
license=$(
  echo ${license} | xargs -r -n1 echo \
    | grep -v -e "\.py$" \
    | grep -v -e "\.sh$" \
    | grep -v -e "\.c$" \
    | grep -v -e "\.cpp$" \
    | grep -v -e "\.h$" \
    | grep -v -e "\.h$")
license=$(ls -1 ${license})  # sort by name
license=$(
  echo \
    $(echo ${license} | xargs -r -n1 echo | grep -v "/") \
    $(echo ${license} | xargs -r -n1 echo | grep "/")
)  # root directry first
echo ${license} | xargs -n1 echo "-"

if [ $(echo ${license} | wc -w) -eq 0 ]; then
  echo "license not found"
  exit 1
fi

tmpfile=$(mktemp)
mkdir -p ${tmpdir}/doc


echo
echo "install script:"
echo
echo "	# Install license files" | tee -a ${tmpfile}
if [ $(echo ${license} | wc -w) -eq 1 ]; then
  echo "	install -Dm644 \"\$builddir\"/${license} \"\$pkgdir\"/usr/share/licenses/\$pkgname/${license}" | tee -a ${tmpfile}
else
  echo "	install -d -m 0755 \"\$pkgdir\"/usr/share/licenses/\$pkgname" \
    | tee -a ${tmpfile}
  for l in ${license}; do
    dir=$(dirname $l)
    if [ ! -d ${tmpdir}/doc/${dir} ]; then
      mkdir -p ${tmpdir}/doc/${dir}
      echo "	install -d -m 0755 \"\$pkgdir\"/usr/share/licenses/\$pkgname/${dir}" \
        | tee -a ${tmpfile}
    fi
    echo "	install -m644 \"\$builddir\"/$l \"\$pkgdir\"/usr/share/licenses/\$pkgname/$l" \
      | tee -a ${tmpfile}
  done
fi
echo

sed "/^package()/,/^}$/s|^}$|\n$(cat ${tmpfile} | sed ':l; N; $!b l; s/\n/\\n/g')\n}|" \
  -i ${cwd}/$1


echo
echo "update subpackage:"
echo

if echo ${subpackages:-} | grep "$pkgname-doc" > /dev/null; then
  echo "- already has -doc package"
elif [ -z "${subpackages:-}" ]; then
  echo "- add new subpackages entry"
  sed "/^$/{i subpackages=\"\$pkgname-doc\"
      :l; n; $!b l}" \
    -i ${cwd}/$1
else
  echo "- add doc to subpackages"
  sed "s/subpackages=\"/\0\$pkgname-doc /" \
    -i ${cwd}/$1
fi

sed "/^pkgrel=/c pkgrel=$(expr ${pkgrel} + 1)" -i ${cwd}/$1

rm -rf ${tmpdir} ${tmpfile}


echo
echo "result:"
echo

diff -upr --color=always ${origfile} ${cwd}/$1 || true

echo
echo
echo -e "\e[31medit $1 by hand to verify\e[m"
echo
