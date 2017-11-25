#${PMcomponent}

use parent qw(NCM::Component CAF::Path);
use CAF::Object qw(SUCCESS);
use LC::Exception;

use Readonly;
use Set::Scalar;

Readonly my $TOKENS => '/var/lib/pcsd/tokens';

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

# return short hostname(s) from all arguments
# if first arg is arrayref, use all elements in that first arg
sub _short
{
    return map {[split(/\./, $_, 2)]->[0]} (ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_);
}

# convert value from _parse
# supported options
#    array: convert all values in arrayref
#    set: convert all values to Set::Scalar
sub _value
{
    my ($val, %opts) = @_;

    my $res = $val;
    if ($opts{array} || $opts{set}) {
        $res = defined($val) ? [split(/\s+/, $val)] : [];
        $res = Set::Scalar->new(@$res) if $opts{set};
    }
    return $res;
}

# parse pcs output in a hashref
# nested structure, based on indentation
# options relevant here (i.e. not for _value):
#    lower: all keys lowercase
# %opts also passed to _value
sub _parse
{
    my ($txt, %opts) = @_;

    my $res = {};
    # depth -> hashref
    my $curr = {0 => $res};
    my $prevdepth = 0;
    # not relevant, first line should always be depth=0;
    #   so no depth>prevdepth, and thus prevkey is something meaningful
    my $prevkey = 'INVALID';

    foreach my $line (split(/\n/, $txt)) {
        if ($line =~ m/^(\s*)(\S.*?)\s*:\s*(\S.*?)?\s*$/) {
            my $key = $opts{lower} ? lc($2) : $2;
            my $depth = length($1);

            if ($depth > $prevdepth) {
                $curr->{$prevdepth}->{$prevkey} = {};
                $curr->{$depth} = $curr->{$prevdepth}->{$prevkey};
            }
            $curr->{$depth}->{$key} = _value($3, %opts);

            $prevdepth = $depth;
            $prevkey = $key;
        }
    }

    return $res;
}

=head1 NAME

ncm-${project.artifactId}: Configuration module for Cororsync/Pacemaker using pcs

=head1 DESCRIPTION

ncm-${project.artifactId}: Configuration module for Cororsync/Pacemaker using pcs

The main intend is not to provide full configuration (there's no real API to make it possible),
but rather to help setting up a corosync+pacemaker cluster using pcs, following guide from
L<http://clusterlabs.org/doc/en-US/Pacemaker/1.1-pcs/html/Clusters_from_Scratch/index.html>.

The component assumes you have a C<hacluster> user with password to setup the authentication.

All nodes are (expected to be) configured using short hostnames.

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

    # only start the cluster on the configured nodes
    my $start = sub {
        return $self->_pcs(['cluster', 'start',
                            _short $cluster->{nodes}
                           ], "start cluster@_", test => 1);
    };

    my $status = sub {
        return $self->_pcs(['cluster', 'status'], "find running cluster@_", test => 1);
    };

    if (!&$status('')) {
        $self->info("No running cluster, try to start cluster");
        &$start('');

        if (!&$status(' after start')) {
            $self->info("Still no running cluster, setting up cluster");
            $self->_pcs(['cluster', 'setup',
                         '--name', $cluster->{name},
                         _short $cluster->{nodes}
                        ], "setup cluster") or return;
            &$start(' after cluster setup');
            if (!&$status(' after setup and start')) {
                $self->error("Still not running cluster after setup and start");
                return;
            }
        }
    }

    return SUCCESS;
}

=item nodes

Get nodes status, and compare with to be configured nodes.
If any node is missing, unknown nodes are encountered or
nodes are not optimal: report and error and return undef.

Only when the pacemaker and corosync nodes are the configured nodes,
and all others are empty, will the method return success.

=cut

sub nodes
{
    my ($self, $nodes_array) = @_;

    # use set scalar for comparing
    my $nodes = Set::Scalar->new(_short $nodes_array);

    # reports error on failure
    my ($ok, $output) = $self->_pcs([qw(status nodes both)], "show nodes status");
    return if ! $ok;

    my $states = _parse($output, set => 1, lower => 1);
    my $expected = 0;
    foreach my $type (sort keys %$states) {
        my $state = $states->{$type};
        $type =~ s/\s+nodes?//;
        foreach my $val_name (sort keys %$state) {
            my $val = $state->{$val_name};
            if (($type eq 'corosync' or $type eq 'pacemaker') &&
                $val_name eq 'online') {
                # do not use != logic (is false if there's overlap in sets)
                if ($val == $nodes) {
                    $expected += 1;
                } else {
                    $self->error("Found $type $val_name nodes ($val) ",
                                 "not equal to configured nodes ($nodes)");
                    return;
                }
            } else {
                if (!$val->is_null) {
                    $self->error("Found non-empty $type $val_name nodes ($val)");
                    return;
                }
            }
        }
    }
    return $expected == 2 ? SUCCESS : undef;
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

    # Test cluster status, it none is found, setup cluster with main/first node
    # --> how to reinstall 1st node: well, make other node first node first
    $self->setup($tree->{cluster}) or return;

    # Check nodes
    $self->nodes($tree->{cluster}->{nodes}) or return;

    return 1;
}

=pod

=back

=cut

1;
