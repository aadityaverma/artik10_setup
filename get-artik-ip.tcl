#!/usr/bin/env expect
#set device [lindex $argv 0]
set device "/dev/ttyUSB0"
set baud 115200
set opts "cs8 ixoff"

set user "root"
set pass "tizen"

set prompt "(%|#|\\$|root:~>)$"

set str {}

log_user 0

spawn screen -S artik $device $baud $opts

send -- "\r"
expect -re ".*artik login:" {
    send -- "${user}\r"
}
expect "Password:" {
    send -- "${pass}\r"
}

expect "root:~>" {
    send -- "ip -f inet addr show\r"
}

expect "root:~>" {
    set matchTuples [regexp -all -inline {\d+\:\s(\w+)[^\n]*\n\s*inet\s*(\d+\.\d+\.\d+\.\d+)\/(\d+)[^\n]*} $expect_out(buffer)]
    foreach {group0 group1 group2 group3} $matchTuples {
        set str "${str}${group1} ${group2} ${group3}\n"
    }
}
send -- "exit\r"
expect "logout\r"
spawn screen -S artik -X kill
expect eof
puts "${str}"
