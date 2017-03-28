# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the update_pam_file method

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor qw(pamadditions);
use NCM::Component::authconfig;
use Readonly;
use Cwd;
use CAF::Object;

$CAF::Object::NoAction = 1;

Readonly my $PAM_FILE => getcwd()."/target/tmp/file.pam";
Readonly my $NEW_ENTRY => 'required pam_access.so accessfile=/tmp/acc.conf';

Readonly my $PAM_FILE_DATA => <<EOF;
#%PAM-1.0
auth       required     pam_sepermit.so
auth       include      password-auth
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
EOF

Readonly my $PAM_FILE_DATA_NOHEADER => <<EOF;
auth       required     pam_sepermit.so
auth       include      password-auth
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
EOF


my $cmp = NCM::Component::authconfig->new("authconfig");

my $fh;

=pod

=head2 add new end of file

Add new entry, by default at end of file

=cut

set_file_contents($PAM_FILE, $PAM_FILE_DATA);
$cmp->update_pam_file({
    conffile => $PAM_FILE,
    section => 'account',
    lines => [{
        order => 'last',
        entry => $NEW_ENTRY,
    }]
});

$fh = get_file($PAM_FILE);
# should have been added to last line
like("$fh", qr{account $NEW_ENTRY$}, "Added new entry to end of file");
$fh->close();

=pod

=head2 add new begin of file

Add new entry, at the begin of file (after header).

=cut


set_file_contents($PAM_FILE, $PAM_FILE_DATA);
$cmp->update_pam_file({
    conffile => $PAM_FILE,
    section => 'account',
    lines => [{
        entry => $NEW_ENTRY,
        order => 'first',
    }]
});

$fh = get_file($PAM_FILE);

like("$fh", qr{\A#%PAM-1.0}m, "PAM header at begin of file");

my $pat = '\A#%PAM-1.0\s+^account '.$NEW_ENTRY;
like("$fh", qr{$pat}m, "Added new entry beginning of file, after PAM header");
$fh->close();


=pod

=head2 add new begin of file, no header

Add new entry, at the begin of file (no header).

=cut


set_file_contents($PAM_FILE, $PAM_FILE_DATA_NOHEADER);
$cmp->update_pam_file({
    conffile => $PAM_FILE,
    section => 'account',
    lines => [{
        entry => $NEW_ENTRY,
        order => 'first',
    }]
});

$fh = get_file($PAM_FILE);

unlike("$fh", qr{^#%PAM-1.0}m, "No PAM header anywhere");

like("$fh", qr{^account $NEW_ENTRY}, "Added new entry beginning of file, no PAM header");
$fh->close();

=pod

=test2 Error on missing module

When no C<.so> module is found, throw an error, and skip that entry.

=cut

ok(! exists($cmp->{ERROR}), "No errors so far");
set_file_contents($PAM_FILE, $PAM_FILE_DATA);
$cmp->update_pam_file({
    conffile => $PAM_FILE,
    section => 'account',
    lines => [{
        entry => "NO MODULE",
        order => 'first',
    }]
});
$fh = get_file($PAM_FILE);
is($cmp->{ERROR}, 1, "1 error");

unlike("$fh", qr{NO MODULE}, "entry skipped");

=pod

=test2 Sample from template

Test the sample from the config instance

=cut

# succesfully compiled template verifies the schema
my $cfg = get_config_for_profile("pamadditions");
$cmp->build_pam_systemauth($cfg->getElement('/software/components/authconfig/pamadditions')->getTree());
$fh = get_file("/etc/pam.d/sshd");
is("$fh",
   "account required      pam_access.so accessfile=/etc/security/access_sshd.conf\n",
   "added line to (empty) pam sshd config");


done_testing();
