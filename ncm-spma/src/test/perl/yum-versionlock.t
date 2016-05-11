# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<versionlock> method.  This method adds all packages
from the profile to a file in /etc.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use CAF::Object;
use Set::Scalar;

$CAF::Object::NoAction = 1;

Readonly::Array my @REPOQUERY_ORIG => NCM::Component::spma::yum::REPOQUERY;
Readonly::Array my @REPOQUERY => @{NCM::Component::spma::yum::_set_yum_config(\@REPOQUERY_ORIG)};
Readonly my $FILE => "/etc/yum/pluginconf.d/versionlock.list";

ok(grep {$_ eq '-C'} @REPOQUERY, 'repoquery command has cache enabled');

my $cmp = NCM::Component::spma::yum->new("spma");


my $pkgs = {
    "ConsoleKit"=> {
	"_30_2e4_2e1_2d3_2eel6"=> {
	    "arch"=> {
		"x86_64"=> "sl620_x86_64"
	       }
	   }
       },
    "ConsoleKit_2dlibs"=> {
	"_30_2e4_2e1_2d3_2eel6"=> {
	    "arch"=> {
		"x86_64"=> "sl620_x86_64"
	       }
	   }
       },
    "glibc"=> {
	"_32_2e12_2d1_2e47_2eel6_5f2_2e9"=> {
	    "arch"=> {
		"i686"=> "sl620_x86_64_updates",
		"x86_64"=> "sl620_x86_64_updates"
	       }
	   }
       },
    "tzdata_2djava"=> {
	"_32012b_2d3_2eel6"=> {
	    "arch"=> {
		"noarch"=> "sl620_x86_64_updates"
	       }
	   }
       },
    "kde" => {},
    "foo" => { "a" => { "arch" => { "x" => "arepo" } } },
    "python_2a" => {
	"_32_2e7_2e5_2del6" => {
	    "arch" => {
		"x86_64" => {}
	       }
	   }
       },
    "perl" => {
        "_35_2e10_2a" => {
            "arch" => {
                "x86_64" => {}
               }
           }
       },
   };


# I don't know in which order the arguments will be passed!!
set_desired_output(join(" ", @REPOQUERY, "glibc-2.12-1.47.el6_2.9.x86_64",
			"glibc-2.12-1.47.el6_2.9.i686"),
		   q{0:glibc-2.12-1.47.el6_2.9.x86_64
1:glibc-2.12-1.47.el6_2.9.i686});
set_desired_err(join(" ", @REPOQUERY, "glibc-2.12-1.47.el6_2.9.x86_64",
		     "glibc-2.12-1.47.el6_2.9.i686"), "");
set_desired_output(join(" ", @REPOQUERY, "glibc-2.12-1.47.el6_2.9.i686",
			"glibc-2.12-1.47.el6_2.9.x86_64"),
		   q{0:glibc-2.12-1.47.el6_2.9.x86_64
1:glibc-2.12-1.47.el6_2.9.i686});
set_desired_err(join(" ", @REPOQUERY, "glibc-2.12-1.47.el6_2.9.i686",
		     "glibc-2.12-1.47.el6_2.9.x86_64"), "");
is($cmp->versionlock({ glibc => $pkgs->{glibc},
		       kde => $pkgs->{kde}}), 1,
   "Simple versionlock succeeds");

my $fh = get_file($FILE);

like($fh, qr{^\d:glibc.*i686}m, "glibc listed in version lock");
like($fh, qr{^\d:glibc.*x86_64}m, "glibc listed in version lock winth all archs");
unlike($fh, qr{kde}, "Package kde with no version is not version locked");

set_command_status(join(" ", @REPOQUERY, "glibc-2.12-1.47.el6_2.9.x86_64",
			"glibc-2.12-1.47.el6_2.9.i686"), 1);
set_command_status(join(" ", @REPOQUERY, "glibc-2.12-1.47.el6_2.9.i686",
			"glibc-2.12-1.47.el6_2.9.x86_64"), 1);


is($cmp->versionlock({ glibc => $pkgs->{glibc} }), 0,
   "Errors in repoquery are propagated");
is($cmp->{ERROR}, 1, "Errors in versionlock are logged");

set_desired_output(join(" ", @REPOQUERY, "foo-a.x"), "");
set_desired_err(join(" ", @REPOQUERY, "foo-a.x"), "Could not match: this is a bogus package!!");
is($cmp->versionlock({ foo => $pkgs->{foo}}), 0, "Unmatched package triggers an error");

set_desired_err(join(" ", @REPOQUERY, "foo-a.x"), "");
set_desired_output(join(" ", @REPOQUERY, "foo-a.x"), "");
is($cmp->versionlock({foo => $pkgs->{foo}}), 0,
   "Not locking packages that should be triggers an error");

set_desired_output(join(" ", @REPOQUERY, "python*-2.7.5-el6.x86_64"),
		   q{0:python-2.7.5-el6.x86_64
0:python-libs-2.7.5-el6.x86_64
0:python-devel-2.7.5-el6.x86_64});
set_desired_err(join(" ", @REPOQUERY, "python*-2.7.5-el6.x86_64"));

is($cmp->versionlock({python_2a => $pkgs->{python_2a}}), 1,
   "Locking of packages with wildcards succeeds");

$fh = get_file($FILE);
like($fh, qr{^0:python}m, "Versionlocked packages are correctly listed");

set_desired_output(join(" ", @REPOQUERY, "python*-2.7.5-el6.x86_64"), "");
is($cmp->versionlock({pythoh_2a => $pkgs->{python_2a}}), 0,
   "Detected non-locked packages when wildcards are present");

set_desired_output(join(" ", @REPOQUERY, "perl-5.10*.x86_64"), "perl-5.10.1-1.x86_64");
is($cmp->versionlock({perl => $pkgs->{perl}}), 1,
   "Version with star is processed correctly");


set_desired_output(join(" ", @REPOQUERY, "perl-5.10*.x86_64"), "");
my $tmppkgs = {perl => $pkgs->{perl}};
my ($locked, $toquery) = $cmp->prepare_lock_lists($tmppkgs);

is($cmp->locked_all_packages($locked, "", 0), 1, "Failed to lock packages with star version (but it's ok without fullsearch)");
is($cmp->locked_all_packages($locked, "", 1), 0, "Failed to lock packages with star version (fullsearch on)");

is($cmp->versionlock($tmppkgs, 0), 1,
   "Failure to versionlock star version is reported (but it's ok without fullsearch)");
is($cmp->versionlock($tmppkgs, 1), 0,
   "Failure to versionlock star version is reported (fullsearch on)");

# make large enough output with mock versions and random ordered output
# also make list of packages with version wildcards
srand(0);
my @chars = ("a".."z", "A".."Z");
sub make_rand_name {
    my $size = shift || 8;
    return join '', map { @chars[rand @chars] } 1 .. $size;
}

sub make_rand_version {
    return int(rand(100)).".".int(rand(10)).".".int(rand(100));
}

sub escape {
  my $str=shift;
  $str =~ s/(^[0-9]|[^a-zA-Z0-9])/sprintf("_%lx", ord($1))/eg;
  return $str;
}

my $randpkgs = {};
my ($name, $subname, $version, $wildversion, $arch,@randrepoqueryreply);
# insert $tot iterations; per iteration 2 packages will be added
my $tot = 100;
foreach my $idx (1..$tot) {
    $name = make_rand_name(10);
    $version = make_rand_version();

    # glob that will match
    $wildversion = $version;
    $wildversion =~ s/^.{3}/*/;

    $arch = "x86_64";

    push(@randrepoqueryreply, "0:$name-$version.$arch");
    $randpkgs->{escape($name)} = { escape($wildversion) => { "arch" => { $arch => {} } } };

    $subname = make_rand_name(10);
    push(@randrepoqueryreply, "0:$name-$subname-$version.$arch");
    $randpkgs->{escape("$name-$subname")} = { escape($wildversion) => { "arch" => { $arch => {} } } };
}

# there's no way to guess the repoquery command that will be run (the args are not sorted).
($locked, $toquery) = $cmp->prepare_lock_lists($randpkgs);
is($locked->size, $tot*2, "2 packages per iteration, $tot iterations.");
is($cmp->locked_all_packages($locked, join("\n", @randrepoqueryreply, ''), 1), 1,
   "All wildcard versions match (fullsearch on)");

# insert a packages that has no match in repoquery output
# just reuse the last defined one
$randpkgs->{escape("NOMATCH$name-$subname")} = { escape($wildversion) => { "arch" => { $arch => {} } } };
($locked, $toquery) = $cmp->prepare_lock_lists($randpkgs);
is($locked->size, $tot*2+1, "2 packages per iteration, $tot iterations; and 1 extra that can't be matched.");
is($cmp->locked_all_packages($locked, join("\n", @randrepoqueryreply, ''), 1), 0,
   "Wildcard versions match fails (fullsearch on)");


done_testing();
