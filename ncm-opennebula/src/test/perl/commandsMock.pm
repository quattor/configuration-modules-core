package commandsMock;

use Test::MockModule;
use Test::More;
use Data::Dumper;
use base 'Exporter';

use sshdata;

sub mock_run_command {
    my ($self, $command) = @_;
    my $cmd = join(" ", @$command);
    # we need to reset the loop
    keys %sshdata::ssh;
    while (my ($short, $data) = each %sshdata::ssh) {
        my $sameparams = $cmd eq $data->{command};
        note("This is my shortname:", $short);
        note("ssh internal command: ", $cmd);
        note("ssh dictionary command: ", $data->{command});
        
        if ($sameparams) {
            note("ssh command found: ", $data->{out});
            return $data->{out};
        }
    }
};

our $onecmd = Test::MockModule->new('NCM::Component::OpenNebula::commands');
$onecmd->mock( 'run_command',  \&mock_run_command);

1;
