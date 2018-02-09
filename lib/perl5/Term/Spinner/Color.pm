package Term::Spinner::Color;

use strict;
use warnings;

use 5.010001;

use POSIX;
use Time::HiRes qw( sleep );

use Term::ANSIColor;
use Term::Cap;

use utf8;
use open ':std', ':encoding(UTF-8)';

$| = 1;    # Disable buffering on STDOUT.

# Couple of instance vars for colors and frame sets
my @colors = qw( red green yellow blue magenta cyan white );
my %frames = (
    'ascii_propeller' => [qw(/ - \\ |)]
);
my $DEFAULT_MSG = "Long process...";

sub new {
    my ($class, %args) = @_;
    my $self = {};

    # seq can either be an array ref with a whole set of frames, or can be the
    # name of a frame set.
    if (!defined($args{seq})) {
        $self->{seq} = $frames{'ascii_propeller'};
    } elsif (ref($args{seq}) ne 'ARRAY') {
        $self->{seq} = $frames{$args{seq}};
    } else {
        $self->{seq} = $args{seq};
    }

    $self->{delay}      = $args{delay}      || 0.2;
    $self->{color}      = $args{color}      || 'cyan';
    $self->{colorcycle} = $args{colorcycle} || 0;
    $self->{bksp}       = chr(0x08);
    $self->{last_size}  = length($self->{seq}[0]);

    if (defined $args{braces} && ref($args{seq}) eq 'ARRAY' && (scalar(@{$args{braces}}) % 2 == 0)) {
        $self->{braces} = $args{braces};
    } else {
        $self->{braces} = [qw([ ])];
    }
    $self->{spaces}     = $args{spaces} || 1;

    return bless $self, $class;
}

sub _hide_cursor {
    print "\x1b[?25l"; 
}

sub _show_cursor {
    print "\x1b[?25h";
}

sub _build_spinnered_msg {
    my ($self, %args) = shift;
    return $self->_build_msg(symbol => $self->{seq}[$self->{_pos}]);
}

sub _build_msg {
    my ($self, %args) = @_;
    my $msg = (exists $args{msg}) ? $args{msg} : $self->{msg};
    my $color = (exists $args{color}) ? $args{color} : $self->{color};
    my $symbol = (exists $args{symbol}) ? $args{symbol} : "*";

    return $self->{braces}[0]       # Left brace
        . " " x $self->{spaces}     # Spaces
        . colored($symbol, $color)  # Spinner symbol
        . " " x $self->{spaces}     # Spaces
        . $self->{braces}[1]        # Right brace
        . $msg;                     # Message
}

sub start {
    my ($self, $msg) = @_;

    $self->{msg} = $msg // $DEFAULT_MSG;
    
    $self->_hide_cursor();   # Hide cursor
    $self->{_pos} = 0;

    if ((index $self->{msg}, " ") != 0) {
        $self->{msg} = " " . $self->{msg};
    }
    my $spinnered_msg = $self->_build_spinnered_msg(); 

    $self->{last_size} = length($spinnered_msg);
    print $spinnered_msg;
}

sub next {
    my ($self) = shift;

    if ($self->{colorcycle}) {
        push @colors, shift @colors;    # rotate the colors list
        $self->{color} = $colors[0];
    }

    $self->{_pos} = ++$self->{_pos} % scalar @{$self->{seq}};
    
    my $spinnered_msg = $self->_build_spinnered_msg(); 

    print $self->{bksp} x $self->{last_size};
    print "\e[2K" . "\r";
    print $spinnered_msg;

    $self->{last_size} = length($spinnered_msg);
}

sub done {
    my $self = shift;

    print $self->{bksp} x $self->{last_size};
    print "\e[2K" . "\r";
    $self->_show_cursor();    # Show cursor
}

# Fork and run spinner asynchronously, until signal received.
sub auto_start {
    my ($self, $msg) = @_;

    $self->{msg} = $msg // $DEFAULT_MSG;

    my $ppid = $$;
    my $pid  = fork();
    die("Failed to fork progress indicator.\n") unless defined $pid;

    if ($pid) {           # Parent
        $self->{child_pid} = $pid;
        return;
    } else {                # Kid stuff
        $self->start($msg);
        my $exists;
        while (1) {
            sleep $self->{delay};
            $self->next();

            # Check to be sure parent is still running, if not, die
            $exists = kill 0, $ppid;
            unless ($exists) {
                $self->done();
                exit 0;
            }
            $exists = "";
        }
        exit 0;    # Should never get here?
    }
}

sub auto_done {
    my $self = shift;

    kill 'KILL', $self->{child_pid};
    my $pid = wait();
    $self->done();
}

sub auto_ok {
    my ($self, $msg) = @_;
    $msg //= "Done!";
    $msg = " " . $msg if index($msg, " ") != 0;
    $msg = $self->_build_msg(symbol => "+", color => 'green', msg => $msg);
    $self->auto_done();
    say $msg;
}

sub auto_warn {
    my ($self, $msg) = @_;
    $msg //= "Warning!";
    $msg = " " . $msg if index($msg, " ") != 0;
    $msg = $self->_build_msg(symbol => "!", color => 'yellow', msg => $msg);
    $self->auto_done();
    say $msg;
}

sub auto_fail {
    my ($self, $msg) = @_;
    $msg //= "Failed!";
    $msg = " " . $msg if index($msg, " ") != 0;
    $msg = $self->_build_msg(symbol => "x", color => 'red', msg => $msg);
    $self->auto_done();
    say $msg;
}

1;