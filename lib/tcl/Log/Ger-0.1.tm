package require Tcl 8.5

package require String::Utils 0.0.1

namespace eval ::Log::Ger {

    variable __num_levels [dict create {*}{
        {critical}  0
        {warn}      1
        {info}      2
        {debug}     3
    }]
    variable __constants [dict create {*}{
        MIN_LEVEL_NUM   0
        MAX_LEVEL_NUM   3
        DEFAULT_LEVEL   1
    }]

    variable logging_opts   {}
    
    proc __prepare {} {
        variable __constants

        variable logging_opts

        dict for {k v} [dict create {*}"
            {level}     [get-default-level]
        "] {
            dict set logging_opts $k $v
        }
    }

    proc setup {level} {
        variable __num_levels
        variable __constants
        
        variable logging_opts

        __prepare

        namespace import ::String::Utils::is-*

        if {[is-numeric $level]
            && $level >= [dict get $__constants {MIN_LEVEL_NUM}]
            && $level <= [dict get $__constants {MAX_LEVEL_NUM}]
        } {
            dict set logging_opts {level} $level
        } elseif {[lsearch $level [dict keys $__num_levels]] >= 0} {
            dict set logging_opts {level} [dict get $__num_levels $level]
        }
    }

    proc log-info {msg} {
        variable __num_levels
        
        variable logging_opts

        if {[dict get $logging_opts {level}] >= [dict get $__num_levels {info}]} {
            puts $msg
        }
    }

    proc get-default-level {} {
        variable __constants

        return [dict get $__constants {DEFAULT_LEVEL}]
    }
}