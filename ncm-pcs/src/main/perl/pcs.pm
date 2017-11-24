#${PMcomponent}

use parent qw(NCM::Component CAF::Path);
use CAF::Object qw(SUCCESS);
use LC::Exception;

use Readonly;

Readonly my $TOKENS => '/var/lib/pcsd/tokens';

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

# return short hostname(s) from all arguments
# if first arg is arrayref, use all elements in that first arg
sub _short
{
    return map {[split(/\./, $_, 2)]->[0]} (ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_);
}

=head1 NAME

ncm-${project.artifactId}: Configuration module for Cororsync/Pacemaker using pcs

=head1 DESCRIPTION

ncm-${project.artifactId}: Configuration module for Cororsync/Pacemaker using pcs

The main intend is not to provide full configuration (there's no real API to make it possible),
but rather to help setting up a corosync+pacemaker cluster using pcs, following guide from
L<http://clusterlabs.org/doc/en-US/Pacemaker/1.1-pcs/html/Clusters_from_Scratch/index.html>.

The component assumes you have a C<hacluster> user with password to setup the authentication.

=head2 Methods

=over

=item _pcs

Run C<pcs> with arguments arrayref C<args>, report C<msg>.

Returns tuple C<ok>, C<output> when called in array context (just C<ok> otherwise).

Options

=over

=item test: the command is a test, no error will be reported on failure

=back

=cut

sub _pcs
{
    my ($self, $args, $msg, %opts) = @_;

    my $proc = CAF::Process->new(
        ['pcs', @$args],
        log => $self,
        sensitive => $opts{sensitive}
        );
    my $output = $proc->output();
    chomp($output);

    my $ok = $? ? 0 : 1;
    my $report = ($opts{test} || $ok) ? 'verbose' : 'error';

    my $fmsg = "$msg";
    $fmsg .= " as user $opts{user}" if (exists $opts{user});
    $fmsg .= " output: $output" if ($output && !$opts{sensitive});

    $self->$report($ok ? ucfirst($fmsg) : "Failed to $fmsg");

    return wantarray ? ($ok, $output) : $ok;
}

=item has_tokens

Check if the authentication tokens are available.
If not, report error with instructions to make them
and return undef;

=cut

sub has_tokens
{
    my ($self, $nodes) = @_;

    if ($self->file_exists($TOKENS)) {
        $self->verbose("Found tokens $TOKENS");
    } else {
        $self->error("No tokens $TOKENS found. ",
                     "Create them with command \"",
                     "pcs cluster auth ", join(" ", _short $nodes),
                     " -u hacluster -p 'haclusterpassword'\"");
        return;
    }
    return SUCCESS;
}

=item setup

Setup the cluster if none is running.
This does not yet take care of adding/removing nodes.
Return undef on failure.

=cut

sub setup
{
    my ($self, $cluster) = @_;

    if (!$self->_pcs(['cluster', 'status'], "find running cluster", test => 1)) {
        $self->info("No running cluster, setting up cluster");
        $self->_pcs(['cluster', 'setup',
                     '--name', $cluster->{name},
                     _short $cluster->{nodes}
                    ], "setup cluster") or return;
    }

    return SUCCESS;
}

=item Configure

component Configure method

=cut

sub Configure
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix);

    # Test auth files, if not present error with commandline
    $self->has_tokens($tree->{cluster}->{nodes}) or return;

    $self->setup($tree->{cluster}) or return;

    # Test cluster status, it none is found, setup cluster with main/first node
    # --> how to reinstall 1st node: well, make other node first node first


    return 1;
}

=pod

=back

=cut

1;
