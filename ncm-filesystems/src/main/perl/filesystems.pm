# ${license-info}
# ${developer-info}
# ${author-info}

# File: filesystems.pm
# Implementation of ncm-filesystems
# Author: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# Version: 1.0.1 : 03/03/11 19:03
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
use Cwd qw(abs_path);
use NCM::BlockdevFactory qw (build);
use NCM::Filesystem;
use NCM::Partition qw (partition_compare);
use constant PROTECTED_PATH => "/software/components/fstab/protected_mounts";

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

# Returns a hash with the canonical paths to the protected mountpoints
# as its keys. I This small overhead may simplify the code later.
sub protected_hash
{
	my $config = shift;
	my %ph;

	my $pl = $config->getElement (PROTECTED_PATH)->getTree;

	foreach my $i (@$pl) {
		$ph{$i} = 0;
		my $path = abs_path("$i/");
		$ph{$path} = 0 if $path;
	}
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

# Frees space on the system. It removes filesystems that are not
# present in the profile anymore, and are *not* present in the
# protected hash either. Returns 0 on success, -1 on error.
sub free_space
{
	my ($self, $cfg, $protected, @fs) = @_;

	my %ph = %$protected;
	my %fsh = fshash (\@fs);

	my $fl = output ("grep", "^[[:space:]]*#", "/etc/fstab", "-v");

	$self->info ("Checking filesystems not defined in the profile");
	my @fstab = split ("\n+", $fl);
	foreach my $l (@fstab) {
		$self->debug (5,"Fstab line: $l");
		$l =~ m{^\S+\s+(\S+)\s} or next;
		my $mount = $1;
		next if(exists $fsh{$mount} || exists $ph{$mount}
			    || exists($ph{abs_path($mount)}));
		$self->verbose("Removing filesystem $mount");
		my $f = NCM::Filesystem->new_from_fstab ($l);
		$f->remove_if_needed==0 or return -1;

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
	my %protected = protected_hash ($config);
	$self->free_space ($config, \%protected, @fs)==0 or return 0;
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

		if ($_->format_if_needed (%protected) != 0) {
			$self->warn ("Failed to format filesystem: ".
				      $_->{mountpoint});
		}
	}
	return 1;
}
