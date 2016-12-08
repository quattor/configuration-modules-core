# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the configuration of the gpfs rpms and files


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(base);
use NCM::Component::gpfs;
use CAF::Object;
use Readonly;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('base');
my $cmp = NCM::Component::gpfs->new('gpfs');

my $rpm_output = <<'EOF';
gpfs.gplbin-3.10.0-327.36.2.el7.ug.x86_64 gpfs.gplbin-3.10.0-327.36.2.el7.ug.x86_64-4.2.1-1
gpfs.base gpfs.base-4.2.1-1
gpfs.docs gpfs.docs-4.2.1-1
gpfs.ext gpfs.ext-4.2.1-1
gpfs.gpl gpfs.gpl-4.2.1-1
gpfs.gskit gpfs.gskit-8.0.50-57
gpfs.smb gpfs.smb-4.3.0_gpfs_9-3.el7
gpfs.msg.en_US gpfs.msg.en_US-4.2.1-1
gpfs.hdfs-protocol gpfs.hdfs-protocol-2.7.0-3
EOF

my $rpm_unknown = $rpm_output . "gpfs.bla gpfs.bla-4.3.0_gpfs_9-3.el7";

my $rpm_cmd = '/bin/rpm -v -q -a gpfs.* --qf %{NAME} %{NAME}-%{VERSION}-%{RELEASE}\\n';

# unknown rpms
set_desired_output($rpm_cmd, $rpm_unknown);

ok(!$cmp->remove_existing_rpms($cfg), 'not removed existing gpfs rpms');

ok(get_command($rpm_cmd), 'rpm listing fetched');

# ok rpms
set_desired_output($rpm_cmd, $rpm_output);

my ($ok, $removed) = $cmp->remove_existing_rpms($cfg);
ok($ok, 'removed existing gpfs rpms');
my $pkgs = [ 'gpfs.gplbin-3.10.0-327.36.2.el7.ug.x86_64-4.2.1-1', 'gpfs.base-4.2.1-1', 'gpfs.docs-4.2.1-1',
    'gpfs.ext-4.2.1-1', 'gpfs.gpl-4.2.1-1', 'gpfs.gskit-8.0.50-57', 'gpfs.smb-4.3.0_gpfs_9-3.el7', 
    'gpfs.msg.en_US-4.2.1-1', 'gpfs.hdfs-protocol-2.7.0-3'];
cmp_deeply($removed, $pkgs);

my $rm_cmd = '/usr/bin/yum -y remove gpfs.gplbin-3.10.0-327.36.2.el7.ug.x86_64-4.2.1-1 gpfs.base-4.2.1-1 gpfs.docs-4.2.1-1 gpfs.ext-4.2.1-1 gpfs.gpl-4.2.1-1 gpfs.gskit-8.0.50-57 gpfs.smb-4.3.0_gpfs_9-3.el7 gpfs.msg.en_US-4.2.1-1 gpfs.hdfs-protocol-2.7.0-3';
ok(get_command($rm_cmd), 'rpm removal run');

ok($cmp->reinstall_update_rpms($cfg, $removed), 'reinstall rpms ok');

my $inst_cmd = '/usr/bin/yum -y install gpfs.gplbin-3.10.0-327.36.2.el7.ug.x86_64-4.2.1-1 gpfs.base-4.2.1-1 gpfs.docs-4.2.1-1 gpfs.ext-4.2.1-1 gpfs.gpl-4.2.1-1 gpfs.gskit-8.0.50-57 gpfs.smb-4.3.0_gpfs_9-3.el7 gpfs.msg.en_US-4.2.1-1 gpfs.hdfs-protocol-2.7.0-3';

ok(get_command($inst_cmd), 'rpm reinstall run');

done_testing();
