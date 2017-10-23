#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use FindBin;
use lib "$FindBin::Bin/../lib/perl5";

use Local::Deploy::Artik::Artik7;

my $artik = Local::Deploy::Artik::Artik7->new();
$artik->process_plugin;
