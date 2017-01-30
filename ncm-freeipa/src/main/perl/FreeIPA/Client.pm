#${PMpre} NCM::Component::FreeIPA::Client${PMpost}

use parent qw(Net::FreeIPA
              NCM::Component::FreeIPA::Host
              NCM::Component::FreeIPA::DNS
              NCM::Component::FreeIPA::User
              NCM::Component::FreeIPA::Group
              NCM::Component::FreeIPA::Cert
              NCM::Component::FreeIPA::Service);

use Net::FreeIPA 3.0.2;

use NCM::Component::FreeIPA::Logger;

use Readonly;

=head1 NAME

NCM::Component::FreeIPA::Client is a perl FreeIPA JSON API client
class for Quattor

=head2 Private methods

=over

=item _initialize

Handle the actual initializtion of new. Return 1 on success, undef otherwise.

=over

=item log

An C<CAF::Reporter> instance that can be used for logging
(it is converted in a logger appropriate for C<Net::FreeIPA>).

=back

All other arguments and options are passed to L<Net::FreeIPA>
during initialisation.

=cut

sub _initialize
{
    my ($self, $hostname, %opts) = @_;

    if ($opts{log}) {
        # debug method from C<CAF::Reporter> interprets first argument as debug level
        $opts{log} = NCM::Component::FreeIPA::Logger->new($opts{log});
    }

    return $self->SUPER::_initialize($hostname, %opts);
}

=pod

=back

=cut


1;
