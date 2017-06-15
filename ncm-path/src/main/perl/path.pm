#${PMcomponent}

=head1 DESCRIPTION

C<ncm-path> handles interaction with files, directories, links, ...
using C<CAF::Path>.

=cut

use parent qw(NCM::Component CAF::Path);

sub Configure
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix());

    1;
}

1;
