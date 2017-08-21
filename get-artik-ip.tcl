#!/usr/bin/env expect
set device [lindex $argv 0]
set baud 115200
set opts "cs8 ixoff"

set user "root"
set pass "tizen"

set prompt "(%|#|\\$|root)$"

log_user 0

spawn sudo screen $device $baud $opts
send "\r"

expect {
    "login:" {
        send "$user\r"
        expect "Password:"
        send "$pass"
    }
    -re $prompt
}
spawn ip -f inet addr show
set accum {}
#expect {
#    -re {(\d+\: +(\w+).*?\s*inet\s*(\d+\.\d+\.\d+\.\d+)\/(\d+)(?!\d+\:).*\n)+} {
#        set accum "${accum}$expect_out(2,string) "
#        set accum "${accum}$expect_out(3,string) "
#        set accum "${accum}$expect_out(4,string) "
#        set accum "${accum}\n"
#        exp_continue
#    }
#}
set tmp {}
set if {}
set ip {}
set port {}
set matchStr {}
expect "!\r"
while {[regexp {\d+\: +(\w+).*?\s*inet\s*(\d+\.\d+\#.\d+\.\d+)\/(\d+)(?!\d+\:)[.\n]*} $expect_out(buffer) -> if ip port]} {
    set matchStr "${matchStr}${if} ${ip} ${port}\n"
}
# output sss
puts $matchStr
#puts $expect_out(1, string)
spawn exit

send -- \001\028
puts "192.168.0.1"
