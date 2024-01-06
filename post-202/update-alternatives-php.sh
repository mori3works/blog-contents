#!/bin/bash

_target="auto"
while getopts t:h OPT
do
    case "${OPT}" in
    t)
        _target=${OPTARG}
        ;;
    h)
        cat <<HELP
USAGE: ${0} -t target

    target:
        auto    : use auto mode
        \d+\.\d : specify "version \d\.\d"  (ex. 8.1, 7.1)
HELP
        exit 1
        ;;
    esac
done

if [ "${_target}" = "auto" ] || [[ "${_target}" =~ ^[[:digit:]]+\.[[:digit:]]+$ ]]
then
    cat <<MSG
INFO: Target is specified "${_target}".
MSG
else
    cat <<MSG
ERROR: Target must be either "auto" or '\d+\.\d+'.
MSG
    exit 1
fi


declare -A _status
# Before update
_alts=$(update-alternatives --get-selections | egrep 'ph(p|ar)' | awk '{ print $1 }')
for _a in ${_alts}
do
    _table=$(echo | update-alternatives --config "${_a}" | awk '/Selection/,/^$/ { print $0 }')
    #echo "# ${_a}"
    #echo "${_table}"
    _status[${_a}]=$(echo "${_table}" | base64 -w 0)
done


# Update
_pat='^(\*)?\s+(\d+)\s+(\S.*\S)\s+(\d+)\s+(auto|manual)\s+mode$'
for _a in ${_alts}
do
    _table=$(echo "${_status[${_a}]}" | base64 -d)
    OLDIFS=${IFS}
    IFS=$'\n'
    _current=
    _auto=
    _entries=()
    for _e in $(echo "${_table}" | grep -P -o ${_pat})
    do
        _aster=$(echo "${_e}" | perl -lne "s/${_pat}/\\1/; print")
        _order=$(echo "${_e}" | perl -lne "s/${_pat}/\\2/; print")
        _path=$(echo "${_e}" | perl -lne "s/${_pat}/\\3/; print")
        _prior=$(echo "${_e}" | perl -lne "s/${_pat}/\\4/; print")
        _mode=$(echo "${_e}" | perl -lne "s/${_pat}/\\5/; print")
        cat <<DEBUG >/dev/null
ORDER: ${_order}
    ${_path} (priority=${_prior}, mode=${_mode})
DEBUG
        if [ "${_aster}" = "*" ]
        then
            _current="${_order}"
        fi
        if [ "${_mode}" = "auto" ]
        then
            _auto="${_order}"
        fi
        _entries[${_order}]="${_path}"
    done
    IFS=${OLDIFS}
    cat <<DEBUG >/dev/null
    AUTO=${_auto}
    CURRENT=${_current}
DEBUG
    
    if [ "${_target}" = "auto" ]
    then
        if [ ! "${_current}" = "${_auto}" ]
        then
            cat <<MSG
INFO: Change "${_current}" to "${_auto}" of alternatives about ${_a}."
MSG
            echo "${_auto}" | sudo update-alternatives --quiet --config "${_a}" >/dev/null 2>/dev/null
        fi
    elif [[ "${_target}" =~ ^([[:digit:]]+\.[[:digit:]]+) ]]
    then
        _ver=${BASH_REMATCH[1]}
        _bin=${_a}${_ver}
        _i=-1
        _n=${#_entries[@]}; ((_n = _n - 1))
        for _ii in $(seq 0 ${_n})
        do
            _e=${_entries[${_ii}]}
            if [[ "${_e}" =~ ${_bin}$ ]]
            then
                _i=${_ii}
            fi
        done
        if [ ! "${_i}" = "${_current}" -a ! "${_i}" = "-1" ]
        then
            cat <<MSG
INFO: Change "${_current}" to "${_i}".
MSG
            echo "${_i}" | sudo update-alternatives --quiet --config "${_a}" >/dev/null 2>/dev/null
        fi
    fi
done


# After update
for _a in ${_alts}
do
    _table=$(echo | update-alternatives --config "${_a}" | awk '/Selection/,/^$/ { print $0 }')
    _table_before=$(echo "${_status[${_a}]}" | base64 -d)
    _diff=$(diff -U5 <(echo "${_table_before}") <(echo "${_table}"))
    if [ ! "${?}" = 0 ]
    then
        echo "# ${_a}"
        echo "${_diff}"
        echo
    fi
done


cat <<MSG
INFO: Operation completed.
MSG

