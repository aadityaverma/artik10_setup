#!/usr/bin/env perl

use strict;
use warnings;
use 5.010001;

use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib', 'perl5');

use Script::Deploy;

# Script::Deploy->run();
use Script::Output; if (Script::Output->new()->can('warn')) { say "Yay!" };
# use Deploy::Artik::Artik7;
# Deploy::Artik::Artik7->new()->process_plugin()
