package Script::Output;

use strict;
use warnings;
use 5.010001;

BEGIN {
    my $make_method = sub {
        my $impl_method = "_$_[0]_impl";
        return sub {
            my ($self, $msg) = @_;
            return $self->$impl_method();
        }
    };

    my @methods = qw! success warn fail wrapper_begin wrapper_end !;
    for my $m (@methods) {
        my $m_ref = $make_method->($m);
        no strict 'refs';       ## no critic
        *{__PACKAGE__ . "::$m"} = $m_ref;
    }
}

sub new {
    my ($class) = @_;
    my $self = {};

    return bless $self, $class;
}

1;
