#!/usr/bin/env tclsh

package require Tcl 8.5
source yapal.tcl

set auto_path [linsert $auto_path 0 ..]

namespace eval myprog {
    # first, show all the argument types that exist and how
    #  they are declared (including default value)
    argp::registerArgs process1 {
        {-name   string  }
        {-nice   integer }
        {-%cpu   double  }
        {-alive  boolean }
    }

    # show how different value ranges can be defined
    argp::registerArgs process2 {
        {-name   string  tclsh {tclsh tcl wish wishx} }
        {-nice   integer 0  { {-20 20} }              }
        {-%cpu   double  0  { {0 100 } }              }
        {-alive  bool    1  }
    }
    
#    ::yapal::registerArgs myparse {
#	{-name   string  tclsh {tclsh tcl wish wishx}                }
#	{-number integer 10    { { - -20 } { 5 100 } { 200 +} }      }
#	{-%cpu   double  90    { 50.0 50.1 50.3  { 90 100 } }        }
#	{-alive  boolean 1     { 1 }                                 }
#    }
}

proc myprog::myparse {args} {
    # parse
    ::yapal::parseArgs opts

    # and show the values (given or set by default)
    foreach {k v} [array get opts] {
       puts "option $k has value $v"
    }
}

eval myprog::myparse $argv
