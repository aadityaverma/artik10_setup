package Term::Spinner::Color::Beautyfied;

use strict;
use warnings;
use 5.010;

use Attribute::Handlers;
use Storable qw/dclone/;

use Term::ANSIColor;

use parent 'Term::Spinner::Color';

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->{'old_seq'} = dclone($self->{'seq'});

    # $self->set_signal_handlers();
    return $self;
}

# sub set_signal_handlers {
#     my $self = shift;
#     $SIG{__DIE__} = sub { $self->handle_DIE() }
# }
#
# sub handle_DIE {
#     my $self = shift;
#     $self->print_result("!!! Critical error! Exit...\n");
# }

sub auto_start {
    my ($self, $msg) = @_;
    $msg //= "Long process...";
    $msg = " " . $msg if !$self->{'seq'}[0] =~ /^.* $/;
    $self->{'seq'} = [ map { $_ . $msg } @{ $self->{'seq'} } ];
    $self->{'last_size'} = length($self->{'seq'}[0]);
    $self->SUPER::auto_start();
}

sub auto_ok {
    my ($self, $msg) = @_;
    $msg //= "Done!";
    $msg = " " . $msg if index($msg, " ") != 0;
    $self->print_result("[" . colored("+", 'green') . "]" . $msg);
}

sub auto_warn {
    my ($self, $msg) = @_;
    $msg //= "Warning!";
    $msg = " " . $msg if index($msg, " ") != 0;
    $self->print_result("[" . colored("!", 'yellow') . "]" . $msg);
}

sub auto_fail {
    my ($self, $msg) = @_;
    $msg //= "Failed!";
    $msg = " " . $msg if index($msg, " ") != 0;
    $self->print_result("[" . colored("x", 'red') . "]" . $msg);
}

sub print_result {
    my ($self, $msg) = @_;
    $self->auto_done();
    say $msg;
    $self->{'seq'} = dclone($self->{'old_seq'});
}

sub done {
    my $self = shift;

    print "\e[2K" . "\r" . "\x1b[?25h";
}

1;
