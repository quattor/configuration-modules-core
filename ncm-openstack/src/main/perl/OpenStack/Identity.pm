#${PMpre} NCM::Component::OpenStack::Identity${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use NCM::Component::OpenStack::Client qw(get_client);
# For now, only support identity v3
# TODO: add check
use Net::OpenStack::Client::Identity::v3;

use Readonly;
Readonly my $MANAGED_BY => '(mgt QUATTOR)';

my $filter = sub {
    my $pattern = quotemeta($MANAGED_BY);
    return ($_[0]->{description} || '') =~ m/$pattern$/;
};

=head2 Methods

=over

=item run_client

Configure identity service related items such as region, endpoint ...

=cut

sub run_client
{
    my ($self) = @_;

    my $client = get_client() or return;

    my @order = (@Net::OpenStack::Client::Identity::v3::SUPPORTED_OPERATIONS);

    # Loop through all configuration in order
    foreach my $oper (@order) {
        next if !exists($self->{comptree}->{identity}->{$oper});

        # fecth the cfg data, using json data typing
        my $cfg = $self->_get_json_tree("identity/$oper");

        # augment the description with $MANAGED_BY
        foreach my $name (sort keys %$cfg) {
            $cfg->{$name}->{description} .= " $MANAGED_BY"
                if exists($cfg->{$name}->{description});
        }

        # apply the changes using sync
        $client->api_identity_sync($oper, $cfg, filter => $filter);
    }

    return 1;
}

=pod

=back

=cut

1;
