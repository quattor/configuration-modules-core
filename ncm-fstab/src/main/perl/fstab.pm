# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::fstab;

use strict;
use warnings;
use NCM::Component;
use LC::Exception qw (throw_error);
use CAF::Process;
use CAF::FileWriter;
use CAF::FileEditor;
use NCM::Filesystem;
use Fcntl qw(:seek);
use LC::File;

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

    $self->verbose ("Updating /etc/fstab with new or modified contents");

    my $el = $config->getElement ("/system/filesystems");

    while ($el->hasNextElement()) {
        my $el2 = $el->getNextElement();
        my $fs = NCM::Filesystem->new ($el2->getPath()->toString(), $config);
        $self->debug (4, "Update fstab entry at $fs->{mountpoint}");
        $fs->update_fstab($fstab, $protected);
        next if $fs->{type} eq 'swap';
        $mounts{$fs->{mountpoint}} = $fs;
    }

    return %mounts;
}

# build the protected hash from the template
sub protected_hash 
{
    my ($self, $config) = @_;

    my $mounts_depr = $config->getElement("/software/components/fstab/protected_mounts")->getTree();
    my $protect = $config->getElement("/software/components/fstab/protected")->getTree();

    my %mounts = map { $_ => 1 } @$mounts_depr;
    foreach my $mnt (@{$protect->{mounts}}) {
        $mounts{$mnt} = 1;
    }
    my %filesystems = map { $_ => 1 } @{$protect->{filesystems}};

    my $protected = {
        mounts => \%mounts,
        filesystems => \%filesystems,
        strict => $protect->{strict},
    };
    return $protected;
}


# Returns a hash with all the mount points that are accepted in the
# system as keys.
sub valid_mounts
{
    my ($self, $protected, $fstab, %mounts) = @_;

    @mounts{ keys %{$protected->{mounts}} } = values %{$protected->{mounts}};
    my $txt = "$fstab";
    my $re = qr!^\s*([^#\s]\S+)\s+(\S+?)\/?\s+(\S+)\s!m;
    while ($txt =~m/$re/mg) {
        @mounts{$2} = 1 if ($protected->{filesystems}->{$3});
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
    my ($self, $fstab, %mounts) = @_;

    my @rm;

    seek($fstab, 0, SEEK_SET);

    while (my $f = <$fstab>) {
    	my $mount = $self->mount_from_entry($f) or next;
    	if (!exists ($mounts{$mount})) {
    	    CAF::Process->new ([UMOUNT, $mount],
    			       log => $self)->run();
    	    push (@rm, $f);
    	    $self->verbose ("Scheduling for removal: $mount");
    	}
    }

    foreach my $outdated (@rm) {
    	$self->info("Removing line $outdated");
    	$fstab->replace_lines (qr{$outdated}, qr{^$}, "");
    }
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
    	LC::File::makedir ($mount);
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

sub Configure
{
    my ($self, $config) = @_;

    my $fstab = CAF::FileEditor->new ("/etc/fstab", log => $self,
				      backup => '.old');
    my $protected = $self->protected_hash($config);
    my %mounts;
    if ($protected->{strict}) {
        %mounts = $self->update_entries ($config, $fstab, $protected);
    } else {
        %mounts = $self->update_entries ($config, $fstab);
    }
    %mounts = $self->valid_mounts($protected, $fstab, %mounts);
    $self->delete_outdated ($fstab, %mounts);
    if ($fstab->close()) {
    	$fstab = CAF::FileEditor->new ("/etc/fstab", log => $self);
    	$fstab->cancel();
    	my $err = $self->remount_everything ($fstab);
    	if ($err) {
    	    $self->error ("Failed to mount some filesystems");
    	    return 0;
    	}
    }
    return 1;
}

1;
