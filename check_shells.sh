#!/usr/bin/env bash

_CMD=( "python" "ruby" "perl" "lua5.3" "tclsh" )
_V=( "-V" "-v" "-v | awk 'FNR==2 {print}'" "-v" "printf 'puts [info patchlevel];exit 0' | ")

__pretty_banner() {
    __str="${1// /\$}"
    __sym=$2
    __num=$3
    __v=$(printf "%-${__num}s\e[3m\e[1m%s\e[0m%-${__num}s" "$__sym" "$__str" "$__sym")
    __v="${__v// /$__sym}"
    printf "%s\n" "${__v//\$/ }"
}

__pretty_out() {
    __filler="~"
    __banner_len=22
    __test_str=" test"
    ((__len_str = ${#1} + ${#__test_str}))
    if ((__len_str % 2 == 0)); then
        __pretty_banner "${1}${__test_str}" $__filler $((__banner_len / 2 - __len_str / 2))
    else
        __pretty_banner "${1} ${__test_str}" $__filler $((__banner_len / 2 - (__len_str / 2 + 1) ))
    fi
}

__get_max_len() {
    __max=0
    for str in $1; do
        if ((${#str} > __max)); then
            __max=${#str}
        fi
    done
}

__get_lang_name() {
    if [[ $1 == "lua5.3" ]]; then
        printf "lua"
    else
        printf "%s" "$1"
    fi
}

__print_version() {
    __version_str=""
    __max_len=$(__get_max_len @_CMD)
    __lang=$(__get_lang_name "$1")
    if [[ $__lang == "perl" ]]; then
        __version_str=$(eval "$1 $2")
    elif [[ $__lang == "tclsh" ]]; then
        __version_str=$(eval "$2 $1")
    else
        __version_str=$($1 "$2")
    fi
    printf "\e[1m%${__max_len}s\e[0m version: %s\n" "$__lang" "$__version_str"
}

tabs -4
__pretty_banner "" "\"" 22
printf "%s How do I test %s\n" "-----" "-----"
printf "\n\ttime for _ in {1..1000}; do\n\t\t<interpreter_cmd> - <<< exit\n\tdone\n\n"
__pretty_banner "" "\"" 22

for ((i=0; i<${#_CMD[@]}; ++i)); do
    __pretty_out "$(__get_lang_name "${_CMD[i]}")"
    __print_version "${_CMD[i]}" "${_V[i]}"
    for _ in {1..2}; do
        printf "\e[4mTest #%s\e[0m:\t" "$_"
        if [[ ${_CMD[i]} == "lua5.3" ]]; then
            (
                time for _ in {1..1000}; do
                    ${_CMD[i]} 2> /dev/null - <<< exit
                done
            ) 2>&1 | awk 'FNR==2 {print}'
        else
            (
                time for _ in {1..1000}; do
                    ${_CMD[i]} - <<< exit
                done
            ) 2>&1 | awk 'FNR==2 {print}'
        fi
    done
    printf "\n"
done
tabs -8
