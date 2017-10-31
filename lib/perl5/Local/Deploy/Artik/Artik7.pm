package Local::Deploy::Artik::Artik7;
use strict;
use warnings;
use 5.010;

use Carp;

use File::Path qw/make_path/;
use File::Spec::Functions qw/splitpath/;
use IO::File;
use IO::Uncompress::Unzip qw//;

use File::Fetch;
use Term::Spinner::Color;

$File::Fetch::WARN = 0;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak "Illegal parameter list has odd number of values" if scalar(@_) % 2;

    my %params = @_;

    my $self = {};
    bless $self, $class;

    $self->{'board'} = "artik-710";

   # This could be abstracted out into a method call if you
   # expect to need to override this check.
   # for my $required (qw/ name rank serial_number /) {
   #     croak "Required parameter '$required' not passed to '$class' constructor"
   #         unless exists $params{$required};
   # }

    $self->_defaultize(\%params);
    $self->_initialize(\%params);

    # initialize all attributes by passing arguments to accessor methods.
    # for my $attr ( keys %params ) {
    #
    #     croak "Invalid parameter '$attr' passed to '$class' constructor"
    #         unless $self->can( $attr );
    #
    #     $self->$attr( $params{$attr} );
    # }
    return $self;
}

sub _defaultize {
    my ($self, $params) = @_;

    $params->{'uri'} //=
"https://s3-us-west-2.amazonaws.com/tizendriver/common_plugin_tizen3.0_artik7.zip";
    $params->{'dl_path'} //= "/tmp/artik-builder/.cache";
    $params->{'unzip_path'} //= "/tmp/artik-builder/" . $self->board;
}

sub _initialize {
    my ($self, $params) = @_;
    for my $k (keys %$params) {
        $self->{$k} = $params->{$k};
    }
    make_path $self->dl_path, $self->unzip_path;

}

sub get_file {
    my $self = shift;
    my $ff = File::Fetch->new(uri => $self->uri);
    $self->tizen_plugin_path($ff->fetch(to => $self->dl_path));

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

### Accessors

sub board {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{'board'} = $value;
        return $self;
    } else {
        return $self->{'board'};
    }
}

sub uri {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{'uri'} = $value;
        return $self;
    } else {
        return $self->{'uri'};
    }
}

sub dl_path {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{'dl_path'} = $value;
        return $self;
    } else {
        return $self->{'dl_path'};
    }
}

sub unzip_path {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{'unzip_path'} = $value;
        return $self;
    } else {
        return $self->{'unzip_path'};
    }
}

sub tizen_plugin_path {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{'tizen_plugin_path'} = $value;
        return $self;
    } else {
        return $self->{'tizen_plugin_path'};
    }
}

### Methods

sub process_plugin {
    my $self = shift;
    my $spin = Term::Spinner::Color->new(
      'delay' => 0.3,
      'colorcycle' => 1,
      );
    $spin->run_ok($self->get_file);
    $spin->run_ok($self->unzip);
    return $self;
}

1;
