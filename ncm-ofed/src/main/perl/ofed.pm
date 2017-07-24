#${PMcomponent}

=head1 NAME

NCM::Component::ofed - OFED configuration component

=cut

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::TextRender;
use Readonly;

Readonly my $OPENIB_CONF_TT => 'openib_conf';
Readonly my $PARTITIONS_CONF_TT => 'partitions';
Readonly my $NAMES_CONF_TT => 'names';

Readonly my $PARTITIONS_FILENAME => '/etc/opensm/partitions.conf';
Readonly my $NAMES_FILENAME => '/etc/opensm/ib-node-name-map';

sub _render
{
    my ($self, $element, $tt, $cfg_fn) = @_;

    my $cfg_trd = EDG::WP4::CCM::TextRender->new($tt,
                                                 $element,
                                                 relpath => 'ofed',
                                                 log => $self);

    my $cfg_fh = $cfg_trd->filewriter($cfg_fn, log => $self, backup => ".old", mode => oct(644));
    if(! defined($cfg_fh)) {
        $self->error("Failed to render $cfg_fn: $cfg_trd->{fail}");
        return;
    } else {
        return $cfg_fh->close();
    }
}

sub openib
{
    my ($self, $config) = @_;

    # write the openib config file (mandatory in schema)
    my $cfg_fn = $config->getValue($self->prefix() . "/openib/config");
    my $res = $self->_render($config->getElement($self->prefix().'/openib'),
                             $OPENIB_CONF_TT,
                             $cfg_fn);

    if ($res) {
        $self->verbose("ofed openib $cfg_fn modified, but openibd service not restarted (not yet supported by component)");
        # TODO: support restart, but investigate impact first
        # CAF::Service->new(['openibd'], log => $self)->restart();
    }
}

sub opensm
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix() . "/opensm");
    my $changed = 0;

    if ($tree->{partitions}) {
        $changed += $self->_render(
            $config->getElement($self->prefix().'/opensm/partitions'),
            $PARTITIONS_CONF_TT,
            $PARTITIONS_FILENAME
        ) || 0;
    }

    if ($tree->{names}) {
        $changed += $self->_render(
            $config->getElement($self->prefix().'/opensm/names'),
            $NAMES_CONF_TT,
            $NAMES_FILENAME
        ) || 0;
    }

    if ($changed) {
        CAF::Service->new($tree->{daemons}, log => $self)->restart();
    }
}

sub Configure
{

    my ($self, $config) = @_;

    $self->openib($config);
    $self->opensm($config);

    # TODO: opensm support

    return 1;
}

1;
