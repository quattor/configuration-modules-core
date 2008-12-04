# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# hostsfile component
#
# configure local /etc/hosts settings and resources as per CDB
#

package NCM::Component::hostsfile;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use LC::Process;
use LC::File;
use Socket; # for IP gethostbyname() of cluster members - should we use CDB instead? XXX
use Data::Dumper;

#
# OO stuff
#
$EC->error_handler(\&my_handler);
sub my_handler {
	my($ec, $e) = @_;
	$e->has_been_reported(1);
}

##########################################################################
sub Configure {
##########################################################################
	my ($self,$config)=@_;

	my $valPath = '/software/components/hostsfile';

	unless ($config->elementExists($valPath)) {
		$self->error("cannot get $valPath");
		return;
	}

	my $re; # root element (of subtrees in our config)
	my $val; # value (temporary) retrieved for a given config element
	my @localhostsent;	# Old host entries
	my $reload=0; # shall we reload the config file?
	my $errorflag=0;    # fatal error
	my $domainname;

	my $domainpath="/system/network/domainname";
	if ($config->elementExists($domainpath)) {
	    $re=$config->getElement("$domainpath");
	    $domainname=$re->getValue();
	}

# Structure is
#   hostsfile
#	file
#	entries
#	    <hostname>
#		ipaddr
#	    	aliases = list
#
	my $hostsfile="/etc/hosts";
	my $cdbpath=$valPath."/file";
	my @fields;
	my %ncmhosts;
	my %newncmhosts;
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    $hostsfile=$re->getValue();
	}

	# Read all non-NCM entries
	if (open(HOSTS,"$hostsfile")) {
	    while (<HOSTS>) {
		chomp;
		next if (/^# NCM/);	# Prolog
		if (/# NCM/) {		# Hosts
		    @fields=split /\s+/,$_;
		    my $host=$fields[1];
		    $ncmhosts{$host}=$_;
		    next;
		}
		push @localhostsent,$_;
	    }
	    close HOSTS;
	}

	# Now build the lines for the hosts file
	$cdbpath=$valPath."/entries";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    while ($re->hasNextElement()) {
		my $he=$re->getNextElement();
		my $heval=$he->getValue();
		my $hename=$he->getName();	# Hostname
		my $helist=$config->getElement("$cdbpath/$hename");
		my %hesettings;
		my $line="";
		my $ipaddr;
		my $comment;
		my $aliases;
		while ($helist->hasNextElement()) {
		    my $hl=$helist->getNextElement();
		    my $hlval=$hl->getValue();
		    my $hlname=$hl->getName();
		    if ($hlname eq "ipaddr") {
			$ipaddr=$hlval;
		    } elsif ($hlname eq "aliases") {
			$aliases=$hlval;
		    } elsif ($hlname eq "comment") {
			$comment=$hlval;
		    } else {
			$self->error("List entry $hlname for $hename not understood");
			$errorflag=1;
		    }
		}
		unless (defined($ipaddr)) {
		    $self->error("IP address not defined for $hename");
		    $errorflag=1;
		}
		$line="$ipaddr\t$hename";
		if (!defined($aliases)) {
		    $aliases="";
		    if ($hename =~ m/([^.]+)[.].*/) {
			$aliases=$1;
		    } elsif (defined($domainname)) {
			$aliases=$hename.".".$domainname;
		    }
		}
		$line.=" $aliases";
		$line=sprintf("%-40s # NCM",$line);
		if (defined($comment)) {
		    $line.=" $comment";
		}
		my $oldline=$ncmhosts{$hename};
		if (!defined($oldline)) {
		    $self->info("Adding entry for $hename");
		    $reload=1;
		} elsif ($line ne $oldline) {
		    $self->info("Changed entry for $hename");
		    $reload=1;
		}
		delete $ncmhosts{$hename};
		if (defined($newncmhosts{$hename})) {
		    $self->error("Duplicate entry for $hename");
		    $errorflag=1;
		}
		$newncmhosts{$hename}=$line;
	    }
	}

	my @oldhosts=keys %ncmhosts;
	if (@oldhosts>0) {
	    $reload=1;
	    my $ohosts=join(' ',@oldhosts);
	    $self->info("Deleting entries for $ohosts");
	    $reload=1;
	}
	if ($reload && !$errorflag) {
	    my $contents="";
	    my $prolog="# NCM Generated automatically by component hostsfile at ".localtime()."\n";
	    $contents.=$prolog;
	    for my $l (@localhostsent) {
		$contents.="$l\n";
	    }
	    for my $h (sort keys %newncmhosts) {
		my $le=$newncmhosts{$h};
		$contents.="$le\n";
	    }
	    if (open(HOSTS,">$hostsfile")) {
		print HOSTS $contents;
		close HOSTS;
	    } else {
		$self->error("Cannot update $hostsfile : $!");
	    }
	    chmod 0644,$hostsfile;
	}
	return;
}

##########################################################################
sub Unconfigure {
##########################################################################
}


1; #required for Perl modules
