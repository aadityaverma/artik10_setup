#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib', 'perl5');

use Script::Deploy;

Script::Deploy->run();
# use Deploy::Artik::Artik7;
# Deploy::Artik::Artik7->new()->process_plugin()
