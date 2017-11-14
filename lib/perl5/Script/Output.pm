package Script::Output;

use strict;
use warnings;
use 5.010001;

our @_output_methods = ();

BEGIN {
    @_output_methods = qw/ success warn fail wrapper_begin wrapper_end /;

    my $__generate_method = sub {
        my $impl_method = "_$_[0]_impl";
        return sub {
            my ($self, $msg) = @_;
            return $self->$impl_method();
        }
    };

    for my $m (@_output_methods) {
        my $m_ref = $__generate_method->($m);
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
