#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = { acommand => 'ls -lh' };

my $rs = $comp->print_commands($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{commands},
   "Correct file was opened");
is("$rs", q!define command {
	command_name acommand
	command_line ls -lh
}
!,
  'File contents properly written');

$rs->close();
