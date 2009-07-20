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

use constant PATH => '/software/components/nrpe/';
use constant FILE => '/etc/nagios/nrpe.cfg';

sub Configure {
    my ($self, $config) = @_;
    my $st = $config->getElement (PATH)->getTree;
    my $fh = FileHandle->new (FILE, 'w');
    unless ($fh) {
        throw_error ("Couldn't open " . FILE);
        return;
    }

    # Output caution header
    $fh->print ("# /etc/nagios/nrpe.cfg\n");
    $fh->print ("# written by ncm-nrpe. Do not edit!\n");
    
    # Output unreferenced options
    while (my ($key, $value) = each (%{$st})) {
      $fh->print ("$key=$value\n") unless (ref($value) eq "ARRAY" || ref($value) eq "HASH");
    }

    # Output allowed_hosts array as a comma separated string
    $fh->print ("allowed_hosts=");
    $fh->print (join (",", @{$st->{allowed_hosts}}));
    seek ($fh, 1, -1);
    $fh->print ("\n");

    # Output nrpe_commands 
    while (my ($cmdname, $cmdline) = each (%{$st->{cmds}})) {
        $fh->print ("command[$cmdname]=$cmdline\n");
    }

    # Output external files' includes
    for my $fn (@{$st->{external_files}}) {
        $fh->print ("include=$fn\n");
    } 

    # Try to close the output file
    unless(close($fh)) {
        throw_error ("cannot close " . FILE);
        return;
    }

    # Restart daemon
    execute (["/etc/init.d/nrpe", "restart"]);
        
    # Get the PID from pid_file
    my $stdout;
    my $status = execute (["/usr/bin/tail", "-n1", "$st->{pid_file}"], stdout => \$stdout,);
    my $retval = $?;
    unless (defined $status && $status) {
        throw_error ("could not tail pid_file");
        return;
    }
    if ($retval) {
        throw_error ("no pid_file after restart");
        return;
    }
    
    # Check PID is a number string
    chomp ($stdout);
    unless ($stdout =~ /^[0-9]+$/) {
        throw_error ("nrpe failed to restart");
        return;
    }
    
    # Success
    return;
}

1;