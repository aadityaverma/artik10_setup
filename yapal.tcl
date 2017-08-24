
# Tcl parser for optional arguments in function calls and
#  commandline arguments
#
# (c) 2001 Bastien Chevreux

#  Index of exported commands
#     - ::yapal::registerArgs
#     - ::yapal::setArgDefaults
#     - ::yapal::setArgsNeeded
#     - ::yapal::parseArgs

#  Internal commands
#     - ::yapal::CheckValues

# See end of file for an example on how to use

package provide argp 0.2

namespace eval ::yapal {
    variable Optstore
    variable Opttypes {
        boolean integer double string
    }

    namespace export {[a-z]*}
}


proc ::yapal::registerArgs { func arglist } {
    variable Opttypes
    variable Optstore

    set parentns [string range [uplevel 1 [list namespace current]] 2 end]
    if { $parentns != "" } {
       append caller ${parentns}::${func}
    } else {
       set caller $func
    }
    set cmangled [string map {:: _} $caller]

    #puts $parentns
    #puts $caller
    #puts $cmangled

    set Optstore(keys,$cmangled) {}
    set Optstore(deflist,$cmangled) {}
    set Optstore(argneeded,$cmangled) {}

    foreach arg $arglist {
        foreach {opt type default allowed} $arg {
            set optindex [lsearch -glob $Opttypes $type*]
            if { $optindex < 0} {
        		return -code error "$caller, unknown type $type while registering arguments.\nAllowed types: [string trim $Opttypes]"
            }
            set type [lindex $Opttypes $optindex]

            lappend Optstore(keys,$cmangled) $opt
            set Optstore(type,$opt,$cmangled) $type
            set Optstore(default,$opt,$cmangled) $default
            set Optstore(allowed,$opt,$cmangled) $allowed
            lappend Optstore(deflist,$cmangled) $opt $default
        }
    }

    if {[catch {CheckValues $caller $cmangled $Optstore(deflist,$cmangled)} res]} {
        return -code error "Error in declaration of optional arguments.\n$res"
    }
}

proc ::yapal::setArgDefaults { func arglist } {
    variable Optstore

    set parentns [string range [uplevel 1 [list namespace current]] 2 end]
    if { $parentns != "" } {
           append caller $parentns :: $func
    } else {
           set caller $func
    }
    set cmangled [string map {:: _} $caller]

    if {![info exists Optstore(deflist,$cmangled)]} {
           return -code error "Arguments for $caller not registered yet."
    }
    set Optstore(deflist,$cmangled) {}
    foreach {opt default} $arglist {
    	if {![info exists Optstore(default,$opt,$cmangled)]} {
    	    return -code error "$caller, unknown option $opt, must be one of: $Optstore(keys,$cmangled)"
    	}
       set Optstore(default,$opt,$cmangled) $default
    }

    # set the new defaultlist
    foreach opt $Optstore(keys,$cmangled) {
           lappend Optstore(deflist,$cmangled) $opt $Optstore(default,$opt,$cmangled)
    }
}

proc ::yapal::setArgsNeeded { func arglist } {
    variable Optstore

    set parentns [string range [uplevel 1 [list namespace current]] 2 end]
    if { $parentns != "" } {
           append caller $parentns :: $func
    } else {
           set caller $func
    }
    set cmangled [string map {:: _} $caller]

    #append caller $parentns :: $func
    #set cmangled ${parentns}_$func

    if {![info exists Optstore(deflist,$cmangled)]} {
           return -code error "Arguments for $caller not registered yet."
    }

    set Optstore(argneeded,$cmangled) {}
    foreach opt $arglist {
    	if {![info exists Optstore(default,$opt,$cmangled)]} {
    	    return -code error "$caller, unknown option $opt, must be one of: $Optstore(keys,$cmangled)"
    	}
    	lappend Optstore(argneeded,$cmangled) $opt
    }
}


proc ::yapal::parseArgs { args } {
    variable Optstore

    if {[llength $args] == 0} {
        upvar args a opts o
    } else {
        upvar args a [lindex $args 0] o
    }

    if { [ catch { set caller [lindex [info level -1] 0]}]} {
        set caller "main program"
        set cmangled ""
    } else {
        set cmangled [string map {:: _} $caller]
    }

    if {![info exists Optstore(deflist,$cmangled)]} {
        return -code error "Arguments for $caller not registered yet."
    }

    # set the defaults
    array set o $Optstore(deflist,$cmangled)

    # but unset the needed arguments
    foreach key $Optstore(argneeded,$cmangled) {
        catch { unset o($key) }
    }

    foreach {key val} $a {
        if {![info exists Optstore(type,$key,$cmangled)]} {
            return -code error "$caller, unknown option $key, must be one of: $Optstore(keys,$cmangled)"
        }
        switch -exact -- $Optstore(type,$key,$cmangled) {
            boolean -
            integer {
                if { $val == "" } {
                    return -code error "$caller, $key empty string is not $Optstore(type,$key,$cmangled) value."
                }
                if { ![string is $Optstore(type,$key,$cmangled) $val]} {
                    return -code error "$caller, $key $val is not $Optstore(type,$key,$cmangled) value."
                }
            }
            double {
                if { $val == "" } {
                    return -code error "$caller, $key empty string is not double value."
                }
                if { ![string is double $val]} {
                    return -code error "$caller, $key $val is not double value."
                }
                if { [string is integer $val]} {
                    set val [expr {$val + .0}]
                }
            }
            default {
            }
        }
        set o($key) $val
    }

    foreach key $Optstore(argneeded,$cmangled) {
        if {![info exists o($key)]} {
            return -code error "$caller, needed argument $key was not given."
        }
    }

    if { [catch { CheckValues $caller $cmangled [array get o]} err]} {
        return -code error $err
    }

    return
}


proc ::yapal::CheckValues { caller cmangled checklist } {
    variable Optstore

    #puts "Checking $checklist"

    foreach {key val} $checklist {
        if { [llength $Optstore(allowed,$key,$cmangled)] > 0 } {
            switch -exact -- $Optstore(type,$key,$cmangled) {
                string {
                    if { [lsearch $Optstore(allowed,$key,$cmangled) $val] < 0} {
                        return -code error "$caller, $key $val is not in allowed values: $Optstore(allowed,$key,$cmangled)"
                    }
                }
                double -
                integer {
                    set found 0
                    foreach range $Optstore(allowed,$key,$cmangled) {
                        if {[llength $range] == 1} {
                            if { $val == [lindex $range 0] } {
                                set found 1
                                break
                            }
                        } elseif {[llength $range] == 2} {
                            set low [lindex $range 0]
                            set high [lindex $range 1]

                            if { ![string is integer $low] && \
                                [string compare "-" $low] != 0} {
                                      return -code error "$caller, $key of type $Optstore(type,$key,$cmangled) has a lower value range that is not integer and not Ž-Ž: $range"
                                  }
                            if { ![string is integer $high] && \
                                [string compare "+" $high] != 0} {
                                    return -code error "$caller, $key of type $Optstore(type,$key,$cmangled) has a upper value range that is not integer and not Ž+Ž: $range"
                                }
                            if {[string compare "-" $low] == 0} {
                                if { [string compare "+" $high] == 0 || $val <= $high } {
                                    set found 1
                                    break
                                }
                            }
                            if { $val >= $low } {
                                if {[string compare "+" $high] == 0 || $val <= $high } {
                                    set found 1
                                    break
                                }
                            }
                        } else {
                            return -code error "$caller, $key of type $Optstore(type,$key,$cmangled) has an allowed value range containing more than 2 elements: $range"
                        }
                    }
                    if { $found == 0 } {
                        return -code error "$caller, $key $val is not covered by allowed ranges: $Optstore(allowed,$key,$cmangled)"
                    }
                }
            }
        }
    }
}
