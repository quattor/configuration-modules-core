#${PMpre} NCM::Component::Systemd::Service::Component::chkconfig${PMpost}

use parent qw(NCM::Component::${project.artifactId});

our $EC = LC::Exception::Context->new->will_store_all;
# Force namespace
$NCM::Component::${project.artifactId}::NoActionSupported = 1;

=head2 Methods

=over

=item _set_name

Set and return name to use for prefix to get the the standard configuration path
for the systemd component C<</software/components/systemd>>
(not the C<chkconfig> one through inheritance).

This allows for easier subclassing, but is not safe for component aliasing.

=cut

sub _set_name
{
    my ($self) = @_;
    $self->{NAME} = 'systemd';
    return $self->{NAME};
}

=item _initialize

Modify the inheritance to set the C<NAME> attribute via C<_set_name> method.

=cut

sub _initialize
{
    my ($self) = shift;

    my $res = $self->SUPER::_initialize(@_);
    $self->_set_name();
    return $res;
}


=item skip

Skip all but service configuration.

=cut

sub skip
{
    my ($self, $config) = @_;
    my $skip = $self->SUPER::skip($config);

    # force override
    foreach my $name (keys %$skip) {
        $skip->{$name} = ($name eq "service") ? 0 : 1;
    }
    return $skip
}

=pod

=back

=cut

1; #required for Perl modules
