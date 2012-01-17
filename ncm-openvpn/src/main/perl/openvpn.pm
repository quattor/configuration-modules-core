# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::openvpn;

use strict;
use warnings;
use NCM::Component;
use CAF::Process;
use CAF::FileWriter;
use LC::Exception qw (throw_error);

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

sub setup_client
{
    my ($self, $client, $cfg) = @_;

    $self->verbose("Setting up client: $client");

    my $fh = CAF::FileWriter->new($cfg->{configfile},
				  log => $self,
				  backup => ".old");
    delete($cfg->{configfile});


    print $fh join("\n", map("remote $_", @{$cfg->{remote}}), "");
    delete($cfg->{remote});

    while (my ($k, $v) = each(%$cfg)) {
	# Boolean options are printed only if they are true
	if ($v eq '1') {
	    print $fh "$k\n";
	} elsif ($v ne '0') {
	    print $fh "$k $v\n";
	}
    }
    return $fh->close();
}

sub setup_clients
{
    my ($self, $tree) = @_;

    my $changed = 0;

    while (my ($clnt, $cfg) = each(%$tree)) {
	$changed ||= $self->setup_client($clnt, $cfg);
    }

    return $changed;
}

sub setup_server
{
    my ($self, $tree) = @_;

    $self->verbose("Setting up server configuration");
    my $fh = CAF::FileWriter->open($tree->{configfile},
				   log => $self,
				   backup => ".old");
    delete($tree->{configfile});

    print $fh join("\n", map("push $_", @{$tree->{push}}), "")
	 if exists($tree->{push});
    delete($tree->{push});

    while (my ($k, $v) = each(%$tree)) {
	# Boolean options are printed only if they are true
	if ($v eq '1') {
	    print $fh "$k\n";
	} elsif ($v ne '0') {
	    print $fh "$k $v\n";
	}
    }

    return $fh->close();
}

sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement("/software/components/openvpn")->getTree();
    my $changed = 0;

    $changed ||= $self->setup_clients($t->{clients}) if exists($t->{clients});
    $changed ||= $self->setup_servers($t->{server}) if exists($t->{server});

    $self->verbose("Restarting OpenVPN daemon");

    if ($changed) {
	CAF::Process->new([qw(/etc/init.d/openvpn restart)],
			  log => $self)->run();
	return !$?;
    }
    return 1;
}
