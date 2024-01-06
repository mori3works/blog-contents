#!/bin/bash


_os_id=$(grep ^ID= /etc/os-release | awk -F= '{ print $2 }' | tr 'A-Z' 'a-z')
if [ ! "${_os_id}" = "ubuntu" ]
then
    cat <<MSG
ERROR: This script is only tested in *ubuntu.
MSG
    exit 1
fi


_ver=
while getopts v:h OPT
do
    case ${OPT} in
    v)
        _ver=${OPTARG}
        ;;
    h)
        cat <<HELP
USAGE: ${0} -v version-string
HELP
        exit 0
        ;;
    esac
done


if [[ "${_ver}" =~ [[:digit:]]+\.[[:digit:]]+ ]]
then
    echo "${_ver}"
else
    cat <<MSG
ERROR: PHP version string must be specified by '\d+\.\d+'.
MSG
    exit 1
fi


if ! dpkg -l software-properties-common >/dev/null 2>/dev/null
then
    sudo apt install -y software-properties-common
fi

if ! add-apt-repository -L | grep ondrej/php >/dev/null 2>/dev/null
then
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt update
fi


_php_req="php${_ver}"
_php_cur="php#.#"
_packages_install="php#.#-cli php#.#-common php#.#-mysql php#.#-opcache php#.#-readline"
if which php >/dev/null 2>/dev/null
then
    _php_cur=$(php -v | head -n1 | egrep -o 'PHP [[:digit:]]+\.[[:digit:]]+' | tr -d ' ' | tr 'A-Z' 'a-z')
    if [ "${_php_req}" = "${_php_cur}" ]
    then
        _already_satisfied=1
    else
        _packages_install=$(dpkg -l | grep "${_php_cur}" | awk '{ print $2 }' | tr '\n' ' '; echo)
    fi
fi

if [ ! "${_already_satisfied}" = 1 ]
then
    echo "INFO: Installing ${_php_req}(${_packages_install//${_php_cur}/${_php_req}}) started."
    sudo apt install -y ${_packages//${_php_cur}/${_php_req}}
    echo "INFO: Installing completed."
else
    echo "INFO: Requirements is already satisified. Skipping."
fi

