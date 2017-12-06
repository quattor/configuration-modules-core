use strict;
use warnings;

my $newline;
BEGIN {
    # \R generic newline is new in 5.10;
    # use \n or \r in older versions
    $newline = $] < 5.010000 ? '[\n\r]' : '\R';
}

use Test::More;
use Test::Quattor qw(aii-options);
use NCM::Component::aiiserver;
use CAF::Object;
use Readonly;



=pod

=head1 SYNOPSIS

Basic test for C<ncm-aiiserver>

=cut

Readonly my @CONFIG_PARTS => qw(shellfe dhcp);
Readonly my %CONFIG_ROOTS => (shellfe => '/software/components/aiiserver/aii-shellfe',
                             dhcp => '/software/components/aiiserver/aii-dhcp');
Readonly my %CONFIG_FILES => (shellfe => '/etc/aii/aii-shellfe.conf',
                              dhcp => '/etc/aii/aii-dhcp.conf');

$CAF::Object::NoAction = 1;

my $comp = NCM::Component::aiiserver->new('ncm-aiiserver');
my $cfg = get_config_for_profile('aii-options');
$comp->Configure($cfg);

for my $part (@CONFIG_PARTS) {
    my $part_config = $cfg->getElement($CONFIG_ROOTS{$part})->getTree();
    my $config_file = $CONFIG_FILES{$part};

    # Be sure to do the same has the components in term of ordering
    # A regexp is used to avoid failing the test if the comment in the header.
    # lines are changing. Apart from that, require exactly what the component
    # produces.
    my $expected_contents = '^#.*'.$newline.'#.*'.$newline;
    for my $key (sort keys%$part_config) {
        $expected_contents .= $key . ' = ' . $part_config->{$key} . $newline;
    }
    $expected_contents .= '$';

    my $fh = get_file($config_file);
    like("$fh", qr{$expected_contents}m, "File $config_file has expected contents");
}

done_testing();
