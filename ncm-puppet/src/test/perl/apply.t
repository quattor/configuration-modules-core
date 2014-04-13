# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Testing manifests execution

=cut

use strict;
use warnings;
use NCM::Component::puppet;
use Test::More tests => 12;
use Test::Quattor;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $comp = NCM::Component::puppet->new('puppet');

use Readonly;

Readonly::Scalar my $GOOD => "This is a fake content";
Readonly::Scalar my $WRONG => "This is a wrong fake content";
Readonly::Scalar my $FILES_DIR => "/etc/puppet/manifests";
Readonly::Scalar my $APPLY_CMD => "puppet apply --detailed-exitcodes -v -l /var/log/puppet/log";

#Test that the node files are written properly (also checking that the files names are unescaped)
#
set_file_contents("$FILES_DIR/foo1.pp",$WRONG);
set_file_contents("$FILES_DIR/foo2.pp",$WRONG);
$comp->nodefiles({'foo1_2epp' => {'contents'=>$GOOD},'foo2_2epp' => {'contents'=>$GOOD}});
is(get_file("$FILES_DIR/foo1.pp"),$GOOD,"checkfile function puts the correct content in the node files");
is(get_file("$FILES_DIR/foo2.pp"),$GOOD,"checkfile function puts the correct content in the node files");

#1st Case: all apply command run succesfully and perform no actions
# - all command invoked and returing 0
# - no info/error messages
#
set_command_status("$APPLY_CMD $FILES_DIR/foo1.pp",0);
set_command_status("$APPLY_CMD $FILES_DIR/foo2.pp",0);

$comp->apply({'foo1_2epp' => {'contents'=>$GOOD},'foo2_2epp' => {'contents'=>$GOOD}});

ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo1.pp")), "1st apply command is invoked");
ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo2.pp")), "2nd apply command is invoked");
ok(!exists($comp->{ERROR}), "No errors in normal execution");
ok(!exists($comp->{INFO}), "No messages when there are no changes");

#2nd Case: all apply command run succesfully, one of them performs an action
# - 1 commad returns status 2. Both commands are invoked
# - no errors messages + 1 info message
#
set_command_status("$APPLY_CMD $FILES_DIR/foo3.pp",2<<8);
set_command_status("$APPLY_CMD $FILES_DIR/foo4.pp",0);

$comp->apply({'foo3_2epp' => {'contents'=>$GOOD},'foo4_2epp' => {'contents'=>$GOOD}});

ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo3.pp")), "1st apply command is invoked");
ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo4.pp")), "2nd apply command is invoked");
ok(!exists($comp->{ERROR}), "No errors in normal execution");
ok(exists($comp->{INFO}), "A message is printed to inform that a change was made");

#2nd Case: the apply command fails
# - the command returns error status
# - the component exits with error message
#
set_command_status("$APPLY_CMD $FILES_DIR/foo5.pp",6<<8);

$comp->apply({'foo5_2epp' => {'contents'=>$GOOD}});

ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo5.pp")), "apply command is invoked");
ok(exists($comp->{ERROR}), "The component exits with error");
