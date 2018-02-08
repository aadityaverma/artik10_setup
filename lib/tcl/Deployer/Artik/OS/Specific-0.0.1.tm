package require Tcl 8.5

namespace eval Deployer::Artik::OS::Specific {
    
    variable os_specific

    proc setup {} {
        variable os_specific

        set os_specific [dict create {*}{
            {Tizen} {
                {Tizen 3.0m2} {
                    {login_prompt}  "localhost"
                    {login_params}  {
                        {user}      "root"
                        {password}  "tizen"
                    }
                    {prompt}        "root:~> "
                }
            }
            {Fedora} {
                {Fedora 24} {
                    {login_prompt}  "artik"
                    {login_params}  {
                        {user}      "root"
                        {password}  "root"
                    }
                    {prompt}        ""

                }
            }
        }]

        return
    }

    proc detect-os-by-login-prompt {prompt_string} {
        variable os_specific

        set error_str [dict create {*}{
            {no_os}
                "No OS suitable for this login prompt string"
        }]

        set prompt_part [lindex [split $prompt_string " "] 0]

        dict for {os os_dict} $::Deployer::Artik::OS::Specific::os_specific {
            dict for {os_version os_version_dict} $os_dict {
                dict with os_version_dict {
                    if {[string equal $prompt_part $login_prompt]} {
                        return $os_version
                    }
                }
            }
        }

        return -error code [dict get $error_str {no_os}]
    }
}

::Deployer::Artik::OS::Specific::setup