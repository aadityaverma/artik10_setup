package Script::Worker;

use strict;
use warnings;
use 5.010001;

use Carp;
use Scalar::Util qw/blessed/;

BEGIN {
    my $__generate_accessor = sub {
        my ($field) = @_;
        return sub {
            my $self = shift;
            return $self->{$field};
        };
    };

    my %accessors = (
        deployer    => 'deployer',
        deploy_subs => 'deploy_subs',
    );
    for my $field (keys %accessors) {
        no strict 'refs';       ## no critic
        *{ __PACKAGE__ . "::$accessors{$field}" } = $__generate_accessor->($field);
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
    my ($self, $kwargs_ref) = @_;

    $kwargs_ref->{is_output_beauty} //= 0;
}

sub _validate {
    my ($self, $params) = @_;
    croak "Invalid args in deploy_args: no such step in deploy_steps"
        if grep { not exists $params->{deploy_steps}->{$_} } keys %{$params->{deploy_attrs}};
    croak "Invalid attributes in output_attrs: no such step in deploy_steps"
        if grep { not exists $params->{deploy_steps}->{$_} } keys %{$params->{deploy_attrs_for_output}};

    # Don't try to pass output_handler via params for deployer
    delete $params->{deployer_params}->{output_handler}
        if (exists $params->{deployer_params}->{output_handler});
}

sub _initialize {
    my ($self, %kwargs) = @_;

    $self->{beauty_output} = $kwargs{beauty_output};

    # Output handler.
    if (my $class = blessed $kwargs{output}
        and $kwargs{output}->isa('Script::Output'))
    {
        $self->{output_handler} = $kwargs{output};
    } else {
        use Script::Output::Null;
        $self->{output_handler} = Script::Output::Null->new();
    }

    # Deployer package import and instance creation
    eval "require $kwargs{deployer}"   ## no critic
    or do {
        confess "Cannot find deployer class $kwargs{deployer}!\n";
    };
    $self->{deployer} = $kwargs{deployer}->new(
        output_handler  => $self->{output_handler},
        %{ $kwargs{deployer_params} },
    );

    $self->{deploy_steps} = $kwargs{deploy_steps};
    $self->{deploy_attrs} = $kwargs{deploy_attrs};

    $self->{output_attrs} = $kwargs{deploy_attrs_for_output};

    $self->{deploy_subs} = [];
}

sub run {
    my ($self) = @_;

    for my $step (@{ $self->{deploy_steps} }) {
        $self->deployer()->$step($self->{deploy_attrs}->{$step});
    }

}

# msg_ok => "File downloaded at " . $self->deployer()->dl_path(),
# delay => 0.1,
# seq => [ '[/] ', '[-] ', '[\] ', '[|] ' ]

1;
