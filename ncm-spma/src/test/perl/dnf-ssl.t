# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the NCM::Component::spma::dnf SSL configuration.
These tests verify that SSL settings (verify, cacert, clientkey, clientcert)
are properly written to repository configuration files by calling the
actual Configure method.

=cut

use strict;
use warnings;
use Test::Quattor qw(dnf_ssl_none dnf_ssl_verify dnf_ssl_cacert dnf_ssl_client dnf_ssl_all);
use Test::More;
use Test::MockModule;
use NCM::Component::spma::dnf;
use CAF::Object;
use CAF::FileWriter;
use Set::Scalar;
use Readonly;

$CAF::Object::NoAction = 1;

Readonly my $REPOS_DIR => "/etc/yum.repos.d";

my $cmp = NCM::Component::spma::dnf->new("spma");

# Mock external dependencies so Configure can run
my $mock = Test::MockModule->new('NCM::Component::spma::dnf');

$mock->mock('execute_command', sub {
    my ($self, $command, $why, $keeps_state, $stdin, $nolog) = @_;
    my $cmd_str = join(" ", @$command);
    if ($cmd_str =~ /rpm -qa/) {
        return (0, "ConsoleKit-0:4.1-3.el6.x86_64\nncm-spma-0:1.0-1.noarch\n", "");
    }
    if ($cmd_str =~ /rpm -q.*ncm-spma/) {
        return (0, "ncm-spma-1.0-1.el8.noarch", "");
    }
    if ($cmd_str =~ /dnf repoquery/) {
        return (0, "ConsoleKit;0;4.1;3.el6;x86_64\nncm-spma;0;1.0;1;noarch\n", "");
    }
    return (0, "", "");
});

$mock->mock('get_installed_rpms', sub {
    return Set::Scalar->new("ConsoleKit-0:4.1-3.el6.x86_64", "ncm-spma-0:1.0-1.noarch");
});

$mock->mock('set_default_modules', sub {
    return 1;
});

$mock->mock('cleanup', sub {
    return 1;
});

$mock->mock('directory', sub {
    return "/tmp/mock_dir";
});

$mock->mock('symlink', sub {
    return 1;
});

=pod

=head1 TESTS

=head2 Repository without SSL settings

When no SSL settings are defined in protocols, no SSL fields should be present.

=cut

my $cfg = get_config_for_profile("dnf_ssl_none");
$cmp->Configure($cfg);

my $fh = get_file("$REPOS_DIR/spma-test_repo.repo");
ok(defined($fh), "Repository file created");
unlike($fh, qr{^sslcacert=}m, "No sslcacert field when not configured");
unlike($fh, qr{^sslverify=}m, "No sslverify field when not configured");
unlike($fh, qr{^sslclientkey=}m, "No sslclientkey field when not configured");
unlike($fh, qr{^sslclientcert=}m, "No sslclientcert field when not configured");

=pod

=head2 Repository with SSL verification enabled

=cut

$cfg = get_config_for_profile("dnf_ssl_verify");
$cmp->Configure($cfg);

$fh = get_file("$REPOS_DIR/spma-ssl_verify_repo.repo");
ok(defined($fh), "Repository file with verify created");
like($fh, qr{^sslverify=1$}m, "sslverify=1 correctly printed");

=pod

=head2 Repository with CA certificate

=cut

$cfg = get_config_for_profile("dnf_ssl_cacert");
$cmp->Configure($cfg);

$fh = get_file("$REPOS_DIR/spma-ssl_cacert_repo.repo");
ok(defined($fh), "Repository file with cacert created");
like($fh, qr{^sslcacert=/etc/pki/CA/cert.pem$}m, "sslcacert correctly printed");

=pod

=head2 Repository with client certificate and key

=cut

$cfg = get_config_for_profile("dnf_ssl_client");
$cmp->Configure($cfg);

$fh = get_file("$REPOS_DIR/spma-ssl_client_repo.repo");
ok(defined($fh), "Repository file with client cert/key created");
like($fh, qr{^sslclientcert=/etc/pki/client/cert.pem$}m, "sslclientcert correctly printed");
like($fh, qr{^sslclientkey=/etc/pki/client/key.pem$}m, "sslclientkey correctly printed");

=pod

=head2 Repository with all SSL options

=cut

$cfg = get_config_for_profile("dnf_ssl_all");
$cmp->Configure($cfg);

$fh = get_file("$REPOS_DIR/spma-ssl_full_repo.repo");
ok(defined($fh), "Repository file with all SSL options created");
like($fh, qr{^sslverify=1$}m, "sslverify correctly printed");
like($fh, qr{^sslcacert=/etc/pki/CA/ca-bundle.crt$}m, "sslcacert correctly printed");
like($fh, qr{^sslclientcert=/etc/pki/tls/certs/client.pem$}m, "sslclientcert correctly printed");
like($fh, qr{^sslclientkey=/etc/pki/tls/private/client.key$}m, "sslclientkey correctly printed");

done_testing();
