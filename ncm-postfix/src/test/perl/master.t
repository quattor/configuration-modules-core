# -*- mode: cperl -*-
use strict;
use warnings;
use CAF::Object;
use Test::Quattor;
use NCM::Component::postfix;
use Test::More tests => 5;

use Test::Quattor::TextRender::Base;
$CAF::Object::NoAction = 1;
my $caf_trd = mock_textrender();

my $cmp = NCM::Component::postfix->new('postfix');

my $master = [ {
		name => "foo",
		type => 'hello',
		command => "Hello, world",
		private => 1,
		unprivileged => 1,
		chroot => 1,
		wakeup => 100,
		maxproc => 20,
	       },
	       {
		name => "bar",
		type => "world",
		private => 0,
		unprivileged => 0,
		chroot => 0,
		wakeup => 100,
		maxproc => 20,
		command => "World, hello"
	       },
	       {
		name => "foo",
		type => "baz",
		private => 0,
		unprivileged => 1,
		chroot => 0,
		maxproc => 30,
		wakeup => 100,
		command => "Another instance of foo"
	       }
	  ];



my $rs = $cmp->handle_config_file({master => $master},
                                  { file => "/etc/postfix/master.cf",
                                    template => "master.tt" });

ok($rs, "Successfully handled the master config file");

my $fh = get_file("/etc/postfix/master.cf");
ok(defined($fh), "Correct file opened");
like($fh, qr{^foo\s+hello\s+y\s+y\s+y\s+\d+\s+\d+\s+Hello, world\s*$}m,
     "First line correctly rendered");
like($fh, qr{^bar\s+world\s+n\s+n\s+n\s+\d+\s+\d+\s+World, hello\s*$}m,
     "Second line correctly rendered");
like($fh, qr{^foo\s+baz\s+n\s+y\s+n\s+\d+\s+\d+\s+Another instance of foo\s*$}m,
    "Second instance with the same name correctly rendered");
