#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Test::More tests => 6;
use File::Find;

use CAF::Application;
our $this_app = new CAF::Application ('a', @ARGV);
use Exporter;
our @EXPORT = ($this_app);

use NCM::Component::icinga;
use CAF::Object;
$CAF::Object::NoAction = 1;

my $comp = NCM::Component::icinga->new('icinga');

my $t = { acontact => {
		       alias => 'foo',
		       host_notification_commands => [[1,2],[3,4]],
		       foo => [4,5],
		       bar => 6
		       }
	};

my $rs = $comp->print_contacts($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");

is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{contacts},
   "Correct file was opened");

like("$rs", qr(^\s*alias\s+foo$)m, "Alias properly written");
like("$rs", qr(^\s*host_notification_commands\s+1!2,3!4$)m,
     "Notification commands properly written");
like("$rs", qr(^\s*foo\s+4,5$)m,
     "Random array field properly written");
like("$rs", qr(^\s*bar\s+6$)m,
     "Random scalar field properly written");
