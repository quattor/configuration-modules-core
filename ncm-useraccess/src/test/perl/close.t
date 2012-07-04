#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::Quattor;
use Test::More;
use File::Path qw(mkpath);
use Cwd;
use NCM::Component::useraccess;
use CAF::Object;
use CAF::FileWriter;


$CAF::Object::NoAction = 1;

no warnings 'redefine';

*CAF::FileWriter::cancel = sub {
    my $self = shift;
    *$self->{CANCELLED}++;
    *$self->{save} = 0;
};

use warnings 'redefine';


=pod

=head1 DESCRIPTION

Test the C<close_files> method.

=cut




my $cmp = NCM::Component::useraccess->new("useraccess");

my $f = { managed_credentials => { a => 1, b => 1 },
	  a => CAF::FileWriter->new("target/test/foo", log => $cmp),
	  b => CAF::FileWriter->new("target/test/bar", log => $cmp),
	  c => CAF::FileWriter->new("target/test/baz", log => $cmp)
	};

$f->{a}->print("Some contents\n");
$f->{c}->print("Some other contents\n");

open(my $fh, ">", "target/test/bar");
close($fh);
open($fh, ">", "target/test/foo");
close($fh);

$cmp->close_files($f);

# All files have been cancelled at creation time because of
# NoAction. A second call can only happen inside close_files.
ok(! -f "target/test/bar", "Empty managed file is removed");
is(*{$f->{b}}->{CANCELLED}, 2, "Empty managed file is cancelled");
is(*{$f->{c}}->{CANCELLED}, 2,
   "File for ummanaged credentials is cancelled");
is(*{$f->{a}}->{CANCELLED}, 1, "Managed file is not cancelled");
ok(-f "target/test/foo", "Managed file with contents is not removed");

done_testing();
