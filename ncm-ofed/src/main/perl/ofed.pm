#${PMcomponent}

=head1 NAME

NCM::Component::ofed - OFED configuration component

=cut

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::TextRender;
use Readonly;

Readonly my $OPENIB_CONF_TT => 'openib_conf';

sub openib
{
    my ($self, $config) = @_;

    # write the openib config file (mandatory in schema)
    my $cfg_fn = $config->getValue($self->prefix() . "/openib/config");

    my $cfg_trd = EDG::WP4::CCM::TextRender->new($OPENIB_CONF_TT,
                                             $config->getElement($self->prefix().'/openib'),
                                             relpath => 'ofed',
                                             log => $self);

    my $cfg_fh = $cfg_trd->filewriter($cfg_fn, log => $self, backup => ".old", mode => oct(644));
    if(! defined($cfg_fh)) {
        $self->error("Failed to render $cfg_fn: $cfg_trd->{fail}");
    } else {
        if($cfg_fh->close()) {
            $self->verbose("ofed openib $cfg_fn modified, but openibd service not restarted (not yet supported by component)");
            # TODO: support restart, but investigate impact first
            # CAF::Service->new(['openibd'], log => $self)->restart();
        }
    }
}

sub Configure
{

    my ($self, $config) = @_;

    $self->openib($config);

    # TODO: opensm support

    return 1;
}

1;
