# -*- mode: cperl -*-
use strict;
use warnings;
use CAF::Object;
use FindBin qw($Bin);
use lib $Bin;
use Test::Quattor qw(%files_contents %commands_run);
use NCM::Component::postfix;
use Test::More tests => 6;
use CAF::Object;
no strict 'refs';

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::postfix->new('postfix');

my $main = {
	    _2bounce_notice_recipient => "this is a bounce address",
	    allow_percent_hack => 1,
	    allow_untrusted_routing => 0
	   };



my $rs = $cmp->handle_config_file($main,
				  { file => "/etc/postfix/main.cf",
				    template => "postfix/main.tt" });

ok($rs, "Successfully handled the master config file");

ok(exists($Test::Quattor::files_contents{"/etc/postfix/main.cf"}), "Correct file opened");
my $fh = $Test::Quattor::files_contents{"/etc/postfix/main.cf"};
like($fh, qr{^2bounce_notice_recipient\s*=\s*$main->{_2bounce_notice_recipient}\s*$}m,
     "Bounce notice had its heading '_' correctly removed");
like($fh, qr{^allow_percent_hack\s*=\s*yes}m, "True boolean correctly parsed");
like($fh, qr{^allow_untrusted_routing\s*=\s*no}m, "False boolean correctly parsed");
unlike($fh, qr{^alternate_config_directories}m,
       "Undefined keys are not shown in the file");
