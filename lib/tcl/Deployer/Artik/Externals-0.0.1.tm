package require Tcl 8.5

package require OS::Utils 0.0.1

namespace eval ::Deployer::Artik::Externals {
    
    proc shutdown-screen {args} {
        set opts [dict create {*}{
            {args}      ""
            {kill_main} false
        }]

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-args" {
                    while {
                        ![string equal [string index [lindex $args 1] 0] "-"]
                        && [llength $args] > 1
                    } {
                        dict set opts args "[dict get $opts {args}][lindex $args 1] "
                        set args [lreplace $args 1 1]
                    }
                    set args [lreplace $args 0 0]
                }
                "-kill-main" {
                    dict set opts {kill_main} true
                    set args [lreplace $args 0 0]
                }
            }
        }

        if {[dict get $opts {kill_main}]} {
            ::OS::Utils::kill-program "SCREEN"
        } else {
            set pids [::OS::Utils::is-running-program -case-insensetive "screen" \
                        [join [dict get $opts {args}] " "]]

            if {[string is true $pids]} {
                ::OS::Utils::kill-program $pids
            }
        }

        return
    }
}