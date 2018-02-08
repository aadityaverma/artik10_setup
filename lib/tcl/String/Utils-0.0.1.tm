package require Tcl 8.5

namespace eval ::String::Utils {
    namespace export is-*

    proc random-delim-string {length args} {
        # TODO: conversion minimum and maximum to binary representation
        set types [dict create {*}{
            {upper_case}    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            {lower_case}    "abcdefghijklmnopqrstuvwxyz"
            {digits}        "0123456789"
        }]
        
        set opts [dict create {*}{
            {upper_case}    true
            {lower_case}    true
            {digits}        true
        }]

        while {[string equal [string index [lindex $args 0] 0] "-"]} {
            switch [lindex $args 0] {
                "-no-upper-case" {
                    dict set opts {upper_case} false
                    set args [lreplace $args 0 0]
                }
                "-no-lower-case" {
                    dict set opts {lower_case} false
                    set args [lreplace $args 0 0]
                }
                "-no-digits" {
                    dict set opts {digits} false
                    set args [lreplace $args 0 0]
                }
            }
        }
        
        set chars {}
        foreach type [list upper_case lower_case digits] {
            if {[dict get $opts $type]} {
                append chars [dict get $types $type]
            }
        }

        set range [expr {[string length $chars] - 1}]

        set txt ""
        for {set i 0} {$i < $length} {incr i} {
            set pos [expr {int(rand() * $range)}]
            append txt [string range $chars $pos $pos]
        }
        return $txt
    }

    proc is-numeric {value} {
        if {![catch {expr {abs($value)}}]} {
            return 1
        }
        set value [string trimleft $value 0]
        if {![catch {expr {abs($value)}}]} {
            return 1
        }
        return 0
    }
}