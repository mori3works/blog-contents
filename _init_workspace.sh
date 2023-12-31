#!/bin/bash

#
# Python VirtualEnv
#
_venv_dir="./.venv-l"
_pip_list_cache="${_venv_dir}/requirements.txt"
_requirements="./requirements.txt"

if ! ls -d "${_venv_dir}" >/dev/null 2>/dev/null
then
    python -m venv "${_venv_dir}"
    . "${_venv_dir}/bin/activate"
    pip install -r <(egrep -v ^pywin "${_requirements}")
    pip freeze > "${_pip_list_cache}"
    deactivate
fi



if [ ! -e "${_pip_list_cache}" ]
then
    . "${_venv_dir}/bin/activate"
    pip freeze > "${_pip_list_cache}"
    deactivate
fi


if [ -e "${_requirements}" ] && ! diff "${_pip_list_cache}" <(egrep -v ^pywin "${_requirements}")
then
    . "${_venv_dir}/bin/activate"
    pip install -r <(egrep -v ^pywin "${_requirements}")
    pip freeze > "${_pip_list_cache}"
    deactivate
fi

