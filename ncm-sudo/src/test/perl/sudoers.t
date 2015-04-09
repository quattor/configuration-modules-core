#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::sudo;
use CAF::Object;
use File::Temp qw(tempfile);
use File::Path qw(mkpath);
$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Tests the generation of /etc/sudoers files.

Implies validating the contents of an C</etc/sudoers> file before
actually writting it to disk, and ensuring the method is really able
to write valid files from a valid profile.

=cut

my $cmp = NCM::Component::sudo->new('sudo');

my $USER = NCM::Component::sudo::USER_ALIASES();
my $RUNAS = NCM::Component::sudo::RUNAS_ALIASES();
my $HOST = NCM::Component::sudo::HOST_ALIASES();
my $CMD = NCM::Component::sudo::CMD_ALIASES();
my $CHECK = NCM::Component::sudo::VISUDO_CHECK();

my $is_valid_sudoers = 0;

no warnings 'redefine';
*NCM::Component::sudo::is_valid_sudoers = sub {
    return $is_valid_sudoers;
};
use warnings 'redefine';


my ($aliases, $opts, $lns, $includes, $includes_dirs);

$aliases = { $USER => ["u"],
	     $RUNAS => ["r"],
	     $CMD => ["c"],
	     $HOST => ["h"]
	   };
$opts = ["\t!insults,requiretty"];
$lns = ["l"];
$includes = ["i"];
$includes_dirs = ["id"];


$cmp->write_sudoers($aliases, $opts, $lns, $includes, $includes_dirs);
my $fh = get_file("/etc/sudoers");
is($cmp->{ERROR}, 1, "Invalid sudoers get reported and cancelled");

is(*$fh->{options}->{mode}, 0440,
   "sudoers is created with the correct permissions");

isa_ok($fh, "CAF::FileWriter", "A file was created");
like($fh, qr{^User_Alias\s+u$}m, "User aliases generated");
like($fh, qr{^Runas_Alias\s+r$}m, "Runas aliases generated");
like($fh, qr{^Cmnd_Alias\s+c$}m, "Command aliases generated");
like($fh, qr{^Host_Alias\s+h$}m, "Host aliases generated");
like($fh, qr{^#include i$}m, "Include lines generated");
like($fh, qr{^Defaults\s+!insults,requiretty$}m, "Defaults lines generated");
like($fh, qr{^l$}m, "Privilege lines generated");
like($fh, qr{^#includedir id$}m, "Includedir lines generated");

$lns = ["root ALL=(ALL) ALL"];
$aliases = {$USER => [],
	    $RUNAS => [],
	    $CMD => [],
	    $HOST => []
	    };
$includes = [];
$opts = [];
$includes_dirs = [];

$is_valid_sudoers = 1;

$cmp->write_sudoers($aliases, $opts, $lns, $includes, $includes_dirs);

is($cmp->{ERROR}, 1, "Valid sudoers don't trigger any more errors");

$fh = get_file("/etc/sudoers");

mkpath("target/test") if ! -d "target/test";
my ($tmp, $tmpname) = tempfile(DIR => "target/test");

print $tmp "$fh";
system(qw(/usr/sbin/visudo -c -f), $tmpname);
is($?, 0, "The component is able to generate valid sudoers file");

done_testing();
