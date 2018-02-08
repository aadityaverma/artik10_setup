#!/usr/bin/env tclsh

if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    lappend auto_path [file join lib tcl]
    ::tcl::tm::path add [file join [file normalize [file dirname [info script]]] lib tcl]
    package require Deployer::Artik

    ::Deployer::Artik::parse-cli-opts
    ::Deployer::Artik::do
}
