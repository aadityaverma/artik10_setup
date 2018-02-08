package require Tcl 8.5

namespace eval ::Deployer::Artik::Builders::Messages {
    namespace export dict-of-msgs-failed

    proc dict-of-msgs-failed {args} {
        set result_dict {}

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-device" {
                    set device [lindex $args 1]
                    set args [lreplace $args 0 1]
                }
            }
        } 
        
        dict set result_dict {failed_login} \
                    "Login incorrect"
        dict set result_dict {invalid_path} \
                    "Cannot exec '$device': No such file or directory"
        dict set result_dict {screen_termed} \
                    "\[screen is terminating\]"

        return $result_dict
    }
}