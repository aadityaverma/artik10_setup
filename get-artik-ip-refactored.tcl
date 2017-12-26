#!/usr/bin/env tclsh

namespace eval ::Deployer::Artik {

    array set cli_defaults {
        device          "/dev/ttyUSB0"
        iface           "eth0"
        is_interactive	0
    }
    array set cli_opts {}

    # -- refactor this --
    variable baud 115200
    variable opts "cs8 ixoff"

    variable login_params {}
    variable tizen_prompts {}
    variable reverse_prompt {}

    variable re_os_info ""
    variable re_prompt {(%|#\s*|\$)$}

    variable str {}

    array set sid {}
    # -- end refactor --

    # -- new --
    variable screen_cli_args {}
    variable os_specific     {}
    # -- end new --

    # Parsing command-line options
    proc parse_cli_opts {} {
        foreach a [list argv argc] {
            upvar 0 ::$a $a
        }
        foreach a [list cli_opts cli_defaults] {
            upvar 0 ::Deployer::Artik::$a $a
        }

        foreach opt $argv {
            if {[string equal $opt --interactive]} {
                set argv [lsearch -all -inline -not -exact $argv $opt]
                set cli_opts(is_interactive) 1
                incr argc -1
            } elseif {[regexp -- {^(?:--device|-d)$} $opt]} {
                set cli_opts(device) [lindex $argv [expr [lsearch $argv $opt] + 1]]
            	set argv [lsearch -all -inline -not -exact $argv $opt]
                incr argc -1
            } elseif {[regexp -- {^(?:--iface|-i)$} $opt]} {
            	set cli_opts(iface)  [lindex $argv [expr [lsearch $argv $opt] + 1]]
            	set argv [lsearch -all -inline -not -exact $argv $opt]
                incr argc -1
            }
        }

        foreach key [array names cli_defaults] {
            if {![info exists cli_opts($key)]} {
                set cli_opts($key) [lindex [array get cli_defaults $key] 1]
            }
        }
    }

    proc do {} {
        upvar 0 ::Deployer::Artik::cli_opts cli_opts
        foreach {key value} [array get cli_opts] {
            puts [format "%-20s %-20s" $key $value]
            if {[string equal $key "device"]} {
                if {[file exists $value]} {
                    puts "tty device exists!"
                } else {
                    puts "Error! Device $value doesn't exist. Aborting..."
                    exit 1
                }
            }
        }
    }

    proc setup {} {
        variable tizen_prompts
        variable login_params
        variable reverse_prompt

        variable re_os_info
        variable re_prompt

        dict set tizen_prompts {Tizen 3.0m3} "root:~> "

        # -- new --
        dict set os_specific {Tizen} {
            {Tizen 3.0m2} {
                {login_prompt}  ""
                {login_params}  {
                    {user}      "root"
                    {password}  "tizen"
                }
                {prompt}        "root:~> "
            }
        }

        dict set os_specific {Fedora} {
            {Fedora 24} {
                {login_prompt}  ""
                {login_params}  {
                    {user}      "root"
                    {password}  "root"
                }
                {prompt}        ""

            }
        }
        # -- end new --

        regsub {(.*?)(?:\)\$)$} $re_prompt {\1} re_prompt
        dict for {prompt_name prompt} $tizen_prompts {
            append re_prompt "|$prompt"
        }
        append re_prompt ")$"

        set login_params {}
        dict set login_params "Tizen 3.0" { user "root" pass "tizen" }
        dict set login_params "Fedora 24" { user "root" pass "root"  }

        set reverse_prompt {}
        dict set reverse_prompt "localhost" "Fedora 24"
        dict set reverse_prompt "artik"     "Tizen 3.0"

        append re_os_info {(?s)[\n\s.]*?(}
        foreach {os_name} [dict keys $login_params] {
            if {![string equal $os_name "Tizen 3.0"]} {
                append re_os_info "$os_name|"
            }
        }
        regsub {(.*?)\|$} $re_os_info {\1)[\n\s.]*} re_os_info

        log_user 0
    }
}

namespace eval ::Deployer::Artik::RegexpBuilder {

    namespace export re_logined_prompt

    proc re-logined-prompt {args} {
        # Default values for switch-style parameters
        set use_default true
        set use_as_names false

        # Retrieve optional switches
        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-no-defaults" {
                    set use_default false
                }
                "-as-names" {
                    set use_as_names true
                }
            }
            set args [lreplace $args 0 0]
        }

        dict set parse_args {
            {re_prompt}     ""
            {dist_prompts}  ""
        }

        switch [llength $args] {
            # 0 arguments — only default values if possible
            0 {
                if {$use_default} {
                    # Set prompt base regexp
                    dict set parse_args { {re_prompt} "-default-upvar" }
                    namespace upvar ::Deployer::Artik re_prompt prompt
                    # Set distribution-specific prompts
                    dict set parse_args { {dist_prompts} "-default-listify" }
                    set dist_prompts {}
                    variable ::Deployer::Artik::os_specific
                    dict for {os os_dict} $::Deployer::Artik::os_specific {
                        dict for {os_version os_version_dict} $os_dict {
                            dict with os_version_dict {
                                if {[string length $prompt] > 0} {
                                    lappend dist_prompts $prompt
                                }
                            }
                        }
                    }
                } else {
                    return -code error "Can't build necessary variables with\
                                        -no-defaults option and without providing\
                                        them as formal arguments"
                }
            }
            # 1 argument — regexp for prompt + default value for dist prompts if
            # possible
            1 {
                # Set prompt base regexp
                dict set parse_args { {re_prompt} "-upvar-or-raw" }
                set prompt_parameter [lindex $args 0]
                if {[uplevel 1 [list info exists $prompt_parameter]]
                    && $use_as_names} {
                    upvar 1 $prompt_parameter prompt
                } elseif {[regexp -expanded {^ .* \( .* \)\$ $} $prompt_parameter]} {
                    set prompt $prompt_parameter
                } else {
                    return -code error "Can't set prompt parameter with supplied\
                                        arguments"
                }
                if {$use_default} {
                    # Set distribution-specific prompts
                    dict set parse_args { {dist_prompts} "-default-listify" }
                    set dist_prompts {}
                    variable ::Deployer::Artik::os_specific
                    dict for {os os_dict} $::Deployer::Artik::os_specific {
                        dict for {os_version os_version_dict} $os_dict {
                            dict with os_version_dict {
                                if {[string length $prompt] > 0} {
                                    lappend dist_prompts $prompt
                                }
                            }
                        }
                    }
                } else {
                    return -code error "Can't build necessary variables with\
                                        -no-defaults option and without providing\
                                        them as formal arguments"

                }
            }
            # 2 arguments — regexp for prompt + list of one element or name of upvar
            # (depending from switch)
            2 {
                # Set prompt base regexp
                dict set parse_args { {re_prompt} "-upvar-or-raw" }
                set prompt_parameter [lindex $args 0]
                if {[uplevel 1 [list info exists $prompt_parameter]]
                    && $use_as_names} {
                    upvar 1 $prompt_parameter prompt
                } elseif {[regexp -expanded {^ .* \( .* \)\$ $} $prompt_parameter]} {
                    set prompt $prompt_parameter
                } else {
                    return -code error "Can't set prompt parameter with supplied\
                                        arguments"
                }
                # Set distribution-specific prompts
                dict set parse_args { {dist_prompts} "-upvar-or-raw" }
                set dist_spec_parameter [lindex $args 1]
                if {[uplevel 1 [list info exists $dist_spec_parameter]]
                    && $use_as_names} {
                    upvar 1 $dist_spec_parameter dist_prompts
                } else {
                    set dist_prompts $dist_spec_parameter
                }
            }
            # 3 or more arguments — regexp for prompt + list of dis-specific prompts
            default {
                # Set prompt base regexp
                dict set parse_args { {re_prompt} "-upvar-or-raw" }
                set prompt_parameter [lindex $args 0]
                if {[uplevel 1 [list info exists $prompt_parameter]]
                    && $use_as_names} {
                    upvar 1 $prompt_parameter prompt
                } elseif {[regexp -expanded {^ .* \( .* \)\$ $} $prompt_parameter]} {
                    set prompt $prompt_parameter
                } else {
                    return -code error "Can't set prompt parameter with supplied\
                                        arguments"
                }
                # Set distribution-specific prompts
                dict set parse_args { {dist_prompts} "-listify" }
                set dist_prompts [lrange $args 1 end]
            }
            # Clean args
            set args [lreplace $args 0 end]
        }
    }

}

if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    Deployer::Artik::parse_cli_opts
    Deployer::Artik::do
}
