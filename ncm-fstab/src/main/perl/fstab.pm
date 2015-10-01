# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::fstab;

use strict;
use warnings;
use NCM::Component;
use LC::Check;
use LC::Exception qw (throw_error);
use CAF::Process;
use CAF::FileEditor;
use CAF::FileReader;
use CAF::FileWriter;
use NCM::Filesystem;
use NCM::Partition qw (partition_compare);
use Fcntl qw(:seek);

use Cwd qw(abs_path);
 
use constant UMOUNT => "/bin/umount";
use constant REMOUNT => qw(/bin/mount -o remount);
use constant MOUNT => qw(/bin/mount);

our @ISA = qw(NCM::Component);
our $EC = LC::Exception::Context->new()->will_store_all();

# Updates entries in /etc/fstab. Returns a hash with the mountpoints
# that exist in the profile.
sub update_entries
{
    my ($self, $config, $fstab, $protected) = @_;

    my %mounts;

    $self->verbose ("Updating " . NCM::Filesystem::FSTAB . " with new or modified contents");

    my $el = $config->getElement ("/system/filesystems");

    while ($el->hasNextElement()) {
        my $el2 = $el->getNextElement();
        my $fs = NCM::Filesystem->new ($el2->getPath()->toString(), $config);
        $self->debug (3, "Checking fstab entry at $fs->{mountpoint}");
        $fs->update_fstab($fstab, $protected);
        next if $fs->{type} eq 'swap';
        $mounts{$fs->{mountpoint}} = $fs;
    }

    return %mounts;
}

# Returns a hash with the mountpoints of the filesystems defined on
# the profile as its keys, and the filesystem objects as its values.
sub fshash
{
    my ($self, $fsl) = @_;
    my %fsh;

    $fsh{$_->{mountpoint}} = $_ foreach @$fsl;
    return %fsh;
}

# build the protected hashes from the template
sub protected_hash 
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix());
    my $mounts_depr = $tree->{protected_mounts}; 
    
    my $protected = {};

    foreach my $type ('keep', 'static'){
        my $protect = $tree->{$type};
        my $mountlist = ($type eq 'keep' && $mounts_depr) ? $mounts_depr : $protect->{mounts};
        my %mounts = map { $_ => 1 } @$mountlist;
        my %fs_types = map { $_ => 1 } @{$protect->{fs_types}};

        $protected->{$type} = {
            mounts => \%mounts,
            fs_types => \%fs_types,
        };
    }
    return $protected;
}


# Returns a hash with all the mount points that are accepted in the
# system as keys. fstab has to be a FileFamily instance
sub valid_mounts
{
    my ($self, $protected, $fstab, %mounts) = @_;

    # update mounts with protected mounts
    @mounts{ keys %{$protected->{mounts}} } = values %{$protected->{mounts}};
    my $txt = "$fstab";
    my $re = qr!^\s*([^#\s]\S+)\s+(\S+?)\/?\s+(\S+)\s!m;
    while ($txt =~m/$re/mg) {
        # add mountpoint for protected fs_type
        $mounts{$2} = 1 if ($protected->{fs_types}->{$3});
    }
    
    return %mounts;
}

# Returns the mountpoint associated to an fstab entry.
sub mount_from_entry
{
    my ($self, $entry) = @_;

    $self->debug (5, "Parsing fstab entry: $entry");
    if ($entry =~ m{^\s*\S+\s+(\S+)\s+\S+\s+\S+\s+\S+\s+\S+$}) {
	   return $1;
    }
}

# Deletes stuff that is not present in the %mounts argument from
# fstab.
sub delete_outdated
{
    my ($self, $fstab, $mountsr, $remove) = @_;

    my @rm;
    my %mounts = %$mountsr;
    seek($fstab, 0, SEEK_SET);

    while (my $f = <$fstab>) {
    	my $mount = $self->mount_from_entry($f) or next;
    	if (!exists ($mounts{$mount}) && !exists($mounts{abs_path($mount)})) {
    	    CAF::Process->new ([UMOUNT, $mount],
    			       log => $self)->run();
    	    push (@rm, $f);
            $self->verbose ("Scheduling for removal of fstab: $mount");
            $self->verbose ("Scheduling for removal filesystem $mount") if $remove;
    	}
    }

    foreach my $outdated (@rm) {
    	$self->info("Removing line $outdated");
    	$fstab->replace_lines (qr{$outdated}, qr{^$}, "");

        if ($remove) {
            $self->info("Removing filesystem for line  $outdated");
            my $fsrm = NCM::Filesystem->new_from_fstab ($outdated);
            $fsrm->remove_if_needed==0 or return 0;
        }
    }
    return 1;
}

# Remounts all the entries in the fstab, to ensure changes are
# correctly applied.
sub remount_everything
{
    my ($self, $fstab) = @_;

    my $rt = 0;

    seek($fstab, 0, SEEK_SET);

    while (my $f = <$fstab>) {
    	my $mount = $self->mount_from_entry($f);
    	$mount && $mount ne 'swap' or next;
    	LC::Check::directory ($mount);
    	if ($f !~ m{^\s*\S+\s+\S+\s+\S+\s+\S*\W+noauto\W+}) {
    	    CAF::Process->new ([REMOUNT, $mount], log => $self)->output();
    	    CAF::Process->new ([MOUNT, $mount], log => $self)->run() if $?;
    	    if ($?) {
        		$self->error ("Failed to mount $mount");
        		$rt = -1;
    	    }
    	}
    }
    return $rt;
}

sub create_blockdevices
{
    my ($self, $config, $fs) = @_;
    # Partitions must be created first, see bug #26137
    my $el = $config->getElement ("/system/blockdevices/partitions");
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
    foreach (@$fs) {
        if ($_->create_if_needed != 0) {
            throw_error ("Failed to create filesystem:  $_->{mountpoint}");
            return 0;
        }
    }
    return 1;
};


sub Configure
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix());
    my $create = $tree->{manage_blockdevs};

    my $fstab = CAF::FileEditor->new (NCM::Filesystem::FSTAB, log => $self,
				      backup => '.old');

    if ($create && $NoAction) {
        $self->warn ("--noaction not supported. Leaving."); # Should be checked if is still true
        return 1;
    }

    my $fs = [];
    my $el = $config->getElement ("/system/filesystems");
    while ($el->hasNextElement) {
        my $el2 = $el->getNextElement;
        push (@$fs, NCM::Filesystem->new ($el2->getPath->toString, $config));
    }

    my $protected = $self->protected_hash($config);
    my %mounts = $self->fshash ($fs);
    %mounts = $self->valid_mounts($protected->{keep}, $fstab, %mounts);

    $self->delete_outdated ($fstab, \%mounts, $create) or return 0;
    if ($create) {
        $self->create_blockdevices ($config, $fs) or return 0;
    }

    $self->update_entries ($config, $fstab, $protected->{static});

    if ($fstab->close()) {
    	$fstab = CAF::FileReader->new (NCM::Filesystem::FSTAB, log => $self);
    	my $err = $self->remount_everything ($fstab);
    	if ($err) {
    	    $self->error ("Failed to mount some filesystems");
    	    return 0;
    	}
    }

    return 1;
}

1;
