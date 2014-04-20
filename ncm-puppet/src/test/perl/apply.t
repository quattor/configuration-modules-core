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

=pod

Tests that the node files are written properly by the nodefiles function. Also checking that the files names are unescaped. 2 tests.

=cut

my $fh;

set_file_contents("$FILES_DIR/foo1.pp",$WRONG);
set_file_contents("$FILES_DIR/foo2.pp",$WRONG);
$comp->nodefiles({'foo1_2epp' => {'contents'=>$GOOD},
                  'foo2_2epp' => {'contents'=>$GOOD}});
$fh = get_file("$FILES_DIR/foo1.pp");
is("$fh", $GOOD, "checkfile function puts the correct content in the node files");
$fh = get_file("$FILES_DIR/foo2.pp");
is("$fh", $GOOD, "checkfile function puts the correct content in the node files");

=pod

Tests that the apply function correctly runs the "puppet apply" command. Three scenarions are taken into account:

=over 4

=item * All apply commands run successfully and perform no actions (4 tests):

=over 4

=item * tests that "puppet apply" is invoked for each of the nodefiles (all set to exit with status 0);

=item * tests that no "INFO" or "ERROR" message is raised by the component.

=back

=cut

set_command_status("$APPLY_CMD $FILES_DIR/foo1.pp",0);
set_command_status("$APPLY_CMD $FILES_DIR/foo2.pp",0);

$comp->apply({'foo1_2epp' => {'contents'=>$GOOD},'foo2_2epp' => {'contents'=>$GOOD}});

ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo1.pp")), "1st apply command is invoked");
ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo2.pp")), "2nd apply command is invoked");
ok(!exists($comp->{ERROR}), "No errors in normal execution");
ok(!exists($comp->{INFO}), "No messages when there are no changes");

=pod

=item * All apply commands run successfully, one of them performs some action (4 tests):

=over 4

=item * tests that "puppet apply" is invoked for each of the nodefiles (one is set to exit with status 2);

=item * tests that an "INFO" message and no "ERROR" message is raised by the component.

=back

=cut

set_command_status("$APPLY_CMD $FILES_DIR/foo3.pp",2<<8);
set_command_status("$APPLY_CMD $FILES_DIR/foo4.pp",0);

$comp->apply({'foo3_2epp' => {'contents'=>$GOOD},'foo4_2epp' => {'contents'=>$GOOD}});

ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo3.pp")), "1st apply command is invoked");
ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo4.pp")), "2nd apply command is invoked");
ok(!exists($comp->{ERROR}), "No errors in normal execution");
ok(exists($comp->{INFO}), "A message is printed to inform that a change was made");

=pod

=item * One "puppet apply" command fail (3 tests):

=over 4

=item * tests that "puppet apply" is invoked (it is set to exit with status 6);

=item * tests that an "ERROR" message is raised by the component.

=back

=back

=cut

set_command_status("$APPLY_CMD $FILES_DIR/foo5.pp",6<<8);

$comp->apply({'foo5_2epp' => {'contents'=>$GOOD}});

ok(defined(get_command("$APPLY_CMD $FILES_DIR/foo5.pp")), "apply command is invoked");
ok(exists($comp->{ERROR}), "The component exits with error");
