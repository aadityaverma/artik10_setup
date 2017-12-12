package Script::Output::Null;

use strict;
use warnings;
use 5.010001;

use Carp;

use parent qw/Script::Output/;

CHECK {
    for my $m (@Script::Output::_output_methods) {
        if (not __PACKAGE__->can("_${m}_impl")) {
            confess "Method _${m}_impl is not implemented in " . __PACKAGE__ . "!\n";
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

sub _info_impl          { return }
sub _success_impl       { return }
sub _warn_impl          { return }
sub _fail_impl          { return }
sub _wrapper_begin_impl { return }
sub _wrapper_end_impl   { return }

1;
