#!/usr/bin/env bash

__CMD=( "python" "ruby" "perl" "lua5.3" "tclsh" )
__V=( "-V" "-v" "-v | awk 'FNR==2 {print}'" "-v" "printf 'puts [info patchlevel];exit 0' | ")

_pretty_banner() {
    local _str="${1// /\$}"
    local _sym=$2
    local _num=$3
    local _v
    _v=$(printf "%-${_num}s\e[3m\e[1m%s\e[0m%-${_num}s" "$_sym" "$_str" "$_sym")
    _v="${_v// /$__sym}"
    printf "%s\n" "${_v//\$/ }"
}

_pretty_out() {
    local __filler="~"
    local __banner_len=22
    local __test_str=" test"
    (( __len_str = ${#1} + ${#__test_str} ))
    if (( __len_str % 2 == 0 )); then
        _pretty_banner "${1}${__test_str}" $__filler $(( __banner_len / 2 - __len_str / 2 ))
    else
        _pretty_banner "${1} ${__test_str}" $__filler $(( __banner_len / 2 - (__len_str / 2 + 1) ))
    fi
}

_get_max_len() {
    local _max=0
    for str in $1; do
        if (( ${#str} > _max )); then
            _max=${#str}
        fi
    done
}

_get_lang_name() {
    if [[ $1 == "lua5.3" ]]; then
        printf "lua"
    else
        printf "%s" "$1"
    fi
}

_print__Version() {
    local _version_str=""
    local _max_len=$(_get_max_len @__CMD)
    local _lang=$(_get_lang_name "$1")
    if [[ $_lang == "perl" ]]; then
        _version_str=$(eval "$1 $2")
    elif [[ $_lang == "tclsh" ]]; then
        _version_str=$(eval "$2 $1")
    else
        _version_str=$($1 "$2")
    fi
    printf "\e[1m%${_max_len}s\e[0m version: %s\n" "$_lang" "$_version_str"
}

_main() {
    tabs -4
    _pretty_banner "" "\"" 22
    printf "%s How do I test %s\n" "-----" "-----"
    printf "\n\ttime for _ in {1..1000}; do\n\t\t<interpreter__CMD> - <<< exit\n\tdone\n\n"
    _pretty_banner "" "\"" 22

    for ((i=0; i<${#__CMD[@]}; ++i)); do
        _pretty_out "$(_get_lang_name "${__CMD[i]}")"
        _print__Version "${__CMD[i]}" "${__V[i]}"
        for _ in {1..2}; do
            printf "\e[4mTest #%s\e[0m:\t" "$_"
            if [[ ${__CMD[i]} == "lua5.3" ]]; then
                (
                    time for _ in {1..1000}; do
                        ${__CMD[i]} 2> /dev/null - <<< exit
                    done
                ) 2>&1 | awk 'FNR==2 {print}'
            else
                (
                    time for _ in {1..1000}; do
                        ${__CMD[i]} - <<< exit
                    done
                ) 2>&1 | awk 'FNR==2 {print}'
            fi
        done
        printf "\n"
    done
    tabs -8
}

_main "$@"
