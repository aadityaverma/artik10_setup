package Script::Worker;

use strict;
use warnings;
use 5.010001;

use Carp;

use Scalar::Util qw/blessed/;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak "Illegal parameter list has odd number of values" if scalar(@_) % 2;

    my %params = @_;

    my $self = {};
    bless $self, $class;

    _defaultize($self, \%params);
    _validate($self, $params{deploy_steps}, $params{deploy_attrs},
        $params{deploy_attrs_for_output});
    _initialize($self, %params);

    return $self;
}

sub _validate {
    my ($self, $deploy_steps, $deploy_args, $output_attrs) = @_;
    croak "Invalid args in deploy_args: no such step in deploy_steps"
        if grep { not exists $deploy_steps->{$_} } keys %$deploy_args;
    croak "Invalid attributes in output_attrs: no such step in deploy_steps"
        if grep { not exists $deploy_steps->{$_} } keys %$output_attrs;
}

sub _defaultize {
    my ($self, $kwargs_ref) = @_;

    $kwargs_ref->{is_output_beauty} //= 0;
}

sub _initialize {
    my ($self, %kwargs) = @_;

    $self->{beauty_output} = $kwargs{beauty_output};

    eval "use $kwargs{deployer}";         ## no critic
    $self->{deployer} = $kwargs{deployer}->new(%{ $kwargs{deployer_params} });

    # Output handler.
    if (my $class = blessed $kwargs{output} and
        $kwargs{output}->isa('Script::Output')) {
        $self->{output_handler} = $kwargs{output};
    } else {
        eval "use Script::Output::Null";     ## no critic
        $self->{output_handler}= Script::Output::Null->new();
    }

    $self->{deploy_steps} = $kwargs{deploy_steps};
    $self->{deploy_attrs} = $kwargs{deploy_attrs};
    $self->{output_attrs} = $kwargs{deploy_attrs_for_output};

    $self->{deploy_subs} = [];
}

sub run {
    my ($self) = @_;

    use Script::Output::Terminal;
    for my $step (@{ $self->{deploy_steps} }) {
        Script::Output::Terminal->wrap_output(
            $self->deployer(),
            $step,
            $self->{deploy_attrs}->{$step},
            $self->{beauty_output}
        );
    }

}


    # msg_ok => "File downloaded at " . $self->deployer()->dl_path(),
    # delay => 0.1,
    # seq => [ '[/] ', '[-] ', '[\] ', '[|] ' ]

### Accessors

sub deployer {
    my $self = shift;
    return $self->{deployer};
}

sub deploy_subs {
    my $self = shift;
    return $self->{deploy_subs};
}

1;
