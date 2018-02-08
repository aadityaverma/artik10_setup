package require Tcl 8.5

package require List::Utils 0.0.1
package require RegExp 0.0.1

namespace eval ::OS::Utils {
    namespace export is-running-program kill-program

    proc is-running-program {args} {
        namespace import ::RegExp::ere-build-case-insensetive-word
        set build {}

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-case-insensetive" {
                    dict set build {case-insensetive} {true}
                    set args [lreplace $args 0 0]
                }
            }
        }

        set program [lindex $args 0]
        if {[dict get $build {case-insensetive}]} {
            set program [ere-build-case-insensetive-word $program]
        }
        set args [lindex $args 1 end]
        
        try {
            return [split [exec pgrep -f "$program.*$args"] "\n"]
        } trap CHILDSTATUS {results options} {
            switch [lindex [dict get $options -errorcode] 2] {
                1 {
                    return false
                }
            }
        }
    }

    proc kill-program {args} {
        namespace import ::List::Utils::* \
                    ::RegExp::ere-build-case-insensetive-word

        set error_str [dict create {*}{
            {no_proc}
                "No such process"
        }]

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-case-insensetive" {
                    dict set build {case-insensetive} {true}
                    set args [lreplace $args 0 0]
                }
            }
        }

        set handler [dict create {*}{}]
        if {![is-numeric [lindex $args 0]]} {
            set re_program_name [ere-build-case-insensetive-word [lindex $args 0]]
            set args_program [lindex $args 1 end]
            dict set handler {type} {pkill}
        } else {
            set pids [list $args]
            dict set handler {type} {kill}
        }

        switch [dict get $handler {type}] {
            "pkill" {
                try {
                    exec pkill -f "$re_program_name.*$args_program"
                } trap CHILDSTATUS {results options} {
                    switch [lindex [dict get $options -errorcode] 2] {
                        1 {
                            return -code error [dict get $error_str {no_proc}]
                        }
                    }
                }
            }
            "kill" {
                foreach pid $pids {
                    # From https://dropbear.xyz/2014/07/01/killing-a-process-in-tcl/
                    set cmdline "kill $pid"
                    try {
                        exec /bin/sh -c $cmdline 
                    } trap CHILDSTATUS {msg options} {
                        return -code error "Could not kill process: $msg"
                    }
                }
            }
        }
    }
}