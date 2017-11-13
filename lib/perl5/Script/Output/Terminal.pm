package Script::Output::Terminal;

use strict;
use warnings;
use 5.010001;

use Exporter 'import';
our @EXPORT_OK = qw/BeautyTerm/;

use Attribute::Handlers;

sub wrap_output {
    my ($package, $obj, $method, $paramsref, $beautyness) = @_;
    my @result = ();
    my %msgs_end = ();

    my $msg_start = "OK";
    $msgs_end{msg_ok} = "End OK";

    if ($beautyness) {
        use Term::Spinner::Color::Beautyfied;
        my $spin = Term::Spinner::Color::Beautyfied->new(delay => 0.1,
        seq => [ '[/] ', '[-] ', '[\] ', '[|] ' ]);
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
