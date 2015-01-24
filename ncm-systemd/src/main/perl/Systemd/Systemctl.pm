# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Systemctl;

use 5.10.1;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(systemctl_show $SYSTEMCTL);

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

=back

=head2 Private methods

=over

=cut


=pod

=back

=cut 

1;
