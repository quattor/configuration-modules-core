# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Systemctl;

use 5.10.1;
use strict;
use warnings;

use parent qw(Exporter);
use Readonly;

use LC::Exception qw (SUCCESS);

Readonly our $SYSTEMCTL => "/usr/bin/systemctl";
Readonly my $DAEMON_RELOAD => 'daemon-reload';

# Unit properties
Readonly our $PROPERTY_ACTIVESTATE => 'ActiveState';
Readonly our $PROPERTY_AFTER => 'After';
Readonly our $PROPERTY_BEFORE => 'Before';
Readonly our $PROPERTY_CONFLICTS => 'Conflicts';
Readonly our $PROPERTY_ID => 'Id';
Readonly our $PROPERTY_NAMES => 'Names';
Readonly our $PROPERTY_REQUIREDBY => 'RequiredBy';
Readonly our $PROPERTY_REQUIRES => 'Requires';
Readonly our $PROPERTY_TRIGGEREDBY => 'TriggeredBy';
Readonly our $PROPERTY_TRIGGERS => 'Triggers';
Readonly our $PROPERTY_WANTEDBY => 'WantedBy';
Readonly our $PROPERTY_WANTS => 'Wants';
Readonly our $PROPERTY_UNITFILESTATE => 'UnitFileState';

Readonly::Array my @PROPERTIES => qw(
    $PROPERTY_ACTIVESTATE $PROPERTY_AFTER $PROPERTY_BEFORE
    $PROPERTY_CONFLICTS $PROPERTY_ID $PROPERTY_NAMES
    $PROPERTY_REQUIREDBY  $PROPERTY_REQUIRES
    $PROPERTY_TRIGGEREDBY $PROPERTY_TRIGGERS
    $PROPERTY_UNITFILESTATE $PROPERTY_WANTEDBY
    $PROPERTY_WANTS
);

# These properties are converted in an array reference with systemctl_show method
Readonly::Array my @PROPERTIES_ARRAY => (
    $PROPERTY_AFTER, $PROPERTY_BEFORE, $PROPERTY_CONFLICTS,
    $PROPERTY_NAMES, $PROPERTY_REQUIRES, $PROPERTY_REQUIREDBY,
    $PROPERTY_TRIGGEREDBY, $PROPERTY_TRIGGERS,
    $PROPERTY_WANTEDBY, $PROPERTY_WANTS,
);

our @EXPORT_OK = qw(
    $SYSTEMCTL
    systemctl_show
    systemctl_daemon_reload
    systemctl_list_units systemctl_list_unit_files
    systemctl_list_deps
    systemctl_command_units systemctl_is_enabled
);

push @EXPORT_OK, @PROPERTIES;

our %EXPORT_TAGS = (
    properties => \@PROPERTIES,
);


#
# Reminder: units can start with a '-',
#   so add '--' before processing the unit on the commandline.
#

=pod

=head1 NAME

NCM::Component::Systemd::Systemctl handle all systemd
interaction via C<systemctl> command.

=head2 Public methods

=over

=item systemctl_show

C<logger> is a mandatory logger to pass.

Run C<systemctl show> on single C<$unit> and return parsed output.
If C<$unit> is undef, the manager itself is shown.

Optional arguments:

=over

=item no_error

Report a failure with C<systemctl show> with C<verbose> level.
If nothing is specified, an C<error> is reported.

=back

If succesful, returns a hashreference interpreting the C<key=value> output.
Following keys have the value split on whitespace and a array reference
to the result as output

=over

=item After
=item Before
=item Conflicts
=item Names
=item RequiredBy
=item Requires
=item TriggeredBy
=item Triggers
=item WantedBy
=item Wants

=back

Returns undef on failure.

=cut

sub systemctl_show
{
    my ($logger, $unit, %opts) = @_;
    my $proc = CAF::Process->new([$SYSTEMCTL, "--no-pager", "--all", "show"],
                                  log => $logger,
                                  keeps_state => 1,
                                  );
    if (defined($unit)) {
        $proc->pushargs('--', $unit);
        $logger->debug(2, "systemctl_show for name $unit");
    } else {
        $logger->debug(2, "systemctl_show for manager itself, name undefined");
    }

    my $output = $proc->output();
    my $ec = $?;
    if ($ec) {
        my $msg = "systemctl show failed (cmd $proc; ec $ec)";
        $msg .= " with output $output" if (defined($output));

        my $reporter = $opts{no_error} ? 'verbose' : 'error';

        $logger->$reporter($msg);
        return;
    }

    # output is k=[v]
    # some keys will be split on whitespace
    #  - when extending this list, update the pod!
    my $res = {};
    while($output =~ m/^([^=\s]+)\s*=(.*)?$/mg) {
        my ($k,$v) = ($1,"$2");
        if (grep {$_ eq $k} @PROPERTIES_ARRAY) {
            my @values = split(/\s+/, $v);
            $res->{$k} = \@values;
        } else {
            $res->{$k} = $v;
        }
    }

    return $res;
}

=pod

=item systemctl_daemon_reload

C<logger> is a mandatory logger to pass.

Reload systemd manager configuration (e.g. when units have been modified).

Returns undef on failure, SUCCESS otherwise.

=cut

sub systemctl_daemon_reload
{
    my ($logger) = @_;

    my $output = CAF::Process->new(
        [$SYSTEMCTL, $DAEMON_RELOAD],
        log => $logger,
        )->output();

    my $ec = $?;
    if ($ec) {
        $logger->error("$SYSTEMCTL $DAEMON_RELOAD failed ec $ec (output $output)");
        return;
    } elsif ($output) {
        # Really odd
        $logger->warn("$SYSTEMCTL $DAEMON_RELOAD returned output while success: $output.",
                    " (This is unexpected, contact developers)");
    }

    return SUCCESS;
}

=pod

=item systemctl_list_units

C<logger> is a mandatory logger to pass.

Return a hashreference with all units and their details for C<type>.
C<type> is passed to the C<systemctl_list> method.

=cut

sub systemctl_list_units
{
    my ($logger, $type) = @_;

    my $regexp = qr{^(?<name>(?<shortname>\S+)\.(?<type>\w+))\s+(?<loaded>\S+)\s+(?<active>\S+)\s+(?<running>\S+)(?:\s+|$)};
    return systemctl_list($logger, "units", $regexp, $type);
}

=pod

=item systemctl_list_unit_files

C<logger> is a mandatory logger to pass.

Return a hashreference with all unit-files and their details for C<type>.
C<type> is passed to the C<systemctl_list> method.

=cut

sub systemctl_list_unit_files
{
    my ($logger, $type) = @_;

    my $regexp = qr{^(?<name>(?<shortname>\S+)\.(?<type>\w+))\s+(?<state>\S+)(?:\s+|$)};
    return systemctl_list($logger, "unit-files", $regexp, $type);
}

=pod

=item systemctl_list_deps

C<logger> is a mandatory logger to pass.

Return a hashreference with all dependencies
(i.e. required and wanted units) of the specified C<unit>
flattened. (This includes the unit itself).

If C<reverse> is set to true (default is false), it returns
 the revese dependencies (i.e. units with dependencies of
 type Wants or Requires on the given unit).

The keys are the full unit names, values are 1. (A hash is used
to allow easy lookup, instead of a list).

The flattening is done via the C<--plain> option of systemctl,
the reverse result via the C<--reverse> option. Both options
are available since systemd-208 (which is in e.g. EL7).

=cut

sub systemctl_list_deps
{
    my ($logger, $unit, $reverse) = @_;

    # no --all !
    my $proc = CAF::Process->new(
        [$SYSTEMCTL, '--no-pager', '--no-legend', '--full', '--plain', 'list-dependencies'],
        log => $logger,
        keeps_state => 1,
        );

    my $deptxt = "dependencies";
    if($reverse) {
        $deptxt = "reverse $deptxt";
        $proc->pushargs("--reverse");
    };

    $proc->pushargs('--', $unit);

    $logger->debug(2, "Looking for $deptxt of unit $unit.");

    my $data = $proc->output();
    my $ec = $?;
    if ($ec) {
        $logger->error("Failed to list dependencies of unit $unit: command $proc ec $ec ($data)");
        return;
    }

    my $res = {};
    foreach my $line (split(/\n/, $data)) {
        if ($line =~ m/^\s*(\S+)\s*$/) {
            $res->{$1} = 1
        }
    };

    return $res;
}

=pod

=item systemctl_command_units

Run the systemctl C<command> for C<units>.

An error is logged when the exitcode is non-zero.

Returns exitcode and output.

=cut

# C<keeps_state> is not set while running the actual command,
# so nothing will be done here under C<NoAction>;
# but you should use C<systemctl_show> and C<systemctl_list_deps>
# to retrieve information about units.
# TODO: Support whitelist of "safe" commands to run with keeps_state?
sub systemctl_command_units
{
    my ($logger, $command, @units) = @_;

    # TODO: any relevant options?
    my $proc = CAF::Process->new(
        [$SYSTEMCTL, $command],
        log => $logger,
        );

    if (@units) {
        $proc->pushargs('--', @units);
    }

    my $data = $proc->output();
    my $ec = $?;

    my $msg = "systemctl_command_units $proc returned ec $ec and output $data";
    if ($ec) {
        $logger->error($msg);
    } else {
        $logger->debug(2, $msg);
    }
    return $ec, $data;
}

=pod

=item systemctl_is_enabled

Run C<systemctl is-enabled> for C<unit>.

Returns output without trailing newlines on success.
An error is logged and undef returned when the exitcode is non-zero.

=cut

sub systemctl_is_enabled
{
    my ($logger, $unit) = @_;

    # Gather stderr separately (e.g. to handle legacy services)
    my ($stdout, $stderr) = ('', '');
    my $proc = CAF::Process->new(
        [$SYSTEMCTL, 'is-enabled', '--', $unit],
        log => $logger,
        keeps_state => 1,
        stdout => \$stdout,
        stderr => \$stderr,
        );

    $proc->execute();
    chomp($stdout);
    chomp($stderr);

    my $ec = $?;

    my $msg = "systemctl_command_units $proc returned ec $ec and stdout $stdout stderr $stderr";
    # Do not test on $ec; if unit is disabled, it is-enabled also returns ec > 0
    # If there's a real issue, like unknown unit, there is no stdout.
    if ($stdout) {
        $logger->debug(2, $msg);
        return $stdout;
    } else {
        $logger->error($msg);
        return;
    }
}



=pod

=back

=head2 Private methods

=over

=item systemctl_list

Helper method to generate and parse output from C<systemctl list-...> commands like
C<list-units> or C<list-unit-files>.

C<logger> is a mandatory logger to pass.

C<spec> is translated in the C<list-<spec>> command, C<regexp> is the named
regular expression that is used to match the output.

C<type> is the type filter (if defined).

The regexp must have a C<name> named group, its value is used for the keys of the
hashref that is returned.
Output that does not match the regexp is skipped, if the regexp matches but
there is no C<name> value in the named group, it is also skipped and
logged as error.

=cut

sub systemctl_list
{
    my ($logger, $spec, $regexp, $type) = @_;
    my $proc = CAF::Process->new(
        [$SYSTEMCTL, '--all', '--no-pager', '--no-legend', '--full'],
        log => $logger,
        keeps_state => 1,
        );

    if($spec =~ m/^([\w-]+)$/) {
        $proc->pushargs("list-$1");
    } else {
        $logger->error("Spec $spec has invalid characters.");
        return;
    }

    my $typmsg="";
    if($type) {
        $proc->pushargs("--type", $type);
        $typmsg=" for type $type";
    }

    my $data = $proc->output();
    my $ec = $?;

    if ($ec) {
        $logger->error(
            "Cannot get list of current $spec$typmsg from $SYSTEMCTL: ec $ec ($data)");
        return;
    }

    my $res = {};
    foreach my $line (split(/\n/, $data)) {
        if ($line !~ m/$regexp/) {
            $logger->debug(1, "Ouptut from $proc does not match pattern $regexp: $line");
            next;
        };

        if(! defined($+{name})) {
            $logger->error("No matched group 'name'. Skipping line $line");
            next;
        }
        # make a hashref-copy of the magic regexp match hash
        $res->{$+{name}} = { %+ };
    };

    return $res;
}

=pod

=back

=cut

1;
