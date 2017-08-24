#!/usr/bin/env tclsh
#set device [lindex $argv 0]

package require Expect

set device "/dev/ttyUSB0"
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

proc get_ip {} {
    upvar screen_id screen_id
    upvar prompt prompt
    set spawn_id $screen_id

    expect -re $prompt {
        send -- "ip -f inet addr show\r"
    }

    expect -re $prompt {
        set matchTuples [regexp -all -inline {\d+\:\s(\w+)[^\n]*\n\s*inet\s*(\d+\.\d+\.\d+\.\d+)\/(\d+)[^\n]*} $expect_out(buffer)]
        set str {}
        foreach {group0 group1 group2 group3} $matchTuples {
            set str "${str}${group1} ${group2} ${group3}\n"
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

log_user 0

set screen_id [connect_device]
puts [get_ip]
disconnect_from_device

exit 0
