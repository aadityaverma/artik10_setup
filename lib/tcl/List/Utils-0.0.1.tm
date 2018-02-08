package require Tcl 8.5

namespace eval ::List::Utils {
    namespace export is-*

    proc is-numeric value {
        if {![catch {expr {abs($value)}}]} {
            return 1
        }
        set value [string trimleft $value 0]
        if {![catch {expr {abs($value)}}]} {
            return 1
        }
        return 0
    }
}