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

BEGIN {
    my $__generate_accessor = sub {
        my ($field) = @_;
        return sub {
            my ($self, $value) = @_;
            if (defined $value) {
                $self->{$field} = $value;
                return $self;
            } else {
                return $self->{$field};
            }
        };
    };

    my @fields = qw/ board uri dl_path unzip_path tizen_plugin_path
        tizen_plugin_filename/;
    for my $f (@fields) {
        no strict 'refs';    ## no critic
        *{ __PACKAGE__ . "::$f" } = $__generate_accessor->($f);
    }
}

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

    $params->{tizen_plugin_filename} //= "common_plugin_tizen3.0_artik7.zip";
    $params->{uri} //=
        "https://s3-us-west-2.amazonaws.com/tizendriver/"
        . $params->tizen_plugin_filename();
    $params->{dl_path} //= "/tmp/artik-builder/.cache";
    $params->{unzip_path} //=
        "/tmp/artik-builder/" . $self->board() . "/uncompressed";

    # Get instance of null output handler, if not specified
    if (not ( my $class = blessed $params->{output_handler}
              and $params->{output_handler}->isa('Script::Output') ))
    {
        my $null_handler = "Script::Output::Null";
        eval "use $null_handler";    ## no critic
        $params->{output_handler} = $null_handler->new();
    }

}

sub _initialize {
    my ($self, %kwargs) = @_;
    for my $k (keys %kwargs) {
        $self->{$k} = $kwargs{$k};
    }

    (my $unzip_dir = $self->unzip_path()) =~ s{/.+$}{};
    make_path $self->dl_path, $unzip_dir;

}

### Methods

sub get_file {
    my $self = shift;
    if (not -e $self->dl_path() . "/" . $self->tizen_plugin_filename()) {
        my $ff = File::Fetch->new(uri => $self->uri());
        $self->tizen_plugin_path($ff->fetch(to => $self->dl_path));

        # We should ignore warnings and error in case when we successfully
        # downloaded file even if they're being raised implicitly by module's
        # logic. See perlmonks thread (http://www.perlmonks.org/?node_id=1154154).
        if ($ff->error()
            && -e $self->tizen_plugin_path())
        {
            # return error
        }
    } else {
        $self->{output_handler}->info("Plugin file in cache. Using it...");
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
