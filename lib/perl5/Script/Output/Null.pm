package Script::Output::Null;

use strict;
use warnings;
use 5.010001;

use Carp;

use parent qw/Script::Output/;

BEGIN {
    my @methods = qw! success warn fail wrapper_begin wrapper_end !;
    for my $m (@methods) {
        use DDP; p __PACKAGE__;
        if (not __PACKAGE__->can($m)) {
            confess "Not impemented all methods!\n";
        }
    }
}

sub new {

}


1;
