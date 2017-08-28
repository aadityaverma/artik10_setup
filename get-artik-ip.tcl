#!/usr/bin/env tclsh
set default_if_name "eth0"
set default_device "/dev/ttyUSB0"

if {$argc == 1} {
    set device [lindex $argv 0]
    set if_name $default_if_name
} elseif {$argc == 2} {
    set device [lindex $argv 0]
    set if_name [lindex $argv 1]
} else {
    set device $default_device
    set if_name $default_if_name
}

package require Expect

set baud 115200
set opts "cs8 ixoff"

set user "root"
set pass "tizen"

set tizen_3_0_m3_prompt "root:~> "

set prompt "(%|#|\\$|$tizen_3_0_m3_prompt)$"

set str {}

proc connect_device {} {
    upvar device device
    upvar baud baud
    upvar opts opts
    upvar user user
    upvar pass pass
    upvar prompt prompt

    spawn screen -S artik $device $baud $opts
    set sid(server) $spawn_id

    send -- "\r"
    expect {
        -re ".*artik login:" {
            send -- "${user}\r"
            exp_continue
        }
        "Password:" {
            send -- "${pass}\r"
        }
        "Login incorrect:" {
            send -- "${user}\r"
            sleep 0.1
            send -- "${pass}\r"
        }
        -re $prompt {
            send -- "\r"
        }
    }
    return $sid(server)
}

proc get_ips {} {
    upvar screen_id screen_id
    upvar prompt prompt
    set spawn_id $screen_id
    set str {}

    expect -re $prompt {
        send -- "ip -f inet addr show\r"
    }

    expect -re $prompt {
        set matchTuples [regexp -all -inline {\d+\:\s(\w+)[^\n]*\n\s*inet\s*(\d+\.\d+\.\d+\.\d+)\/(\d+)[^\n]*} $expect_out(buffer)]
        foreach {group0 group1 group2 group3} $matchTuples {
            if {![regexp {^(?:lo).*} ${group1}]} {
                set str "${str}${group1} ${group2} ${group3}\n"
            }
        }
    }
    return $str
}

proc disconnect_from_device {} {
    upvar screen_id screen_id
    set spawn_id $screen_id

    send -- "exit\r"
    expect "logout\r"
    spawn screen -S artik -X kill
    expect eof
}

proc scratch_desirable_ip {ips_string} {
    upvar prefferable_if if_name
    array set ifaces {}
    set desirable_ip ""
    puts $prefferable_if

    foreach {if_info} [split [string trim $ips_string "\n"] "\n"] {
        set if_info_list [split $if_info]
        dict set ifaces([lindex $if_info_list 0]) ip     [lindex $if_info_list 1]
        dict set ifaces([lindex $if_info_list 0]) subnet [lindex $if_info_list 2]
    }

    if {[info exists ifaces($prefferable_if)]} {
        try {
            set desirable_ip [dict get ifaces($prefferable_if) ip]
        } on error {msg options} {
            exit 1
        }
    } else {
        exit 1
    }

    return $desirable_ip
}

log_user 0

set screen_id [connect_device]
set ips [get_ips]
disconnect_from_device
puts [scratch_desirable_ip ips]

exit 0
