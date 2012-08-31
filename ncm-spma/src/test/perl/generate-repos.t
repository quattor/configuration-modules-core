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

no warnings 'redefine';
*CAF::FileWriter::cancel = sub {
    my $self = shift;
    *$self->{CANCELED}++;
    *$self->{save} = 0;
};
use warnings 'redefine';

my $cmp = NCM::Component::spma->new("spma");

Readonly my $REPOS_DIR => "/etc/yum.repos.d";
Readonly my $REPOS_TEMPLATE => "spma/repository.tt";
Readonly my $PROXY_HOST => "aproxy";

=pod

=head1 TESTS

=head2 Creation of a valid repository file

The information from the profile should be reflected in the
configuration files.

=cut

is($cmp->generate_repos($REPOS_DIR, $repos,
			$REPOS_TEMPLATE), 1);


my $fh = get_file("/etc/yum.repos.d/a_repo.repo");
ok(defined($fh), "Correct file opened");
my $url = $repos->[0]->{protocols}->[0]->{url};
my $name = $repos->[0]->{name};
like("$fh", qr{^baseurl=$url$}m,
     "Repository got the correct URL");
like("$fh", qr{^\[$name\]$}m, "Repository got the correct name");

=pod

=head2 Error handling

Failures in rendering a template are reported, and nothing is written
to disk.

=cut

is($cmp->generate_repos($REPOS_DIR, $repos, "an invalid template name"), 0,
   "Errors on template rendering are detected");
is($cmp->{ERROR}, 1, "Errors on template rendering are reported");
$fh = get_file("/etc/yum.repos.d/$name.repo");
ok(*$fh->{CANCELED}, "File with error is cancelled");

=pod

=head2 Proxy-related settings

When passing proxy-related arguments, we need to test a few things:

=over 4

=item * Forward proxies don't affect how the repository is rendered

=cut

$name = "forward_proxy";
$repos->[0]->{name} = $name;

is($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE, $PROXY_HOST,
			'forward'), 1,
   "Proxy settings succeed");

$fh = get_file("$REPOS_DIR/$name.repo");

like("$fh", qr{^baseurl=$url$}m,
     "Forward proxy settings don't affect to the URL");

=pod

=item * Reverse proxies have their URLs modified

=cut

$name = "reverse_proxy";
$repos->[0]->{name} = $name;
is($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE,
			$PROXY_HOST, 'reverse'), 1,
   "Files with reverse proxies are properly rendered");

$fh = get_file("$REPOS_DIR/$name.repo");
like("$fh", qr{^baseurl=http://$PROXY_HOST$}m,
     "Reverse proxies modify the URLs in the config files");

done_testing();

=pod

=back

=cut
