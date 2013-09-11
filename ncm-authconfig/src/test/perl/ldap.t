# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the ldap.tt template.  We only ensure it renders something
and there are no errors.

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::authconfig;

my $cmp = NCM::Component::authconfig->new("authconfig");

my $t = {
	desc => {
        autofs => { map_name => 'am' },
		default => { bind_dn => 'db' },
        group => { name => 'gn' },
		krb5 => { keytab => 'kt' },
		netgroup => { member => 'nm' },
        sasl => { mech => 'sam' },
        sudo => { hostnames => 'sh' },
        sudorule => { hostnames => 'sh' },
        tls => {
            key => 'tk',
            cacert => 'ca',
            cipher_suite => [qw(c1 c2)]
        },
        user => { shell => 'us' },
		uri => [qw(u1 u2)],
	       }
       };

my $str;

ok($cmp->template()->process('authconfig/domains/ldap.tt', $t, \$str),
   "Template successfully rendered");

is($cmp->template()->error(), "", "No errors in rendering the template");

like($str, qr{^ldap_autofs_map_name\s*=\s*am$}m, "autofs entries rendered correctly");
like($str, qr{^ldap_default_bind_dn\s*=\s*db$}m, "defaults entries rendered correctly");
like($str, qr{^ldap_group_name\s*=\s*gn$}m, "group entries rendered correctly");
like($str, qr{^ldap_krb5_keytab\s*=\s*kt$}m, "krb5 entries rendered correctly");
like($str, qr{^ldap_netgroup_member\s*=\s*nm$}m, "netgroup entries rendered correctly");
like($str, qr{^ldap_sasl_mech\s*=\s*sam$}m, "sasl entries rendered correctly");
like($str, qr{^ldap_sudo_hostnames\s*=\s*sh$}m, "sudo entries rendered correctly");
like($str, qr{^ldap_sudorule_hostnames\s*=\s*sh$}m, "sudo entries rendered correctly");
like($str, qr{^ldap_tls_cacert\s*=\s*ca$}m, "Sample field rendered correctly");
like($str, qr{^ldap_tls_cipher_suite\s*=\s*c1:c2$}m, "Cipher suite rendered correctly");
like($str, qr{^ldap_tls_key\s*=\s*tk$}m, "tls entries rendered correctly");
like($str, qr{^ldap_user_shell\s*=\s*us$}m, "user entries rendered correctly");
like($str, qr{^ldap_uri\s*=\s*u1,\s*u2$}m, "URIs rendered correctly");

done_testing();
