# ${license-info}
# ${developer-info}
# ${author-info}

# File: filesystems.pm
# Implementation of ncm-filesystems
# Author: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# Version: 0.10.4 : 26/03/09 11:17
#  ** Generated file : do not edit **
#
# Note: all methods in this component are called in a
# $self->$method ($config) way, unless explicitly stated.

package NCM::Component::filesystems;

use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Property;
use NCM::Check;
use FileHandle;
use LC::Exception qw (throw_error);
use LC::Process qw (execute output);
use NCM::BlockdevFactory qw (build);
use NCM::Filesystem;
use NCM::Partition qw (partition_compare);
use constant PROTECTED_PATH => "/software/components/filesystems/protected_mounts";

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

# Returns a hash with the protected mountpoints as its keys. This
# small overhead may simplify the code and make it faster.
sub protected_hash
{
	my $config = shift;
	my %ph;

	my $pl = $config->getElement (PROTECTED_PATH)->getTree;

	$ph{$_} = 0 foreach @$pl;
	return %ph;
}

# Returns a hash with the mountpoints of the filesystems defined on
# the profile as its keys, and the filesystem objects as its values.
sub fshash
{
	my $fsl = shift;
	my %fsh;

	$fsh{$_->{mountpoint}} = $_ foreach @$fsl;
	return %fsh;
}

# Frees space on the system. It removes filesystems with !preserve &&
# format and filesystems no longer present in the profile. Returns 0
# on success, -1 on error.
sub free_space
{
	my ($self, $cfg, @fs) = @_;

	my %ph = protected_hash ($cfg);
	my %fsh = fshash (\@fs);

	$self->info ("Checking for filesystems that should be removed");
	foreach (@fs) {
		$self->debug (5, "Filesystem $_->{mountpoint} is",
			     exists $ph{$_->{mountpoint}}? "":" not",
			     " in the protected hash list");
		if ((!exists $ph{$_->{mountpoint}}) && ($_->remove_if_needed!=0)) {
			throw_error ("Couldn't remove filesystem $_->{mountpoint}");
			return -1;
		}
	}

	my $fl = output ("grep", "^[[:space:]]*#", "/etc/fstab", "-v");

	$self->info ("Checking filesystems not defined in the profile");
	my @fstab = split ("\n+", $fl);
	foreach my $l (@fstab) {
		$self->debug (5,"Fstab line: $l");
		$l =~ m{^\S+\s+(\S+)\s};
		my $keepfs=(exists $fsh{$1} || exists $ph{$1});
		$self->debug (5, "Filesystem $1 should ", 
			     $keepfs? "not " : "", "be removed:",
			     exists $fsh{$1}?"": " not",
			     " in the profile",
			     exists $ph{$1}?" and is ":" and is not ",
			     "protected.");
		unless ($keepfs) {
			$self->debug (5, "Actually removing $1");
			my $f = NCM::Filesystem->new_from_fstab ($l);
			$self->debug (5, "Filesystem $f->{mountpoint} left the profile: removing it");
			$f->remove_if_needed==0 or return -1;
		}
	}
	return 0;
}

sub Configure
{
	my ($self, $config) = @_;

	my @fs = ();

	if ($NoAction) {
		$self->warn ("--noaction not supported. Leaving.");
		return 1;
	}

	my $el = $config->getElement ("/system/filesystems");
	while ($el->hasNextElement) {
		my $el2 = $el->getNextElement;
		push (@fs, NCM::Filesystem->new ($el2->getPath->toString, $config));
	}
	$self->free_space ($config, @fs)==0 or return 0;
	# Partitions must be created first, see bug #26137
	$el = $config->getElement ("/system/blockdevices/partitions");
	my @part = ();
	$self->info ("Checking whether partitions need to be created");
	
	while ($el && $el->hasNextElement) {
		my $el2 = $el->getNextElement;
		push (@part, NCM::Partition->new ($el2->getPath->toString, $config));
	}
	foreach (sort partition_compare @part) {
		if ($_->create != 0) {
			throw_error ("Couldn't create partition: " . $_->devpath);
			return 0;
		}
	}
	foreach (@fs) {
		if ($_->create_if_needed != 0) {
			throw_error ("Failed to create filesystem:  $_->{mountpoint}");
			return 0;
		}
		if ($_->format_if_needed != 0) {
			$self->warn ("Failed to format filesystem: ".
				      $_->{mountpoint});
		}
	}
	return 1;
}
