if {![package vsatisfies [package provide Tcl] 8.5]} {return}
package ifneeded Deployer::Artik 0.0.1 [list source [file join $dir artik.tm]]
