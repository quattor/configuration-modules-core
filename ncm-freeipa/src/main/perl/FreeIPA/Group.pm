#${PMpre} NCM::Component::FreeIPA::Group${PMpost}

use Readonly;

=head1 NAME

NCM::Component::FreeIPA::Group adds group related methods to
L<NCM::Component::FreeIPA::Client>.

=head2 Public methods

=over

=item add_group

Add a group with name C<gid>.

=over

=item Arguments

=over

=item gid: group gid

=back

=item Options (passed to C<Net::FreeIPA::API::api_group_add>).

=over

=item gidnumber

=back

=back

=cut

sub add_group
{
    my ($self, $gid, %opts) = @_;

    return $self->do_one('group', 'add', $gid, %opts);
};

=item add_group_member

Add the members to group C<gid> using options
(options are passed to C<api_group_add_member>).

=cut

sub add_group_member
{
    my ($self, $gid, %opts) = @_;

    return $self->do_one('group', 'add_member', $gid, %opts);
};

=pod

=back

=cut


1;
