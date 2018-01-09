#${PMpre} NCM::Component::ceph${PMpost}
#
our $EC=LC::Exception::Context->new->will_store_all;
use parent qw(NCM::Component);
our $NoActionSupported = 1;

sub Configure
{
    my ($self, $config) = @_;
    return $self->call_entry_point("Configure", $config);
}

sub Unconfigure
{
    my ($self, $config) = @_;
    return $self->call_entry_point("Unconfigure", $config);
}

sub call_entry_point
{
    my ($self, $entry_point, $config) = @_;
    my $t = $config->getElement($self->prefix())->getTree();

    my $release;
    if (defined($t->{release})) {
        $release = $t->{release};
    } else {
        $release = 'luminous';
    }

    my $submod = "NCM::Component::Ceph::$release";
    eval "use $submod";
    if ($@) {
        $self->error("Failed to load $submod: $@");
        return undef;
    }

    # No idea what this noaction stuff does, see spma.pm
    my $NoAction = $self->{NoAction};
    bless($self, "$submod");
    $self->{NoAction} = $NoAction;
    return $self->$entry_point($config);
}

1; # required for Perl modules
