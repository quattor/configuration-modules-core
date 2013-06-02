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

    my $mode = $config->getElement('/software/components/nrpe/mode')->getValue();
    my $owner = "root";
    my $group = $st->{nrpe_group};

    # Open file
    my $fw = CAF::FileWriter->open (FILE,
                                    mode => $mode,
                                    owner => $owner,
                                    group => $group,
                                    log => $self);

    # Output caution header
    print $fw ("# /etc/nagios/nrpe.cfg\n");
    print $fw ("# written by ncm-nrpe. Do not edit!\n");

    # Output unreferenced options sorted
    foreach my $key (sort(keys %{$st})) {
        my $value = $st->{$key};
        print $fw ("$key=$value\n") unless (ref($value) eq "ARRAY" || ref($value) eq "HASH");
    }

    # Output allowed_hosts array as a comma separated string
    print $fw ("allowed_hosts=" . join (",", @{$st->{allowed_hosts}}) . "\n");

    # Output nrpe_commands sorted
    foreach my $cmdname (sort(keys %{$st->{command}})) {
        my $cmdline = $st->{command}->{$cmdname};
        print $fw ("command[$cmdname]=$cmdline\n");
    }

    # Output external files' includes
    foreach my $fn (@{$st->{include}}) {
        print $fw ("include=$fn\n");
    }

    # Output directory includes
    foreach my $dn (@{$st->{include_dir}}) {
        print $fw ("include_dir=$dn\n");
    }

    # Close the output file
    $fw->close ();

    # Restart daemon
    my $proc = CAF::Process->new ([qw(/sbin/service nrpe restart)], log => $self);
    $proc->execute ();

    if ($?) {
	$self->error("Failed to restart NRPE");
	return 0;
    }

    # Success
    return 1;
}

1;
