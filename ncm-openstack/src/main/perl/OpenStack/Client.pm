#${PMpre} NCM::Component::OpenStack::Client${PMpost}

=head1 NAME

C<NCM::Component::OpenStack::Client> provides simple functions to get
the REST client.

=head1 Functions

=over

=cut

use NCM::Component::OpenStack::Logger;
use NCM::Component::OpenStack::Openrc;
use Net::OpenStack::Client;
use Readonly;

use parent qw(Exporter);

our @EXPORT_OK = qw(set_logger get_client);

# API logging from debuglevel 3
Readonly my $DEBUGAPI_LEVEL => 3;

# CAF::Reporter instance as logger
#   typcially the component instance
my $_logger;

# Client instance
my $_client;

=item set_logger

Set and return the logger instance to use.

=cut

sub set_logger
{
    $_logger = shift;
    return $_logger;
}

=item get_client

Get the client instance.

It creates one if none existed before using the Openrc Service filename.

=cut

sub get_client
{
    if (!defined($_client)) {
        my $dbglvl = $_logger->{LOGGER} ? $_logger->{LOGGER}->get_debuglevel() : 0;
        $_client = Net::OpenStack::Client->new(
            log => NCM::Component::OpenStack::Logger->new($_logger),
            debugapi => $dbglvl >= $DEBUGAPI_LEVEL,
            openrc => $NCM::Component::OpenStack::Openrc::CONFIG_FILE,
            );
    }

    return $_client;
}

=pod

=back

=cut

1;
