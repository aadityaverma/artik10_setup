#!/usr/bin/env tclsh

if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    lappend auto_path [file join .. lib tcl]
    ::tcl::tm::path add [file join [file normalize [file dirname [info script]]] .. lib tcl]
    package require Deployer::Artik

    try {
        ::Deployer::Artik::parse-cli-opts
    } on error {reason options} {
        switch $reason {
            "Invalid path to device" {
                puts "Error! Device [dict get $options device] doesn't exist. Aborting..."
                exit 1
            }
        }
    }

    try {
        ::Deployer::Artik::do
    } on error {reason options} {
        switch $reason {
            "Interface has no IP" {
                exit 2
            }
            "Screen terminated" {
                exit 3
            }
            "Timeout" {
                exit 4
            }
            "Cannot create directory!" {
                puts "Error! Cannot create directory [dict get $options dirname]. Aborting..."
                exit 5
            }
            "Cannot open file!" {
                puts "Error! Cannot open file [dict get $options fname] for writing. Aborting..."
                exit 5
            }
        }
    }

    exit 0
}
