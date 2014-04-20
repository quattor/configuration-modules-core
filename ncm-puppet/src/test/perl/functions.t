# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Testing base functions

Tests the functionality of the lower function of the puppet component:

=over 4

=item * unescape_keys: checks that the functions correctly returns a data structure with unescaped hash keys.

=item * checkfile: checks that the functions correctly modifies the content of a file to set it to the desired value.

=item * yaml: checks that the function writes a sensible yaml file.

=item * tiny: checks that the function writes a sensible tiny file.

=back

=cut

use strict;
use warnings;
use NCM::Component::puppet;
use Test::More tests => 4;
use Test::Quattor;
use Test::Deep;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $comp = NCM::Component::puppet->new('puppet');

use Readonly;

Readonly::Hash my %HASH_IN => (
			       "_3akey1" => "value1",
			       "_3akey2" =>  ["value2","_3avalue3",{"_3akey8"=>"value4"}],
			       "_3akey3" =>  {
					      "_3akey4" => "_3avalue5",
					      "_3akey6" => {"_3akey7" => "value8"}
					     }
			       );
Readonly::Hash my %HASH_EXP => (
			       ":key1" => "value1",
			       ":key2" =>  ["value2","_3avalue3",{":key8"=>"value4"}],
			       ":key3" =>  {
					      ":key4" => "_3avalue5",
					      ":key6" => {":key7" => "value8"}
					     }
			       );

Readonly::Hash my %HASH_TINY => (
			       "section1" =>  {
					      "field1" => "value1",
					      "field2" => "value2",
					     },
			       "section2" =>  {
					      "field3" => "value3",
					     }
				);

Readonly::Scalar my $TESTFILE => '/test.dir/test.file';
Readonly::Scalar my $GOOD => "This is a fake content";
Readonly::Scalar my $WRONG => "This is a wrong fake content";
Readonly::Scalar my $YAML => <<YAML;
---
:key1: value1
:key2:
- value2
- _3avalue3
- :key8: value4
:key3:
  :key4: _3avalue5
  :key6:
    :key7: value8
YAML
Readonly::Scalar my $TINY => <<TINY;
[section1]
field1=value1
field2=value2

[section2]
field3=value3
TINY

#Testing unescape_keys
#
cmp_deeply($comp->unescape_keys(\%HASH_IN),\%HASH_EXP,"The unescape_keys function does the job");

#Testing checkfile
#
set_file_contents($TESTFILE,$WRONG);
$comp->checkfile($TESTFILE,$GOOD);
my $fh = get_file($TESTFILE);
is("$fh", $GOOD, "checkfile function puts the correct content in the file");

#Testing yaml
#
set_file_contents($TESTFILE,$WRONG);
$comp->yaml(\%HASH_IN,$TESTFILE);

$fh = get_file($TESTFILE);
is("$fh", $YAML, "yaml function writes a good yaml file");

#Testing tiny
#
set_file_contents($TESTFILE,$WRONG);
$comp->tiny(\%HASH_TINY,$TESTFILE);
$fh = get_file($TESTFILE);
is("$fh", $TINY, "tiny function writes a good tiny file");
