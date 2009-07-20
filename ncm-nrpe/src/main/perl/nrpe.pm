# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::nrpe;

use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Property;
use NCM::Check;
use CAF::FileWriter;
use CAF::Process;
use LC::Exception qw (throw_error);

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use constant PATH => '/software/components/nrpe/options/';
use constant FILE => '/etc/nagios/nrpe.cfg';

sub Configure {
    my ($self, $config) = @_;
    my $st = $config->getElement (PATH)->getTree;
    my $fw = CAF::FileWriter->open (FILE, log => $self);
    unless ($fw) {
        throw_error ("Couldn't open " . FILE);
        return;
    }

    # Output caution header
    $fw->print ("# /etc/nagios/nrpe.cfg\n");
    $fw->print ("# written by ncm-nrpe. Do not edit!\n");
    
    # Output unreferenced options
    while (my ($key, $value) = each (%{$st})) {
      $fw->print ("$key=$value\n") unless (ref($value) eq "ARRAY" || ref($value) eq "HASH");
    }

    # Output allowed_hosts array as a comma separated string
    $fw->print ("allowed_hosts=" . join (",", @{$st->{allowed_hosts}}) . "\n");

    # Output nrpe_commands 
    while (my ($cmdname, $cmdline) = each (%{$st->{cmds}})) {
        $fw->print ("command[$cmdname]=$cmdline\n");
    }

    # Output external files' includes
    foreach my $fn (@{$st->{external_files}}) {
        $fw->print ("include=$fn\n");
    } 

    # Close the output file
    $fw->close ();

    # Restart daemon
    my $proc = CAF::Process->new (["/etc/init.d/nrpe", "restart"], log => $self);
    $proc->execute ();
        
    # Check PID file
    $st->{pid_file} = '/var/run/nrpe.pid' unless(exists $st->{pid_file});
    unless (-s $st->{pid_file}) {
        throw_error ("nrpe failed to restart");
        return;
    }
    
    # Success
    return;
}

1;