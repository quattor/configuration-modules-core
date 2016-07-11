# -*- mode: cperl -*-
use strict;
use warnings;
use CAF::Object;
use Test::Quattor;
use NCM::Component::postfix;
use Test::More tests => 9;

use Test::Quattor::TextRender::Base;
$CAF::Object::NoAction = 1;
my $caf_trd = mock_textrender();

my $cmp = NCM::Component::postfix->new('postfix');

my $main = {
	    _2bounce_notice_recipient => "this is a bounce address",
	    allow_percent_hack => 1,
	    allow_untrusted_routing => 0,
	    alias_maps => [
			   { type => "foo",
			     name => "bar"
			   },
			   { type => "baz",
			     name => "quux" }
			  ],
	    allow_mail_to_files => [ qw(a b c d) ],
	    mydestination => [ 1,2,3],
	   };



my $rs = $cmp->handle_config_file($main,
                                  { file => "/etc/postfix/main.cf",
                                    template => "main.tt" });

ok($rs, "Successfully handled the master config file");

my $fh = get_file("/etc/postfix/main.cf");
ok(defined($fh), "Correct file opened");
like($fh, qr{^2bounce_notice_recipient\s*=\s*$main->{_2bounce_notice_recipient}\s*$}m,
     "Bounce notice had its heading '_' correctly removed");
like($fh, qr{^allow_percent_hack\s*=\s*yes}m, "True boolean correctly parsed");
like($fh, qr{^allow_untrusted_routing\s*=\s*no}m, "False boolean correctly parsed");
unlike($fh, qr{^alternate_config_directories}m,
       "Undefined keys are not shown in the file");
like($fh, qr{^alias_maps\s*=\s*foo:bar,\s*baz:quux(?:,)?\s*$}m,
     "Alias maps correctly defined");
like($fh, qr{^allow_mail_to_files\s*=\s*a, b, c, d\s*$}m,
     "List field correctly handled");
like($fh, qr{^mydestination\s*=\s*1, 2, 3\s*$}m,
     "mydestination correctly generated");
