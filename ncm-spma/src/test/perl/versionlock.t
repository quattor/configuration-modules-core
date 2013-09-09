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
use NCM::Component::spma;
use Test::Quattor;
use CAF::Object;
use Set::Scalar;

$CAF::Object::NoAction = 1;

Readonly::Array my @REPOQUERY => NCM::Component::spma::REPOQUERY;
Readonly my $FILE => "/etc/yum/pluginconf.d/versionlock.list";

my $cmp = NCM::Component::spma->new("spma");


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

TODO : {
    local $TODO = <<'EOF';
I don't know yet what to do when the version has a star.  I cannot
detect it with trivial set operations, and brute force pattern
matching makes this method quadratic.  Using tries or other fancy
data structures looks like overengineering at this stage.

In my little tests, brute force pattern matching is OK for up to 2000
versionlocked packages.  Is anyone installing more than 2000 packages?
EOF

    set_desired_output(join(" ", @REPOQUERY, "perl-5.10*.x86_64"), "");
    is($cmp->versionlock({perl => $pkgs->{perl}}), 0,
       "Failure to versionlock star version is reported");
}

done_testing();
