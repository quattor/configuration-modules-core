# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<wanted_pkgs> method.  This method converts all
packages from the profile into a set of strings that can be compared
with the set of already installed packages.

=head1 TESTS

These tests will run only if the RPM binary is present.  They consist
on retrieving the set of all installed packages and ensure there are
no surprising strings among them.

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma::yum;


plan skip_all => "No RPM database to play with" if ! -x "/bin/rpm";

my $cmp = NCM::Component::spma::yum->new("spma");

# A list of packages, based on a real profile.
my $wanted = {
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
    "python_2a" => {
	"_32_2e7_2e5_2del6" => {
	    "arch" => {
		"x86_64" => {}
	       }
	   }
       },
};

my $pkgs = $cmp->wanted_pkgs($wanted);
isa_ok($pkgs, "Set::Scalar", "Received a set, with no errors");

foreach my $pkg (@$pkgs)
{
    like($pkg, qr!^.*(;\w+)?$!,
	 "Package $pkg has the correct format string");
    unlike($pkg, qr{-_}, "All fields are correctly unescaped");
}

is(scalar(grep(m{^glibc}, @$pkgs)), 2,
   "Multiple architectures for the same package are correctly handled");
ok($pkgs->has("python;x86_64"), "Package with wildcards correctly handled");

$pkgs = $cmp->wanted_pkgs({'@malformed' => {}});
is($pkgs, undef, "Malformed packages trigger errors");

done_testing();
