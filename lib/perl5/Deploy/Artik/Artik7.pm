package Deploy::Artik::Artik7;
use strict;
use warnings;
use 5.010001;

use Attribute::Handlers;
use Carp;

use File::Path qw/make_path/;
use File::Spec::Functions qw/splitpath/;
use File::Fetch;
use IO::File;
use IO::Uncompress::Unzip qw//;

use Term::Spinner::Color::Beautyfied qw//;

$File::Fetch::WARN = 0;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak "Illegal parameter list has odd number of values" if scalar(@_) % 2;

    my %params = @_;

    my $self = {};
    bless $self, $class;

    $self->{board} = "artik-710";

    _defaultize($self, \%params);
    _initialize($self, %params);

    return $self;
}

sub _defaultize {
    my ($self, $params) = @_;

    $params->{uri} //=
"https://s3-us-west-2.amazonaws.com/tizendriver/common_plugin_tizen3.0_artik7.zip";
    $params->{dl_path} //= "/tmp/artik-builder/.cache";
    $params->{unzip_path} //=
        "/tmp/artik-builder/" . $self->board() . "/uncompressed";
}

sub _initialize {
    my ($self, %kwargs) = @_;
    for my $k (keys %kwargs) {
        $self->{$k} = $kwargs{$k};
    }

    (my $unzip_dir = $self->unzip_path()) =~ s{/.+$}{};
    make_path $self->dl_path, $unzip_dir;
<<<<<<< HEAD

}

use Attribute::Handlers;

sub BeautyTerm : ATTR(CODE) {
    my ($package, $typeglob, $func, $attr, $data) = @_;

    my ($msg_start, %msgs_end) = shift @$data;
    my %kwargs = @$data;
    for my $msg ('msg_ok', 'msg_warn', 'msg_fail') {
        if (exists $kwargs{$msg}) {
            $msgs_end{$msg} = $kwargs{$msg};
            delete $kwargs{$msg};
        }
    }
    my $spin = Term::Spinner::Color::Beautyfied->new(%kwargs);
    no strict 'refs';          ## no critic
    no warnings 'redefine';    ## no critic
    *{$typeglob} = sub {
        $spin->auto_start($msg_start);
        $func->(@_);
        $spin->auto_ok($msgs_end{msg_ok});
    };
=======
>>>>>>> 07a593db7e4fa7f889ff416020234adf53a07854
}

### Accessors

sub board {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{board} = $value;
        return $self;
    } else {
        return $self->{board};
    }
}

sub uri {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{uri} = $value;
        return $self;
    } else {
        return $self->{uri};
    }
}

sub dl_path {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{dl_path} = $value;
        return $self;
    } else {
        return $self->{dl_path};
    }
}

sub unzip_path {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{unzip_path} = $value;
        return $self;
    } else {
        return $self->{unzip_path};
    }
}

sub tizen_plugin_path {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{tizen_plugin_path} = $value;
        return $self;
    } else {
        return $self->{tizen_plugin_path};
    }
}

### Methods

sub get_file {
    my $self = shift;
    my $ff = File::Fetch->new(uri => $self->uri());
    $self->tizen_plugin_path($ff->fetch(to => $self->dl_path));

    # eval {
    # } or do {
    #     say "error"
    # };

    # We should ignore warnings and error in case when we successfully
    # downloaded file even if they're being raised implicitly by module's
    # logic. See perlmonks thread (http://www.perlmonks.org/?node_id=1154154).
    if ($ff->error()
        && -e $self->tizen_plugin_path())
    {
        # return error
    }
    return $self;
}

sub unzip {
    my $self  = shift;
    my $unzip = IO::Uncompress::Unzip->new($self->tizen_plugin_path);

    my $status;
    for ($status = 1; $status > 0; $status = $unzip->nextStream()) {
        my $header = $unzip->getHeaderInfo();
        my (undef, $path, $name) = splitpath($header->{Name});

        if ($name =~ m|/$|) {
            last if $status < 0;
            next;
        }

        my $buff;
        my $fh = IO::File->new($self->unzip_path, "w")
            or die "Couldn't write to " . $self->unzip_path . ": $!";
        while (($status = $unzip->read($buff)) > 0) {
            $fh->write($buff);
        }
        $fh->close();
        my $stored_time = $header->{'Time'};
        utime($stored_time, $stored_time, $self->unzip_path)
            or die "Couldn't touch " . $self->unzip_path . ": $!";
    }

    die "Error processing " . $self->tizen_plugin_path . ": $!\n"
        if $status < 0;

    return $self;
}

sub process_plugin {
    my $self = shift;

    $self->get_file;
    $self->unzip;

    return $self;
}

1;
