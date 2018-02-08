package require Tcl 8.5

package require String::Utils

namespace eval ::IO::File::Utils {

    proc get-tmp-fname {} {

        switch [lindex $::tcl_platform(os) 0] {
            "Linux" {

                set fname [ file join / tmp artik-builder \
                            "ip-[::String::Utils::random-delim-string 5]" ]

                return $fname
            }
            "Windows NT" {
                return NULL
            }
        }
    }

    proc write-to-file {fname content args} {
        set opts [dict create {*}{
            {create_dir}    false
        }]

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-create-dir" {
                    dict set opts {create_dir} true
                    set args [lreplace $args 0 0]
                }
            }
        }

        if {[dict get $opts {create_dir}]} {
            file mkdir [file dirname $fname]

            if {![file exists [file dirname $fname]]} {
                return -code error -options [dict create {*}"
                            {dirname}   [file dirname $fname]]
                        "] "Cannot create directory!"
            }
        }

        try {
            set file_d [open $fname "w"]
        } on error {} {
            return -code error -options [dict create {fname} $fname] \
                    "Cannot open file!" 
        }

        foreach str $content {
            puts $file_d $str
        }
    }
}