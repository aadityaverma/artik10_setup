package Script::Output::Null;

use strict;
use warnings;
use 5.010001;

use Carp;

use parent qw/Script::Output/;

BEGIN {
    for my $m (@Script::Output::_output_methods) {
        if (not __PACKAGE__->can($m)) {
            confess "Not impemented all methods!\n";
        }
    }
}

my $instance = undef;

sub new {
    my ($class) = @_;
    my $self = {};
    $instance = bless $self, $class unless $instance;
    return $instance;
}

1;
