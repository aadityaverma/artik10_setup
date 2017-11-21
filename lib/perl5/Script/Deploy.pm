package Script::Deploy;

# ABSTRACT: Deployment script for Artik

use strict;
use warnings;

use Script::Worker;
use Getopt::Long;

sub run {
    my ($package) = @_;
    use Script::Output::Terminal;
    my $output = Script::Output::Terminal->new();
    my $worker = Script::Worker->new(
        beauty_output   => 1,
        deployer        => "Deploy::Artik::Artik7",
        output          => $output,
        deploy_steps    => [
            'get_file',
            'unzip',
        ],
    );
    $worker->run();
}

1;
