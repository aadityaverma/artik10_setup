namespace eval ::Deployer::Artik::RegexpBuilder {

    namespace export re_logined_prompt

    proc re-logined-prompt {args} {
        # Default values for switch-style parameters
        set use_default true
        set use_as_names false

        # Error strings
        set error_str_no_defaults \
            "Can't build necessary variables with -no-defaults option and \
             without providing them as formal arguments"
        set error_str_cant_set_params \
            "Can't set prompt parameter with supplied arguments"

        # Retrieve optional switches
        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-no-defaults" {
                    set use_default false
                }
                "-as-names" {
                    set use_as_names true
                }
            }
            set args [lreplace $args 0 0]
        }

        dict set parse_args {
            {re_prompt}     ""
            {dist_prompts}  ""
        }

        # 0 arguments — only default values if possible
        # 1 argument — regexp for prompt + default value for dist prompts if
        #   possible
        # 2 arguments — regexp for prompt + list of one element or name of upvar
        #   (depending from switch)
        # 3 or more arguments (default btanch) —> regexp for prompt + list of
        #   dis-specific prompts
        switch [llength $args] {
            0 {
                if {$use_default} {
                    dict set parse_args {re_prompt} "-default-upvar"
                    dict set parse_args {dist_prompts} "-default-listify"
                } else {
                    return -code error $error_str_no_defaults
                }
            }
            1 {
                dict set parse_args {re_prompt} "-upvar-or-raw"
                if {$use_default} {
                    dict set parse_args {dist_prompts} "-default-listify"
                } else {
                    return -code error $error_str_no_defaults
                }
            }
            2 {
                dict set parse_args {re_prompt} "-upvar-or-raw"
                dict set parse_args {dist_prompts} "-upvar-or-raw"
            }
            default {
                dict set parse_args {re_prompt} "-upvar-or-raw"
                dict set parse_args {dist_prompts} "-listify"
            }
        }

        switch [dict get $parse_args {re_prompt}] {
            "-default-upvar" {
                namespace upvar ::Deployer::Artik re_prompt prompt
            }
            "-upvar-or-raw" {
                set prompt_parameter [lindex $args 0]
                if {[uplevel 1 [list info exists $prompt_parameter]]
                    && $use_as_names} {
                    upvar 1 $prompt_parameter prompt
                } elseif {[regexp -expanded {^ .* \( .* \)\$ $} $prompt_parameter]} {
                    set prompt $prompt_parameter
                } else {
                    return -code error $error_str_cant_set_params
                }
            }
        }

        switch [dict get $parse_args {dist_prompts}] {
            "-default-listify" {
                set dist_prompts {}
                variable ::Deployer::Artik::os_specific
                dict for {os os_dict} $::Deployer::Artik::os_specific {
                    dict for {os_version os_version_dict} $os_dict {
                        dict with os_version_dict {
                            if {[string length $prompt] > 0} {
                                lappend dist_prompts $prompt
                            }
                        }
                    }
                }
            }
            "-upvar-or-raw" {
                set dist_spec_parameter [lindex $args 1]
                if {[uplevel 1 [list info exists $dist_spec_parameter]]
                    && $use_as_names} {
                    upvar 1 $dist_spec_parameter dist_prompts
                } else {
                    set dist_prompts $dist_spec_parameter
                }
            }
            "-listify" {
                set dist_prompts [lrange $args 1 end]
            }
        }

        # Clean args
        set args [lreplace $args 0 end]

        regsub {(.*?)(?:\)\$)$} $prompt {\1} prompt
        foreach dp {[dict values $dist_prompts]} {
            append re_prompt "|$dp"
        }
        append re_prompt ")$"
    }

}
