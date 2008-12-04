# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::nrpe;

use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Property;
use NCM::Check;
use FileHandle;
use LC::Process qw (execute);
use LC::Exception qw (throw_error);

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use constant PATH	=> '/software/components/nrpe/';
use constant CMDS	=> 'cmds';
use constant RC		=> 'add_rc';
use constant FILE	=> '/etc/nagios/nrpe.cfg';

sub Configure
{
	my ($self, $config) = @_;
	my $st = $config->getElement(PATH)->getTree;
	my $fh = FileHandle->new (FILE, 'w');
	unless ($fh) {
		throw_error ("Couldn't open " . FILE);
		return 0;
	}

	$fh->print ("# nrpe.cfg\n",
		    "# written by ncm-nrpe. Do not edit!\n",
		    "pid_file=/var/run/nrpe.pid\n",
		    "server_port=$st->{port}\n",
		    "nrpe_user=$st->{user}\n",
		    "nrpe_group=$st->{group}\n",
		    "command_timeout=$st->{timeout}\n",
		    "dont_blame_nrpe=$st->{allow_cmdargs}\n",
		    "allow_weak_random_seed=$st->{weak_random}\n");

	$fh->print ("command_prefix=$st->{prefix}\n") if $st->{prefix};


	$fh->print("allowed_hosts=");
	$fh->print (join (",", @{$st->{allowed_hosts}}));
	seek ($fh, 1, -1);
	$fh->print("\n");
	while (my ($cmdname, $cmdline) = each (%{$st->{cmds}})) {
		$fh->print("command[$cmdname]=$cmdline\n");
	}

    # external files
    if ( $config->elementExists (PATH . 'external_files') ) {
        my $el = $config->getElement (PATH . 'external_files')->getTree;
        foreach my $f (@$el) {
            $fh->print("include=$f\n");
        }
    }


	execute (["/sbin/chkconfig", "nrpe", $st->{add_rc}?'on':'off']);
	execute (["/etc/init.d/nrpe", "restart"]);
	return 1;
}
