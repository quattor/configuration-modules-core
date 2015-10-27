use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Quattor;

use NCM::Component::postgresql;

my $cmp = NCM::Component::postgresql->new("postgresql");

my $engine = '/usr/pgsql-9.2/bin';

=head1 version

=cut

set_desired_output('/usr/pgsql-9.2/bin/postmaster --version', "postgres (PostgreSQL) 9.2.13\n");
is_deeply($cmp->version($engine), [9, 2, 13], "Got correct version array ref");

set_desired_output('/my/usr/pgsql-9.2/bin/postmaster --version', "postgres (PostgreSQL) 9.2.abc\n");
ok(! defined($cmp->version("/my$engine")), "version returns undef on unparsable output");


done_testing();
