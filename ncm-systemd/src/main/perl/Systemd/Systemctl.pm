# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Systemctl;

use 5.10.1;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(systemctl_show $SYSTEMCTL systemctl_list_units systemctl_list_unit_files);

use Readonly;

Readonly our $SYSTEMCTL => "/usr/bin/systemctl";


=pod

=head1 NAME

NCM::Component::Systemd::Systemctl handle all systemd 
interaction via C<systemctl> command.

=head2 Public methods

=over

=item systemctl_show

C<logger> is a mandatory logger to pass.

Run C<systemctl show> on single C<$name> and return parsed output.
If C<$name> is undef, the manager itself is shown.

If succesful, returns a hashreference interpreting the C<key=value> output.
Following keys have the value split on whitespace and a array reference 
to the result as output

=over
=item Names
=item Requires
=item Wants
=item WantedBy
=item Before
=item After
=item Conflicts
=back

Returns undef on failure. 

=cut

sub systemctl_show
{
    my ($logger, $name) = @_;
    my $proc = CAF::Process->new([$SYSTEMCTL, "--no-pager", "--all", "show"],
                                  log => $logger,
                                  );
    if (defined($name)) {
        $proc->pushargs($name);
        $logger->verbose("systemctl_show for name $name");
    } else {
        $logger->verbose("systemctl_show for manager itself, name undefined");
    }

    my $output = $proc->output();
    my $ec = $?;
    if($ec) {
        my $msg = "systemctl show failed (cmd $proc; ec $ec)";
        $msg .= " with output $output" if (defined($output));
        $logger->error($msg);
        return;
    }
    
    # output is k=[v]
    # some keys will be split on whitespace
    #  - when extending this list, update the pod!
    my @isarray = qw(Names Requires Wants WantedBy Before After Conflicts);
    my $res={};
    while($output =~ m/^([^=\s]+)\s*=(.*)?$/mg) {
        my ($k,$v) = ($1,"$2");
        if (grep {$_ eq $k} @isarray) {
            my @values = split(/\s+/, $v);
            $res->{$k} = \@values;
        } else {
            $res->{$k} = $v;
        }
    }
    
    return $res;    
}

=pod

=item systemctl_list_units

C<logger> is a mandatory logger to pass.

Return a hashreference with all units and their details for C<$type>.

=cut

sub systemctl_list_units
{
    my ($logger, $type) = @_;

    my $regexp = qr{^(?<fullname>(?<name>\S+)\.(?<type>\w+))\s+(?<loaded>\S+)\s+(?<active>\S+)\s+(?<running>\S+)(?:\s+|$)}; 
    return systemctl_list($logger, "units", $regexp, $type);
}

=pod

=item systemctl_list_unit_files

C<logger> is a mandatory logger to pass.

Return a hashreference with all unit-files and their details for C<$type>.

=cut

sub systemctl_list_unit_files
{
    my ($logger, $type) = @_;

    my $regexp = qr{^(?<fullname>(?<name>\S+)\.(?<type>\w+))\s+(?<state>\S+)(?:\s+|$)};
    return systemctl_list($logger, "unit-files", $regexp, $type);
}

=pod

=back

=head2 Private methods

=over

=item systemctl_list

Helper method to generate and parse output from C<systemctl> list commands like
C<list-units> or C<list-unit-files>.

C<logger> is a mandatory logger to pass.

C<property> is translated in the C<list-<property>> command, C<regexp> is the named 
regular expression that is used to match the output. 
C<type> is the type filter (if defined).

The regexp must have a C<name> named group, its value is used for the keys of the
hashreference that is returned.

=cut

sub systemctl_list
{
    my ($logger, $prop, $regexp, $type) = @_;
    my $proc = CAF::Process->new(
        [$SYSTEMCTL, '--all', '--no-pager', '--no-legend', '--full'],
        log => $logger,
        );

    if($prop =~ m/^([\w-]+)$/) {
        $proc->pushargs("list-$1");
    } else {
        $logger->error("Prop $prop has invalid characters.");
        return;
    }

    my $typmsg="";
    if($type) {
        if($type =~ m/^(\w+)$/) {
            $proc->pushargs("--type", $1);
            $typmsg=" for type $type";
        } else {
            $logger->error("Type $type has invalid characters.");
            return;
        }
    }

    my $data = $proc->output();
    my $ec = $?;

    if ($ec) {
        $logger->error(
            "Cannot get list of current $prop$typmsg from $SYSTEMCTL: ec $ec ($data)");
        return;
    }

    my $res = {};
    foreach my $line (split(/\n/, $data)) {
        if ($line !~ m/$regexp/) {
            $logger->debug(2, "Ouptut from $proc does not match pattern $regexp: $line");
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
