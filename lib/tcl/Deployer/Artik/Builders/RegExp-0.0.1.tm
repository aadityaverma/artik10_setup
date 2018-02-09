package require Tcl 8.5

package require RegExp 0.0.1

package require Deployer::Artik::OS::Specific 0.0.1

namespace eval ::Deployer::Artik::Builders::RegExp {

    namespace export re-login-prompt \
                re-login-password-prompt \
                re-logined-prompt \
                dict-of-re-logins \
                re-parsing-ip-output

    proc re-logined-prompt {re_prompt} {
       
        set dist_prompts {}
        variable ::Deployer::Artik::OS::Specific::os_specific
        dict for {os os_dict} $::Deployer::Artik::OS::Specific::os_specific {
            dict for {os_version os_version_dict} $os_dict {
                dict with os_version_dict {
                    if {[string length $prompt] > 0} {
                        lappend dist_prompts $prompt
                    }
                }
            }
        }

        regsub {(.*?)(?:\)\$)$} $re_prompt {\1} re_prompt
        foreach dp $dist_prompts {
            append re_prompt "|$dp"
        }
        append re_prompt ")$"
        
        return $re_prompt
    }

    proc re-login-prompt {} {
        return {.*(artik|localhost|TIZEN.*) login:}
    }

    proc re-login-password-prompt {} {
        return "Password:"
    }

    proc dict-of-re-logins {args} {
        set for_logined {(%|#\\s*|\\$)$}

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-for-logined" {
                    set for_logined [lindex $args 1]
                    set args [lreplace $args 0 1]
                }
            }
        }

        set result_dict {}
        dict set result_dict {login} [re-login-prompt]
        dict set result_dict {password} [re-login-password-prompt]
        dict set result_dict {logined} [re-logined-prompt $for_logined]

        return $result_dict
    }

    proc re-parsing-ip-output {} {
        set iface_name {(\w+)}
        set ip_addr {(\d+\.\d+\.\d+\.\d+)}
        set mask {(\d+)}
        return [append "" \
            {\d+:\s} $iface_name {[^\n]*\n} {\s*inet\s*} $ip_addr {/} $mask {[^\n]*} ]
    }
}
