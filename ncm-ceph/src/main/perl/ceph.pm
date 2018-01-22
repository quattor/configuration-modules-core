#${PMpre} NCM::Component::ceph${PMpost}
#
use parent qw(NCM::Component);
our $NoActionSupported = 1;

our $EC=LC::Exception::Context->new->will_store_all;
use Readonly;
Readonly our $REDIRECT => {
    name => 'release',
    default => 'Luminous',
};

1; # required for Perl modules
