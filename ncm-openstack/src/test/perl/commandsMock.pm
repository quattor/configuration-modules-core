package commandsMock;

use Test::MockModule;
use Test::More;
use Data::Dumper;
use base 'Exporter';

use cmdata;

sub mock_run_command 
{
    my ($self, $command) = @_;
    my $fullcmd = join(" ", @$command);
    # we need to reset the loop
    keys %cmdata::cmd;
    while (my ($short, $data) = each %cmdata::cmd) {
        my $sameparams = $fullcmd eq $data->{command};
        note("This is my shortname:", $short);
        note("internal command: ", $fullcmd);
        note("dictionary command: ", $data->{command});
        
        if ($sameparams) {
            note("command found: ", $data->{out});
            return $data->{out};
        }
    }
}

our $oscmd = Test::MockModule->new('NCM::Component::OpenStack::Commands');
$oscmd->mock( 'run_command', \&mock_run_command);

1;
