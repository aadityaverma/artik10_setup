#!/usr/bin/env tclsh
set default_if_name "eth0"
set default_device "/dev/ttyUSB0"

array set output_opts {}

foreach opt $argv {
    if {[string equal $opt --interactive]} {
        set argv [lsearch -all -inline -not -exact $argv $opt]
        set output_opts(is_interactive) true
        incr argc -1
        break
    }
}

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

set login_params {}
set tizen_prompts {}
set reverse_prompt {}

set re_os_info ""
set pat_tizen_3_0_m3_prompt "root:~> "
set re_prompt {(%|#\s*|\$)$}

set str {}

array set sid {}

proc setup {} {
    upvar tizen_prompts tizen_prompts
    upvar login_params login_params
    upvar reverse_prompt reverse_prompt

    upvar re_os_info re_os_info
    upvar re_prompt re_prompt

    dict set tizen_prompts {Tizen 3.0m3} "root:~> "

    regsub {(.*?)(?:\)\$)$} $re_prompt {\1} re_prompt
    dict for {prompt_name prompt} $tizen_prompts {
        append re_prompt "|$prompt"
    }
    append re_prompt ")$"

    set login_params {}
    dict set login_params "Tizen 3.0" { user "root" pass "tizen" }
    dict set login_params "Fedora 24" { user "root" pass "root"  }

    set reverse_prompt {}
    dict set reverse_prompt "localhost" "Fedora 24"
    dict set reverse_prompt "artik"     "Tizen 3.0"

    append re_os_info {(?s)[\n\s.]*?(}
    foreach {os_name} [dict keys $login_params] {
        if {! [string equal $os_name "Tizen 3.0"]} {
            append re_os_info "$os_name|"
        }
    }
    regsub {(.*?)\|$} $re_os_info {\1)[\n\s.]*} re_os_info

    log_user 0
}

proc connect_device {login_params device reverse_prompt} {
    upvar baud baud
    upvar opts opts
    upvar re_prompt re_prompt
    upvar re_os_info re_os_info

    upvar sid sid

    set re_cmd_name         {[Ss][Cc][Rr][Ee]{2}[Nn]}
    set re_login_prompt     ".*(artik|localhost) login:"

    set pat_pass_prompt     "Password:"
    set pat_failed_login    "Login incorrect"
    set pat_invalid_path    "Cannot exec '$device': No such file or directory"
    set pat_screen_termed   "\[screen is terminating\]"

    set os {}
    set MAX_ATTEMPTS 2

    # Check if there any screen instance is running and kill it.
    # Otherwise return error.
    if {! [catch {exec pkill -f "$re_cmd_name.*$device"}] &&
        ! [catch {exec pgrep -f "$re_cmd_name.*$device"}]} {
        exit 66
    }

    spawn -noecho screen -S artik $device $baud $opts
    set sid(server) $spawn_id

    set attempts 0

    puts [exp_pid]
	if {! [catch {exec ps [exp_pid]} std_out] == 0} { 
	   puts "screen with [exp_pid] has been terminated"
       exit 66
	}

    exec pgrep {^screen}

    send -- "\r"
    expect {
        -re $re_login_prompt {
            regexp $re_os_info $expect_out(buffer) mtchd os
            if {$os eq ""} {
                try {
                    set os [dict get $reverse_prompt $expect_out(1,string)]
                } on error {} {
                    exit 1
                }
            }
            send -- "[dict get $login_params $os user]\r"
            exp_continue
        }
        $pat_pass_prompt {
            send -- "[dict get $login_params $os pass]\r"
            exp_continue
        }
        $pat_failed_login {
            if {$attempts >= $MAX_ATTEMPTS} {
                send -- "\r"
                send -- "\r"
                expect eof {
                    exit 1
                }
            }
            exp_continue
        }
        -re $re_prompt {
            send -- "\r"
            return 0
        }
        $pat_invalid_path {
            exit 67
        }
        $pat_screen_termed {
            puts "In use!"
            exit 67
        }
        timeout {
            exit 66
        }
    }
    exit 1
}

proc get_ips {} {
    upvar sid(server) screen_id
    upvar re_prompt re_prompt
    set spawn_id $screen_id
    set str {}

    set cmd_ip_get_ipv4 "ip -f inet addr show"

    expect -re $re_prompt {
        send -- "$cmd_ip_get_ipv4\r"
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

proc msg {message} {
    upvar output_opts(is_interactive) interactivity
    if {interactivity} {
        puts message
    }
}

setup
connect_device $login_params $device $reverse_prompt
set ips [get_ips]
disconnect_from_device
puts [scratch_desirable_ip $ips]

exit 0
