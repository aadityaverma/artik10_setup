package Script::Output::Null;

use strict;
use warnings;
use 5.010001;

use Carp;

use parent qw/Script::Output/;

BEGIN {
    for my $m (@Script::Output::_output_methods) {
        use DDP; p __PACKAGE__;
        if (not __PACKAGE__->can($m)) {
            confess "Not impemented all methods!\n";
        }
    }
}

sub new {

}


1;
