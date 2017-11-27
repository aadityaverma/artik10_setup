#!/usr/bin/env bash

source "./zypper-installer"
_banner
_banner "$"
_print_with_banner ":("
_print_with_indent "hahahaha how the fuck is real bash programming"
echo $(./get-artik-ip.tcl /dev/ttyUSB1)
