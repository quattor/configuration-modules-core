#${PMpre} NCM::Component::OpenStack::Identity${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use NCM::Component::OpenStack::Client qw(get_client);
# For now, only support identity v3
# TODO: add check
use Net::OpenStack::Client::Identity::v3;

use Readonly;
Readonly my $TAGSTORE => 'quattorstore';
Readonly my $API_SYNC => 'api_identity_sync';

=head2 Methods

=over

=item run_client

Configure identity service related items such as region, endpoint ...

=cut

sub run_client
{
    my ($self) = @_;

    my $client = get_client() or return;

    if (!exists($self->{comptree}->{identity}->{client})) {
        $self->verbose("no identity client configuration, nothing to do");
        return 1;
    }

    my @order = (@Net::OpenStack::Client::Identity::v3::SUPPORTED_OPERATIONS);

    # Loop through all configuration in order
    foreach my $oper (@order) {
        next if !exists($self->{comptree}->{identity}->{client}->{$oper});

        # fecth the cfg data, using json data typing
        my $cfg = $self->_get_json_tree("identity/client/$oper");

        # apply the changes using sync
        # cannot use ->can to test, since there's autoload magic in the client
        if (grep {$oper eq $_} qw(rolemap)) {
            my $method = "${API_SYNC}_$oper";
            $self->verbose("identity client sync for $oper using $method");
            # no need to pass oper; it's a unique method per operation
            $client->$method($cfg, tagstore => $TAGSTORE);
        } else{
            $self->debug(1, "identity client sync for $oper using $API_SYNC");
            $client->$API_SYNC($oper, $cfg, tagstore => $TAGSTORE);
        }
    }

    return 1;
}

=pod

=back

=cut

1;
