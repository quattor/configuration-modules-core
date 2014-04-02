# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Testing base functions

Tests the functionality of the lower function of the puppet component: 
 * unescape_keys
 * checkfile
 * yaml
 * tiny
=cut

use strict;
use warnings;
use NCM::Component::puppet;
use Test::More tests => 4;
use Test::Quattor;
use EDG::WP4::CCM::Element qw(unescape);
use Data::Dumper;

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

Readonly::Scalar my $GOOD => "This is a fake content";
Readonly::Scalar my $WRONG => "This is a wrong fake content";


Readonly::Scalar my $CHECKFILE_FILE => '/tmp/ncm-puppet.test.checkfile';

Readonly::Scalar my $YAML_FILE => '/tmp/ncm-puppet.test.yaml';
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

Readonly::Scalar my $TINY_FILE => '/tmp/ncm-puppet.test.tiny';
Readonly::Scalar my $TINY => <<TINY;
[section1]
field1=value1
field2=value2

[section2]
field3=value3
TINY

#Testing unescape_keys
#
is(Dumper($comp->unescape_keys(\%HASH_IN)),Dumper(\%HASH_EXP),"The unescape_keys function does the job");

#Testing checkfile
#
set_file_contents($CHECKFILE_FILE,$WRONG);
$comp->checkfile($CHECKFILE_FILE,$GOOD);
is(get_file($CHECKFILE_FILE),$GOOD,"checkfile function puts the correct content in the file");

#Testing yaml
#
set_file_contents($YAML_FILE,$WRONG);
$comp->yaml(\%HASH_IN,$YAML_FILE);
is(get_file($YAML_FILE),$YAML,"yaml function writes a good yaml file");

#Testing tiny
#
set_file_contents($TINY_FILE,$WRONG);
$comp->tiny(\%HASH_TINY,$TINY_FILE);
is(get_file($TINY_FILE),$TINY,"tiny function writes a good tiny file");




