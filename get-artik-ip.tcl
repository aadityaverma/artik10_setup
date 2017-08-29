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

set login_params [dict create user "root" pass "tizen"]

set tizen_3_0_m3_prompt "root:~> "

set re_prompt "(%|#|\\$|$tizen_3_0_m3_prompt)$"

set str {}

array set sid {}

proc isAlive {cmd sid} {
    if {[catch {send -i $sid "$cmd\r"} err]} {
        puts "error sending to $sid: $err"
        exit 1
    } else {
        return false
    }
}

proc connect_device {login_params device} {
    upvar baud baud
    upvar opts opts
    upvar re_prompt re_prompt

    upvar sid sid

    set re_login_prompt     ".*artik login:"

    set pat_pass_prompt     "Password:"
    set pat_failed_login    "Login incorrect:"
    set pat_invalid_path    "Cannot exec '$device': No such file or directory"
    log_user 0

    spawn -noecho screen -S artik $device $baud $opts
    set sid(server) $spawn_id

    send -- "\r"
    expect {
        -re $re_login_prompt {
            send -- "[dict get $login_params user]\r"
            exp_continue
        }
        $pat_pass_prompt {
            send -- "[dict get $login_params pass]\r"
        }
        $pat_failed_login {
            send -- "[dict get $login_params user]\r"
            sleep 0.1
            send -- "[dict get $login_params pass]\r"
        }
        -re $re_prompt {
            send -- "\r"
        }
        $pat_invalid_path {
            exit 67
        }
        timeout {
            exit 66
        }
    }
}

proc get_ips {} {
    upvar sid(server) screen_id
    upvar re_prompt re_prompt
    set spawn_id $screen_id
    set str {}

    expect -re $re_prompt {
        send -- "ip -f inet addr show\r"
    }

    expect -re $re_prompt {
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
    upvar sid(server) screen_id
    set spawn_id $screen_id

    send -- "exit\r"
    expect "logout\r"
    spawn screen -S artik -X kill
    expect eof
}

proc scratch_desirable_ip {ips_string} {
    upvar if_name prefferable_if
    array set ifaces {}
    set desirable_ip ""

    foreach {if_info} [split [string trim $ips_string "\n"] "\n"] {
        lassign [split $if_info] if ip subnet
        dict set ifaces($if) ip     $ip
        dict set ifaces($if) subnet $subnet
    }

    if {[info exists ifaces($prefferable_if)]} {
        try {
            set desirable_ip [dict get $ifaces($prefferable_if) ip]
        } on error {msg options} {
            exit 65
        }
    } else {
        exit 65
    }

    return $desirable_ip
}

connect_device $login_params $device
set ips [get_ips]
disconnect_from_device
puts [scratch_desirable_ip $ips]

exit 0
