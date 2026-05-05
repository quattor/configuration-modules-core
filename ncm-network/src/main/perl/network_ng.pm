#${PMpre} NCM::Component::network_ng${PMpost}

use parent qw (NCM::Component::network);

sub disable_networkmanager
{
    my ($self, $allow) = @_;
    # do nothing
};


1;
