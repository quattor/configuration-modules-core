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
	    "kde" => {}
	     };

$cmp->versionlock($pkgs);

my $fh = get_file("/etc/yum/pluginconf.d/versionlock.list");

like($fh, qr{^tzdata-java-.*\.noarch$}m,
     "Package tzdata-java listed in version lock");
like($fh, qr{glibc.*i686}, "glibc listed in version lock");
unlike($fh, qr{^kde}, "Package kde with no version is not version locked");

done_testing();
