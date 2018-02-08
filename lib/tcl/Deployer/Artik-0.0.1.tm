package require Tcl 8.5

package require IO::File::Utils 0.0.1
package require Log::Ger 0.0.1

package require Deployer::Artik::Externals 0.0.1
package require Deployer::Artik::Expect 0.0.1
package require Deployer::Artik::Scratchers 0.0.1

namespace eval ::Deployer::Artik {

    variable cli_opts           {}
    variable screen_cli_args

    proc setup {} {
        variable screen_cli_args
        set screen_cli_args(session_name) artik
        set screen_cli_args(baud) 115200
        set screen_cli_args(opts) [list cs8 ixoff onlret -parenb -cstopb]
    }

    # Parsing command-line options
    proc parse-cli-opts {} {
        variable cli_opts

        dict for {k v} [dict create {*}"
            {device}            /dev/ttyUSB0
            {iface}             eth0
            {is_interactive}    false
            {os}                Tizen
            {os_version}        3.0m2
            {fname}             [::IO::File::Utils::get-tmp-fname]

            {verbosity}         [::Log::Ger::get-default-level]
        "] {
            dict set cli_opts $k $v
        }

        # Prepare array with screen_cli_args
        setup

        # Create local variable linked to global variables argv and argc
        foreach a [list argv argc] {
            variable ::$a
        }

        while {[llength $argv] > 0} {
            set opt [lindex $argv 0]
            switch -regexp $opt {
                {^--interactive$} {
                    dict set cli_opts {is_interactive} true
                    set argv [lreplace $argv 0 0]
                    incr argc -1
                }
                {^(?:--device|-d)$} {
                    dict set cli_opts {device} [lindex $argv [expr [lsearch $argv $opt] + 1]]
                    set argv [lreplace $argv 0 1]
                    incr argc -2
                } 
                {^(?:--iface|-i)$} {
                    dict set cli_opts {iface} [lindex $argv [expr [lsearch $argv $opt] + 1]]
                    set argv [lreplace $argv 0 1]
                    incr argc -2
                }
                {^(?:--os|-o)$} {
                    dict set cli_opts {os} [lindex $argv [expr [lsearch $argv $opt] + 1]]
                    set argv [lreplace $argv 0 1]
                    incr argc -2
                }
                {^(?:--os-version|-V)$} {
                    dict set cli_opts {os_version} [lindex $argv [expr [lsearch $argv $opt] + 1]]
                    set argv [lreplace $argv 0 1]
                    incr argc -2
                }
                {^(?:--file|-f)$} {
                    dict set cli_opts {fname} [lindex $argv [expr [lsearch $argv $opt] + 1]]
                    set argv [lreplace $argv 0 1]
                    incr argc -2
                }

                {^(?:-v|--verbose)$} {
                    dict set cli_opts {verbosity} [expr {[dict get $cli_opts {verbosity}] + 1}]
                    set argv [lreplace $argv 0 0]
                    incr argc -1
                }
                {^(?:-q|--quiet)$} {
                    dict set cli_opts {verbosity} [expr {[dict get $cli_opts {verbosity}] - 1}]
                    set argv [lreplace $argv 0 0]
                    incr argc -1
                }
            }
        }

        # Validation
        if {![file exists [dict get $cli_opts device]]} {
            return -code error -options [dict create {*}"
                        {device}    [dict get $cli_opts device]
                    "] "Invalid path to device" 
        }

        # Setup logger
        ::Log::Ger::setup [dict get $cli_opts {verbosity}]

        return
    }

    proc do {} {
        variable cli_opts
        variable screen_cli_args

        try {
            ::Deployer::Artik::Expect::spawn-screen \
                        -interactive [dict get $cli_opts {is_interactive}] \
                        -speed [set screen_cli_args(baud)] \
                        -device [dict get $cli_opts {device}] \
                        -params {*}[set screen_cli_args(opts)]
            ::Deployer::Artik::Expect::obtain-status \
                        [dict get $cli_opts {os}] \
                        [dict get $cli_opts {os_version}]
        } on error reason {
            switch $reason {
                "Screen terminated" {
                    ::Deployer::Artik::Externals::shutdown-screen -kill-main
                    return -code error $reason
                }
                "Timeout" {
                    ::Deployer::Artik::Externals::shutdown-screen -kill-main
                    return -code error $reason
                }
            }
        }

        set ip [::Deployer::Artik::Scratchers::scratch-ip \
                    [::Deployer::Artik::Expect::get-ip [dict get $cli_opts {iface}]] \
                    -device [dict get $cli_opts {iface}]]
        
        try {
            ::IO::File::Utils::write-to-file [dict get $cli_opts {fname}] $ip -create-dir
        } on error {reason options} {
            switch $reason {
                "Cannot create directory!" {
                    return -code error -options $options $reason
                }
                "Cannot open file!" {
                    return -code error -options $options $reason
                }
            }
        }
        
        ::Deployer::Artik::Expect::disconnect
        ::Deployer::Artik::Externals::shutdown-screen -kill-main


        ::Log::Ger::log-info $ip

        if {[string equal -nocase $ip ""]} {
            return -code error "Interface has no IP"
        } else {
            return
        }
    }
}
