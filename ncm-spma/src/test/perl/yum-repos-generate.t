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
use NCM::Component::spma::yum;
use Test::MockModule;
use Readonly;
use CAF::Object;
use CAF::FileWriter;
use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();

Readonly my $REPOS_DIR => "/etc/yum.repos.d";
Readonly my $REPOS_TEMPLATE => "repository";
Readonly my $PROXY_HOST => "aproxy";
Readonly my $PROXY_PORT => 9876;
Readonly my $URL => "http://localhost.localdomain";

sub initialise_repos
{
    return [ { name => "a_repo",
               owner => 'localuser@localdomain',
               enabled => 1,
               protocols => [ { name => "http",
                                url => $URL },
                              { name => "http",
                                url => "$URL/another/path" },
                             ],
               includepkgs => [qw(foo bar)],
               excludepkgs => [qw(baz quux)],
              }
            ];
}

my $repos = initialise_repos();

my $mock = Test::MockModule->new('CAF::FileWriter');

my $cancelled = 0;
$mock->mock("cancel", sub {
    $cancelled++ if ref($_[0]) ne 'CAF::FileReader';
    return $mock->original('cancel')->(@_);
});

my $cmp = NCM::Component::spma::yum->new("spma");

=pod

=head1 TESTS

=head2 Creation of a valid repository file

The information from the profile should be reflected in the
configuration files.

=cut

ok(defined($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE)),
   "Basic repository correctly created");


my $fh = get_file("/etc/yum.repos.d/a_repo.repo");
ok(defined($fh), "Correct file opened");
my $url = $repos->[0]->{protocols}->[0]->{url};
my $name = $repos->[0]->{name};
like("$fh", qr{^baseurl=\s*$URL$}m,
     "Repository got the correct URL");
$url = $repos->[0]->{protocols}->[1]->{url};
like("$fh", qr{^\s+$url$}m, "Additional base URLs added");
like("$fh", qr{^\[$name\]$}m, "Repository got the correct name");
like($fh, qr{^includepkgs=foo bar$}m, "Included packages listed correctly");
like($fh, qr{^exclude=baz quux$}m, "Excluded packages listed correctly");


=pod

It must also handle properly the rendering of SSL fields

=cut

unlike($fh, qr{^sslcacert}m, "No SSL fields printed if not needed");

$repos = initialise_repos();
$repos->[0]->{protocols} = [{cacert => "ca path",
                             clientkey => "key path",
                             clientcert => "cert path"}];


ok(defined($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE)),
   "Repository with SSL correctly created");
$fh = get_file("/etc/yum.repos.d/a_repo.repo");
like($fh, qr{^sslcacert=$repos->[0]->{protocols}->[0]->{cacert}}m,
     "SSL CA correctly printed");
like($fh, qr{^sslclientkey=$repos->[0]->{protocols}->[0]->{clientkey}}m,
     "SSL key correctly printed");
like($fh, qr{^sslclientcert=$repos->[0]->{protocols}->[0]->{clientcert}}m,
     "SSL cert correctly printed");

=pod

=head2 Error handling

Failures in rendering a template are reported, and nothing is written
to disk.

=cut

$repos->[0]->{protocols}->[0]->{url} = $URL;

$cancelled = 0;
remove_any("/etc/yum.repos.d/$name.repo");
is($cmp->generate_repos($REPOS_DIR, $repos, "an invalid template name"), undef,
   "Errors on template rendering are detected");
is($cmp->{ERROR}, 1, "Errors on template rendering are reported");
ok(!defined(get_file("/etc/yum.repos.d/$name.repo")), "No file created/opened with render error");

=pod

=head2 Proxy-related settings

When passing proxy-related arguments, we need to test a few things:

=over 4

=item * Reverse proxies don't affect how the repository is rendered

=cut


$repos = initialise_repos();

$name = "forward_proxy";
$repos->[0]->{name} = $name;
$repos->[0]->{protocols}->[0]->{url} = $URL;

ok(defined($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE, $PROXY_HOST,
                               'forward')),
   "Proxy settings succeed");

$fh = get_file("$REPOS_DIR/$name.repo");

like("$fh", qr{^baseurl=\s*$URL$}m,
     "Forward proxy settings don't affect to the URL");
like($fh, qr{^proxy=http://$PROXY_HOST$}m,
     "Proxy line rendered for forward proxies");

=pod

=item * Reverse proxies have their URLs modified

=cut

$repos = initialise_repos();

$repos->[0]->{protocols}->[0]->{url} = $URL;

$name = "reverse_proxy";
$repos->[0]->{name} = $name;
ok(defined($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE,
                        $PROXY_HOST, 'reverse')),
   "Files with reverse proxies are properly rendered");

$fh = get_file("$REPOS_DIR/$name.repo");
like("$fh", qr{^baseurl=\s*http://$PROXY_HOST$}m,
     "Reverse proxies modify the URLs in the config files");

=pod

=item * Port number shows up with proxies

=cut

$repos->[0]->{protocols}->[0]->{url} = $URL;

ok(defined($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE,
                                $PROXY_HOST, 'reverse', $PROXY_PORT)),
   "Reverse proxies on special ports are properly rendered");
$fh = get_file("$REPOS_DIR/$name.repo");
like("$fh", qr{^baseurl=\s*http://$PROXY_HOST:$PROXY_PORT$}m,
     "Port number is rendered with the reverse proxy");

$repos->[0]->{protocols}->[0]->{url} = $URL;

ok(defined($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE,
                                $PROXY_HOST, 'forward', $PROXY_PORT)),
   "Forward proxies on special ports are properly rendered");
$fh = get_file("$REPOS_DIR/$name.repo");
like("$fh", qr{^proxy=http://$PROXY_HOST:$PROXY_PORT$}m,
     "Port number is rendered with the forward proxy");

=pod

=item * Many hosts listed as reverse proxies lead to many baseurls in the Yum repo

=cut

$repos = initialise_repos();

ok(defined($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE,
                                "$PROXY_HOST,another", 'reverse', $PROXY_PORT)),
   "List of reverse proxies succeeds to be rendered");

$fh = get_file("$REPOS_DIR/$repos->[0]->{name}.repo");
like($fh, qr{^baseurl= \s* http://$PROXY_HOST:$PROXY_PORT$
             \n \s* http://another:$PROXY_PORT$ }xm,
     "List of reverse proxies correctly rendered");

=pod

=item * A proxy listed on the repo is always used as a forward proxy.

=cut

$repos = initialise_repos();
$repos->[0]->{proxy} = "http://not.your.proxy";
ok(defined($cmp->generate_repos($REPOS_DIR, $repos, $REPOS_TEMPLATE,
                                "$PROXY_HOST,another", 'reverse', $PROXY_PORT)),
   "Repository with its own proxies rendered correctly");
$fh = get_file("/etc/yum.repos.d/a_repo.repo");
like($fh, qr{^proxy\s*=\s*http://not.your.proxy$}m, "Proxy set up correctly");

done_testing();

=pod

=back

=cut
