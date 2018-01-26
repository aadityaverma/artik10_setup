package require Tcl 8.5


package provide Deployer::Artik 0.0.1

source [file join [file dirname [info script]] artik-builders.tm]

namespace eval ::Deployer::Artik {

    # TODO: -- refactor this --
    variable baud 115200            ;# refactored
    variable opts "cs8 ixoff"       ;# refactored

    variable login_params {}        ;# refactored
    variable tizen_prompts {}       ;# refactored
    variable reverse_prompt {}

    variable re_os_info ""
    variable re_logined_prompt {(%|#\s*|\$)$}

    variable str {}

    array set sid {}
    # -- end refactor --

    # -- new --
    variable cli_defaults    {}
    variable cli_opts        {}

    variable screen_cli_args {}
    variable os_specific     {}
    # -- end new --

    # Pre-parse variable setting
    proc pre-parse-setup {} {
        variable cli_defaults

        set cli_defaults [dict create {*}{
            {device}            "/dev/ttyUSB0"
            {iface}             "eth0"
            {is_interactive}    0
        }]
    }

    # Parsing command-line options
    proc parse-cli-opts {} {
        pre-parse-setup

        foreach a [list argv argc] {
            variable ::$a
        }
        foreach a [list cli_opts cli_defaults] {
            variable $a
        }

        foreach opt $argv {
            if {[string equal $opt --interactive]} {
                dict set cli_opts {is_interactive} 1
                set argv [lsearch -all -inline -not -exact $argv $opt]
                incr argc -1
            } elseif {[regexp -- {^(?:--device|-d)$} $opt]} {
                dict set cli_opts {device} [lindex $argv [expr [lsearch $argv $opt] + 1]]
            	set argv [lsearch -all -inline -not -exact $argv $opt]
                incr argc -1
            } elseif {[regexp -- {^(?:--iface|-i)$} $opt]} {
            	dict set cli_opts {iface} [lindex $argv [expr [lsearch $argv $opt] + 1]]
            	set argv [lsearch -all -inline -not -exact $argv $opt]
                incr argc -1
            }
        }

        foreach key [dict keys $cli_defaults] {
            if {![dict exists $cli_opts $key]} {
                dict set cli_opts $key [dict get $cli_defaults $key]
            }
        }
    }

    proc do {} {
        variable cli_opts
        dict for {key value} $cli_opts {
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
        namespace import ::Deployer::Artik::RegexpBuilder::re-logined-prompt

        variable tizen_prompts
        variable login_params
        variable reverse_prompt

        variable re_os_info
        variable re_logined_prompt

        # -- new --
        set screen_cli_args [dict create {*}{
            {baud} 115200
            {opts} [list cs8 ixoff]
        }]

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

        set re_logined_prompt [re-logined-prompt $re_logined_prompt]
        # -- end new --

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
