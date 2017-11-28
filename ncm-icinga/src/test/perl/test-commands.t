#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = { acommand => 'ls -lh' };

my $rs = $comp->print_commands($t);

my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{commands});
is("$fh", q!define command {
	command_name acommand
	command_line ls -lh
}
!,
  'File contents properly written');
