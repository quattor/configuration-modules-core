#${PMpre} NCM::Component::FreeIPA::User${PMpost}

use Readonly;

=head1 NAME

NCM::Component::FreeIPA::User adds host related methods to
L<NCM::Component::FreeIPA::Client>.

=head2 Public methods

=over

=item add_user

Add a user. If the user already exists, return undef.

=over

=item Arguments

=over

=item uid: User uid

=back

=item Options (passed to C<Net::FreeIPA::API::api_user_add>).

=over

=item homedirectory

=item gecos

=item loginshell

=item uidnumber

=item gidnumber

=item ipasshpubkey

=back

=back

=cut

sub add_user
{
    my ($self, $uid, %opts) = @_;

    return $self->do_one('user', 'add', $uid, %opts);
}

=item disable_user

Disable a user with C<uid>.

=cut

sub disable_user
{
    my ($self, $uid) = @_;

    return $self->do_one('user', 'disable', $uid);
}

=item remove_user

Remove the user C<uid>  (preserve=1).

=cut

sub remove_user
{
    my ($self, $uid) = @_;

    return $self->do_one('user', 'del', [$uid], preserve => 1);
}

=item user_passwd

Reset and return a new random password for user C<uid>.
Returns undef if the user doesn't exist.

=cut

sub user_passwd
{
    my ($self, $uid) = @_;

    return $self->do_one('user', 'mod', $uid, random => 1, __result_path => 'result/result/randompassword');
}

=pod

=back

=cut


1;
