# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the generate_repos method.  They will ensure that entries in
/etc/yum.repos.d are properly handled.

=cut

use strict;
use warnings;
use Test::Quattor;
use Test::More;
use NCM::Component::spma;
use Readonly;
use CAF::Object;

$CAF::Object::NoAction = 1;


my $repos = [ { name => "a_repo",
		owner => 'localuser@localdomain',
		protocols => [ { name => "http",
				 url => "http://localhost.localdomain" }
			     ]
	      }
	    ];


my $cmp = NCM::Component::spma->new("spma");

Readonly my $REPOS_DIR => "/etc/yum.repos.d";
Readonly my $REPOS_TEMPLATE => "spma/repository.tt";


is($cmp->generate_repos($REPOS_DIR, $repos,
			$REPOS_TEMPLATE), 1);

my $fh = get_file("/etc/yum.repos.d/a_repo.repo");
ok(defined($fh), "Correct file opened");
my $url = $repos->[0]->{protocols}->[0]->{url};
my $name = $repos->[0]->{name};
like("$fh", qr{^baseurl=$url$}m,
     "Repository got the correct URL");
like("$fh", qr{^\[$name\]$}m, "Repository got the correct name");

done_testing();
