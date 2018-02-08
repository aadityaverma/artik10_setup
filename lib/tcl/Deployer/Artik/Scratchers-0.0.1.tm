namespace eval ::Deployer::Artik::Scratchers {

    proc scratch-ip {ips args} {
        set ip {}

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-device" {
                    set device [lindex $args 1]
                    set args [lreplace args 0 1]
                }
            }
        }

        foreach el $ips {
            if {[info exists device] && [string equal [lindex $el 0] $device]} {
                set ip [lindex $el 1]
            }
        }

        return $ip
    }
}