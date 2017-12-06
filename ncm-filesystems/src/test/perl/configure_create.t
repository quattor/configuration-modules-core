# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 test for ncm-filesystems Configure method

Tests for adding, changing and deleting entries in /etc/fstab and mounting

=cut

use strict;

BEGIN {
    unshift(@INC, '../ncm-fstab/target/lib/perl');
}

use warnings;
use Readonly;
Readonly my $FSTAB => 'target/test/etc/fstab';

BEGIN{
    # This only works because the constant of NCM::Filesystem is used in a ncm-fstab sub
    use NCM::Filesystem;
    undef &{NCM::Filesystem::FSTAB};
    *{NCM::Filesystem::FSTAB} =  sub () {$FSTAB} ;
}
use CAF::FileEditor;
use CAF::Object;
use File::Basename;
use File::Path qw(mkpath);
use LC::Check;
use NCM::Component::filesystems;
use Test::Deep;
use Test::More;
use Test::MockModule;
use Test::Quattor qw(configure_create);
use Test::Quattor::RegexpTest;
use data;

is(NCM::Filesystem::FSTAB, $FSTAB);
mkpath dirname $FSTAB;

$CAF::Object::NoAction = 1;
$LC::Check::NoAction = 1;
set_caf_file_close_diff(1);
my $cfg = get_config_for_profile('configure_create');
my $cmp = NCM::Component::filesystems->new('filesystems');
$NCM::Blockdevices::this_app = $cmp;
use NCM::Blockdevices;

my $mock = Test::MockModule->new('NCM::Filesystem');
my $mockp = Test::MockModule->new('NCM::Partition');

my $created_fs = [];
my $created_part = [];
my $removed_fs = [];
$mock->mock('create_if_needed', sub {
    my ($self) = @_;
    diag "create_if_needed ran on $self->{mountpoint}";
    push (@$created_fs, $self->{mountpoint});
    return 0;
    }
);

$mock->mock('remove_if_needed', sub {
    my ($self) = @_;
    diag "remove_if_needed ran on $self->{mountpoint}";
    push (@$removed_fs, $self->{mountpoint});

    return 0;
    }
);

$mockp->mock('create', sub {
    my ($self) = @_;
    diag "create is ran on $self->{devname}";
    push (@$created_part, $self->{devname});
    return 0;
    }
);

set_file_contents($FSTAB, $data::FSTAB_CONTENT);

# Test all values
$cmp->Configure($cfg);
my $fh = get_file($FSTAB);

cmp_deeply($created_part, \@data::PARTS_CREATE, "Partition create called");
cmp_deeply($created_fs, \@data::FS_CREATE, "fs create_if_needed called");
cmp_deeply($removed_fs, \@data::FS_REMOVE, "fs remove_if_needed called");

my $rt = Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/fstab_regextest',
    text => "$fh",
    );  
$rt->test();

my $cmd = get_command("/bin/mount -o remount /");
ok(defined($cmd), "remount / was invoked");
$cmd=get_command("/bin/mount -o remount /boot");
ok(!defined($cmd), "remount /boot was not invoked");


done_testing();

