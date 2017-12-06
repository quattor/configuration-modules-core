#${PMpre} NCM::Component::filesystems${PMpost}

use CAF::Process;
use CAF::FileEditor;
use CAF::FileReader;
use NCM::Filesystem;
use NCM::Partition 16.12.1 qw (partition_sort);
use CAF::Object;
use Fcntl qw(:seek);
use Readonly;
use Cwd qw(abs_path);

Readonly my $UMOUNT => "/bin/umount";
Readonly my $FSTAB_CMP_PATH => '/software/components/fstab';
Readonly my $FS_TREE => '/system/filesystems';
Readonly my $PARTITIONS_TREE => '/system/blockdevices/partitions';
use parent qw(NCM::Component::fstab);

our $EC = LC::Exception::Context->new()->will_store_all();
our $NoActionSupported = 0; # First needs check/fixing in ncm-lib-blockdevices issue #74

#  Removes filesystem and deletes stuff that is not present in the %mounts 
#  argument from fstab.
sub delete_outdated
{
    my ($self, $fstab, $mountsr, $config, $remove) = @_;

    my @rm;
    my %mounts = %$mountsr;
    $fstab->seek_begin();

    while (my $f = <$fstab>) {
        my $mount = $self->mount_from_entry($f) or next;
        if (!exists ($mounts{$mount}) && !exists($mounts{abs_path($mount)})) {
            CAF::Process->new ([$UMOUNT, $mount],
                log => $self)->run();
            push (@rm, $f);
            $self->verbose ("Scheduling for removal from fstab: $mount");
            $self->verbose ("Scheduling for removal filesystem $mount") if $remove;
        }
    }

    foreach my $outdated (@rm) {
        if ($remove) {
            my $fsrm = NCM::Filesystem->new_from_fstab ($outdated, $config, log => $self);
            $self->info("Removing filesystem for $fsrm->{mountpoint}");
            if ($fsrm->remove_if_needed) {
                $self->error("error $fsrm->{mountpoint}");
                return;
            } else {
                $self->info("removed $fsrm->{mountpoint}")
            }
        }
        $self->info("Removing line $outdated");
        $fstab->replace_lines (qr{$outdated}, qr{^$}, "");
    }
    return 1;
}


sub create_blockdevices
{
    my ($self, $config, $fs) = @_;
    # Partitions must be created first
    my $parttree = $config->getElement ($PARTITIONS_TREE);
    my @part = ();
    $self->info ("Checking whether partitions need to be created");

    while ($parttree && $parttree->hasNextElement) {
        my $partel = $parttree->getNextElement;
        push (@part, NCM::Partition->new ($partel->getPath->toString, $config, log => $self));
    }
    foreach my $partition (partition_sort(@part)) {
        if ($partition->create != 0) {
            $self->error("Couldn't create partition: " . $partition->devpath);
            return 0;
        }
    }
    foreach my $filesystem (@$fs) {
        if ($filesystem->create_if_needed != 0) {
            $self->error("Failed to create filesystem:  $filesystem->{mountpoint}");
            return 0;
        }
    }
    return 1;
};


sub Configure
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix());
    my $fstab_tree = $config->getTree($FSTAB_CMP_PATH);

    my $manage = $tree->{manage_blockdevs};
    $self->info('Managing blockdevices: ', ($manage) ? 'yes' : 'no');
    my $fstab = CAF::FileEditor->new (NCM::Filesystem::FSTAB, log => $self,
				      backup => '.old');

    my $fs = [];
    my $fstree = $config->getElement ($FS_TREE);
    while ($fstree->hasNextElement) {
        my $fsel = $fstree->getNextElement;
        push (@$fs, NCM::Filesystem->new ($fsel->getPath->toString, $config, log => $self));
    }

    my $protected = $self->protected_hash($fstab_tree);
    my %mounts = map {$_->{mountpoint} => $_} @$fs;
    %mounts = $self->valid_mounts($protected->{keep}, $fstab, %mounts);

    $self->delete_outdated ($fstab, \%mounts, $config, $manage) or return 0;
    if($manage) {
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
