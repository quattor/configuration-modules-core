use strict;
use warnings;

use Test::More tests => 45;

use myIcinga;

# Returns a tree with all the keys expected by the component.
sub init_tree
{
    return {
        general => {
            hello         => 'a',
            world         => [1, 2],
            log_file      => "foo.log",
            broker_module => ["/foo init=1", "/bar init=2"]
        },
        cgi                 => '/etc/icinga/cgi.cfg',
        hosts               => '/etc/icinga/objects/hosts.cfg',
        hosts_generic       => '/etc/icinga/objects/hosts_generic.cfg',
        hostgroups          => '/etc/icinga/objects/hostgroups.cfg',
        services            => '/etc/icinga/objects/services.cfg',
        serviceextinfo      => '/etc/icinga/objects/serviceextinfo.cfg',
        servicedependencies => '/etc/icinga/objects/servicedependencies.cfg',
        servicegroups       => '/etc/icinga/objects/servicegroups.cfg',
        contacts            => '/etc/icinga/objects/contacts.cfg',
        contactgroups       => '/etc/icinga/objects/contactgroups.cfg',
        commands            => '/etc/icinga/objects/commands.cfg',
        macros              => '/etc/icinga/resource.cfg',
        timeperiods         => '/etc/icinga/objects/timeperiods.cfg',
        hostdependencies    => '/etc/icinga/objects/hostdependencies.cfg',
        ido2db              => '/etc/icinga/ido2db.cfg',
        cfgdir              => '/etc/icinga',
    };
}

sub validate_tree
{
    my ($tree, $file) = @_;

    delete($tree->{cgi});
    delete($tree->{ido2db});

    #isa_ok($file, 'CAF::FileWriter', "Something was returned");

    #is(
    #    *$file->{filename},
    #    NCM::Component::icinga::ICINGA_FILES->{general},
    #    "Correct file was opened"
    #);

    my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{general});
    like("$fh", qr"resource_file=$tree->{macros}$"m, "Macros file got the correct value");
    delete($tree->{macros});

    like("$fh", qr"hello=a$"m, "General key hello found with the correct value");
    like("$fh", qr"world=1!2", "General key world found with the correct value");

    like("$fh", qr"log_file=foo.log"m, "Log file properly recorded");

    my %h = %{NCM::Component::icinga::ICINGA_FILES()};
    foreach my $i (qw(general macros cgi ido2db)) {
        delete($h{$i});
    }

    foreach my $v (values(%h)) {
        like("$fh", qr"cfg_file=$v$"m, "Config file $v got declared");
    }

    unlike("$fh", qr"^(?:hostgroups|hosts)=", "Only general and selected keys are printed");
    like(
        "$fh",
        qr"^broker_module\s*=\s*/foo init=1$"m,
        "Configuration for broker modules is printed in its own lines"
    );
}

=pod

=head1 SYNOPSIS

Tests the C<print_general> method of NCM::Component::icinga.

=head1 DESCRIPTION

This script ensures the C<print_general> method prints correct
contents for C</etc/icinga/icinga.cfg>. The method also creates some
directories for holding configuration and spool files, and that's not
covered by these tests, since they'd need root permissions.

=head1 TESTS

=cut

my $comp = NCM::Component::icinga->new('icinga');

# Basic tree. It's not valid according to the schema, but all we wish
# to do is to ensure that some keys are filled in the file.
my $t = init_tree();

=pod

=head2 Test that the mandatory fields are there

Run with a basic tree.

All configuration files should be listed in the file. No keys or
values from the profile should be there. For instance, no host groups
should be listed on this file, but a "hostgroups.cfg" file should be
present.

=cut

my $rs = $comp->print_general($t);

validate_tree($t, $rs);

=pod

=head2 Ensure external files are passed properly

Add some fake C<external_files> and C<external_dirs> to our working
layout. They should be present as ordinary configuration files
(C<cfg_file>) or directories (C<cfg_dir>).

=cut

$t = init_tree;
$t->{external_files} = [qw(a b c)];

$t->{external_dirs} = [1 .. 3];

$rs = $comp->print_general($t);
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{general});

foreach my $i (qw(a b c)) {
    like("$fh", qr"cfg_file=$i$"m, "External files present");
}

for my $i (1 .. 3) {
    like("$fh", qr"cfg_dir=$i$"m, "External dirs present");
}

delete($t->{external_files});
delete($t->{external_dirs});
validate_tree($t, $rs);

$t = init_tree();

my $c = $t->{hosts_generic};
delete($t->{hosts_generic});
$rs = $comp->print_general($t);
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{general});
unlike("$fh", qr{^cfg_file\s*=\s*$c$}m, "Non-existing files don't get printed");

