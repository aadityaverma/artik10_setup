package require Tcl 8.5
package require Expect

package require Deployer::Artik::Builders::RegExp 0.0.1
package require Deployer::Artik::Builders::Messages 0.0.1
package require Deployer::Artik::OS::Specific 0.0.1

namespace eval ::Deployer::Artik::Expect {
    
    variable expect_internals
    variable device

    variable re_logined_prompt  {(%|#\s*|\$)$}

    proc spawn-screen {args} {
        variable expect_internals
        variable device

        set interactive false

        set screen_opts [dict create {*}{
            {session_name}  ""
            {device_path}   ""
            {baud}          115200
        }]
        set screen_params {}
        set avaliable_opts {-session_name -device -params}

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-interactive" {
                    set interactive [lindex $args 1]
                    set args [lreplace $args 0 1]
                }
                "-session-name" {
                    dict set screen_opts {session_name} "-S [lindex $args 1]"
                    set args [lreplace $args 0 1]
                }
                "-device" {
                    dict set screen_opts {device_path} [lindex $args 1]
                    set args [lreplace $args 0 1]
                }
                "-speed" {
                    lappend screen_params [lindex $args 1]
                    set args [lreplace $args 0 1]
                }
                "-params" {
                    while {[lsearch avaliable_opts [lindex $args 1]] == -1} {
                        if {[llength $args] > 1} {
                            lappend screen_params [lindex $args 1]
                            set args [lreplace $args 1 1]
                        } else {
                            break
                        }
                    }
                    set args [lreplace $args 0 0]
                }
            }
        }
        set params [list \
                    {*}[join \
                        [list \
                            [dict get $screen_opts {session_name}] \
                            [dict get $screen_opts {device_path}]] " "] \
                    {*}[join \
                        [list {*}$screen_params] ","]]


        # Expect things
        log_user [expr {$interactive} ? 1 : 0]

        spawn -noecho screen {*}$params
        send -- "\r"

        dict set expect_internals {spawned_pid} $spawn_id
        dict set expect_internals {program_name} "screen"
        dict set expect_internals {exit_args} [list -X kill]

        set device [dict get $screen_opts {device_path}]
        try {
            exec ps [dict get $expect_internals {spawned_pid}]
        } trap CHILDSTATUS {results options} {
            switch [lindex [dict get $options -errorcode] 2] {
                1 {
                    puts "Screen with [dict get $expect_internals \
                            {spawned_pid}] has been terminated"
                    return -code error "Screen terminated"
                } 
            }
        }

        return
    }

    proc obtain-status {os os_version} {
        namespace import ::Deployer::Artik::Builders::RegExp::dict-of-re-logins \
                    ::Deployer::Artik::Builders::Messages::dict-of-msgs-failed

        variable expect_internals
        variable device

        set spawn_id [dict get $expect_internals {spawned_pid}]

        set prompts [dict-of-re-logins {(%|#\s*|\$)$}]
        set msgs [dict-of-msgs-failed -device $device]

        set attempts 0
        set MAX_ATTEMPTS 3


        try {
            exec pgrep -f {[Ss][Cc][Rr][Ee][Ee][Nn].*/dev/ttyUSB}
        } trap CHILDSTATUS {results options} {
            return -code error "Screen terminated"
        }

        while {$attempts < $MAX_ATTEMPTS} {
            expect {
                -re [dict get $prompts {login}] {
                    login $os $os_version
                }
                -re [dict get $prompts {password}] {
                    send -- "\r"
                }
                -re [dict get $msgs {failed_login}] {
                    send -- "\r"
                    incr attempts
                }
                -re [dict get $prompts {logined}] {
                    send -- "\r"
                    return 0
                }
                -re [dict get $msgs {invalid_path}] {
                    return -code error "Invalid path to device"
                }
                timeout {
                    return -code error "Timeout"
                }
            }
        }

    }

    proc login {os os_version args} {
        variable expect_internals
        variable device

        set spawn_id [dict get $expect_internals {spawned_pid}]

        set prompts [dict-of-re-logins {(%|#\s*|\$)$}]
        set msgs [dict-of-msgs-failed -device $device]

        if {[llength args] > 0} {
            while {[string equal [string index [lindex $args 0] 0] "-"]} {
                switch [lindex $args 0] {
                    "-empty-password" {
                        set fiction_login true
                    }
                }
            }
        }

        send -- "[dict get $::Deployer::Artik::OS::Specific::os_specific $os \
                    [join [list $os $os_version] " "] {login_params} user]\r"
        expect -re [dict get $prompts {password}]
        send -- "[dict get $::Deployer::Artik::OS::Specific::os_specific $os \
                    [join [list $os $os_version] " "] {login_params} password]\r"
        return
    }

    proc get-ip {iface} {
        variable expect_internals
        variable re_logined_prompt

        set spawn_id [dict get $expect_internals {spawned_pid}]

        set cmd_ip_get_ipv4 "ip -f inet addr show"

        set list_ip {}

        expect -re [ ::Deployer::Artik::Builders::RegExp::re-logined-prompt $re_logined_prompt ]
        send -- "$cmd_ip_get_ipv4\r"

        expect -re [::Deployer::Artik::Builders::RegExp::re-logined-prompt $re_logined_prompt]
        set matchTuples [regexp -all -inline {\d+\:\s(\w+)[^\n]*\n\s*inet\s*(\d+\.\d+\.\d+\.\d+)\/(\d+)[^\n]*} $expect_out(buffer)]
        foreach {group0 group1 group2 group3} $matchTuples {
            if {![regexp {^(?:lo).*} $group1]} {
                lappend list_ip "$group1 $group2 $group3"
            }
        }

        return $list_ip
    }

    proc disconnect {} {
        variable expect_internals

        set spawn_id [dict get $expect_internals {spawned_pid}]

        send -- "exit\r"
        expect "logout"
        close
        return
    }
}