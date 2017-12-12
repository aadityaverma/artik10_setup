package Script::Output::Terminal;

use strict;
use warnings;
use 5.010001;

use Carp;

use parent qw/Script::Output/;

CHECK {
    for my $m (@Script::Output::_output_methods) {
        if (not __PACKAGE__->can("_${m}_impl")) {
            confess "Method _${m}_impl is not implemented! \n";
        }
    }
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak "Illegal parameter list has odd number of values" if scalar(@_) % 2;

    my %params = @_;

    my $self = {};
    bless $self, $class;

    _defaultize($self, \%params);
    _validate($self, \%params);
    _initialize($self, %params);

    return $self;
}

sub _defaultize {
    my ($self, $params) = @_;

    $params->{prefix} ||= "[ * ]";

    $params->{info}    ||= "i";
    $params->{success} ||= "+";
    $params->{warn}    ||= "!";
    $params->{fail}    ||= "x";

    $self->{_brackets} = {
        "(" => ")",
        "[" => "]",
        "{" => "}",
        "<" => ">",
    };
}

sub _validate {
    my ($self, $params) = @_;

    # Prefix and event holders validation
    my $event_holder_length = 0;
    my $open_brackets = quotemeta join '', keys %{ $self->{_brackets} };
    # Consider pure function, i.e. without side effects. Allow using in
    # `(??{ code })` extended pattern
    my $get_end_prefix = sub {
        return
            exists $self->{_brackets}->{ $_[0] }
            ? $self->{_brackets}->{ $_[0] }
            : $_[0];
    };

    say $params->{prefix};
    say $open_brackets;

    # Parsing prefix template
    unless (
        $params->{prefix} =~ m!^
        (?<open> [$open_brackets]|[^\w\s] )         # Open bracket or non-word or non-ws
            (?<lws> \s* )                           # Any ws
                (?<evhold> [*]+ )                   # Event holder
            (?<rws> \g{2} )                         # Backref to ws
        (?<clos> (??{ $get_end_prefix->($1) }) )    # Match to bracket or the same symbol
        $!x
        )
    {
        confess "Prefix is not valid pattern!\n";
    }
    for my $event (qw/info success warn fail/) {
        confess "Event string's length is not equal to holder's one!\n"
            if length $params->{$event} != length $3;
    }

    $params->{_opening_part_prefix} = $1 . $2;
    $params->{_closing_part_prefix} = $4 . $5;
}

sub _initialize {
    my ($self, %params) = @_;

    for my $event (qw/info success warn fail/) {
        $self->{$event} = $params{_opening_part_prefix}
            . $params{$event}
            . $params{_closing_part_prefix};
    }

}

sub wrap_output {
    my ($package, $obj, $method, $paramsref, $beautyness) = @_;
    my @result   = ();
    my %msgs_end = ();

    my $msg_start = "OK";
    $msgs_end{msg_ok} = "End OK";

    if ($beautyness) {
        use Term::Spinner::Color::Beautyfied;
        my $spin = Term::Spinner::Color::Beautyfied->new(
            delay => 0.1,
            seq   => [ '[/] ', '[-] ', '[\] ', '[|] ' ]
        );
        $spin->auto_start($msg_start);
        @result = $obj->$method(@$paramsref);
        $spin->auto_ok($msgs_end{msg_ok});
    } else {
        @result = $obj->$method(@$paramsref);
    }

    return @result;
}

sub BeautyTerm : ATTR(CODE) {
    my ($package, $typeglob, $func, $attr, $data) = @_;

    my %kwargs = ();
    %kwargs = %$data if defined $data;
    my ($msg_start, %msgs_end) = shift @$data;
    for my $msg ('msg_ok', 'msg_warn', 'msg_fail') {
        if (exists $kwargs{$msg}) {
            $msgs_end{$msg} = $kwargs{$msg};
            delete $kwargs{$msg};
        }
    }

    use Term::Spinner::Color::Beautyfied;
    my $spin = Term::Spinner::Color::Beautyfied->new(%kwargs);
    no strict 'refs';    ## no critic
    *{$typeglob} = sub {
        $spin->auto_start($msg_start);
        $func->(@_);
        $spin->auto_ok($msgs_end{msg_ok});
    };
}

1;
