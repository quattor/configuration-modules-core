# -*- mode: cperl -*-
use strict;
use warnings;
use CAF::Object;
use FindBin qw($Bin);
use lib $Bin;
use Test::Quattor qw(%files_contents %commands_run);
use NCM::Component::postfix;
use Test::More tests => 4;
use CAF::Object;

no strict 'refs';

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::postfix->new('postfix');

my $master = {foo => {
		      type => 'hello',
		      command => "Hello, world",
		      private => 1,
		      unprivileged => 1,
		      chroot => 1,
		      wakeup => 100,
		      maxproc => 20,
		     },
	      bar => {
		      type => "world",
		      private => 0,
		      unprivileged => 0,
		      chroot => 0,
		      wakeup => 100,
		      maxproc => 20,
		      command => "World, hello"
		     }
	     };



my $rs = $cmp->handle_config_file({master => $master},
				   { file => "/etc/postfix/master.cf",
				     template => "postfix/master.tt" });

ok($rs, "Successfully handled the master config file");

ok(exists($Test::Quattor::files_contents{"/etc/postfix/master.cf"}), "Correct file opened");
my $fh = $Test::Quattor::files_contents{"/etc/postfix/master.cf"};
like($fh, qr{^foo\s+hello\s+yes\s+yes\s+yes\s+\d+\s+\d+\s+Hello, world\s*$}m,
     "First line correctly rendered");
like($fh, qr{^bar\s+world\s+no\s+no\s+no\s+\d+\s+\d+\s+World, hello\s*$}m,
     "Last line correctly rendered");

