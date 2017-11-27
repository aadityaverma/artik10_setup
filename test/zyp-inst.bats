#!/usr/bin/env bats
# shellcheck disable=1091

__BATS_HELPERS_LOCATION=${BATS_HELPERS_LOCATION:-./bats_helpers}
__pattern_relative_location='.*'

declare -a __LIBS=( bats_support bats_assert bats_file )
for __lib in "${__LIBS[@]}"; do
    if [[ ! $__BATS_HELPERS_LOCATION =~ $__pattern_relative_location ]]; then
        __EXTENSION=".bash"
    fi
    load "${__BATS_HELPERS_LOCATION}/${__lib}/load${__EXTENSION:-}"
done

setup() {
    source "./zypper-installer"
}

@test 'assert_output() Helpers funcs: Banner outputs expected things (w/o args)' {
    run _banner
    assert_output '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
}

@test 'assert_output() Helpers funcs: Banner outputs expected things (w/ args)' {
    run _banner "#"
    assert_output '########################################'
}

@test 'assert_output() Helpers funcs: Test output with banner' {
    run _print_with_banner "oh hi mark"
    assert_output "########################################\n"
    "oh hi d\n"
    "########################################"
}
