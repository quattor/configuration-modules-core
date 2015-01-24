# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Service::Unit;

use 5.10.1;
use strict;
use warnings;

use LC::Exception qw (SUCCESS);

use parent qw(CAF::Object Exporter);
use NCM::Component::Systemd::Systemctl qw(systemctl_show $SYSTEMCTL);

use Readonly;

Readonly our $TARGET_DEFAULT   => "default";
Readonly our $TARGET_RESCUE    => "rescue";
Readonly our $TARGET_MULTIUSER => "multi-user";
Readonly our $TARGET_GRAPHICAL => "graphical";
Readonly our $TARGET_POWEROFF  => "poweroff";
Readonly our $TARGET_REBOOT    => "reboot";
Readonly our $DEFAULT_TARGET =>
    $TARGET_MULTIUSER;    # default level (if default.target is not responding)

Readonly::Array my @TARGETS => qw($TARGET_DEFAULT $TARGET_RESCUE $TARGET_MULTIUSER $TARGET_GRAPHICAL
    $TARGET_POWEROFF $TARGET_REBOOT);

Readonly our $TYPE_SYSV    => 'sysv';
Readonly our $TYPE_SERVICE => 'service';
Readonly our $TYPE_TARGET  => 'target';

Readonly::Array my @TYPES => qw($TYPE_SYSV $TYPE_SERVICE $TYPE_TARGET);

# TODO should match schema default
Readonly our $DEFAULT_STARTSTOP => 1; # startstop true by default
Readonly our $DEFAULT_STATE => "on"; # state on by default

our @EXPORT_OK = qw($DEFAULT_TARGET $DEFAULT_STARTSTOP $DEFAULT_STATE);
push @EXPORT_OK, @TARGETS, @TYPES;

our %EXPORT_TAGS = (
    targets => \@TARGETS,
    types   => \@TYPES,
);

=pod

=head1 NAME

NCM::Component::Systemd::Service::Unit is a class handling services with units

=head2 Public methods

=over

=item new

Returns a new object, accepts the following options

=over

=item services

A hash reference with service as key and a hash reference 
with properties (according to the schema) as value.

This is typical the return value of 
     $config->getElement("/software/components/systemd/service")->getTree

(and if needed, augmented with the conversion of legacy C<ncm-chkconfig> services via the 
 NCM::Component::Systemd::Service::Chkconfig module).

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=cut

sub _initialize
{
    my ($self, %opts) = @_;

    $self->{services} = $opts{services};
    $self->{log} = $opts{log} if $opts{log};

    return SUCCESS;
}

=pod

=item service_text

Convert service C<detail> hash to human readable string.

=cut

sub service_text
{
    my ($self, $detail) = @_;

    my $text = "service $detail->{name} (";
    $text .= "state $detail->{state} ";
    $text .= "startstop $detail->{startstop} ";
    $text .= "type $detail->{type} ";
    $text .= "targets " . join(",", @{$detail->{targets}});
    $text .= ")";

    return $text;
}

# TODO check name for aliases; somehow keep them

=pod

=item current_services

Return hash reference with current configured services 
determined via C<systemctl list-unit-files>.

Specify C<type> (C<service> or C<target>; 
type can't be C<sysv> as those have no unit files).

=cut

sub current_services
{
    my ($self, $type) = @_;

    my $treg = '^(' . join('|', $TYPE_SERVICE, $TYPE_TARGET) . ')$';
    if (!($type && $type =~ m/$treg/)) {
        $self->error("Undefined or wrong type $type for systemctl list-unit-files");
        return;
    }

    my %current;
    # TODO move to NCM::Component::Systemd::Systemctl ?
    my $data = CAF::Process->new(
        [$SYSTEMCTL, 'list-unit-files', '--all', '--no-pager', '--no-legend', '--type', $type],
        log => $self,
        )->output();
    my $ec = $?;

    if ($ec) {
        $self->error(
            "Cannot get list of current unit files for type $type from $SYSTEMCTL: ec $ec ($data)");
        return;
    }

    my $reg = '^\s*(\S+)\.' . $type . '\s+(\w+)\s*$';
    foreach my $line (split(/\n/, $data)) {
        next if ($line !~ m/$reg/);

        my ($servicename, $state) = ($1, $2);
        my $detail = {name => $servicename, type => $type, startstop => $DEFAULT_STARTSTOP};

        # correct name for trailing @
        if ($detail->{name} =~ m/^(.*?)\@$/) {
            $self->debug(1, "Found trailing \@ for servicename $servicename");
            $detail->{name} = $1;
        }

        my $show = systemctl_show($self, "$detail->{name}.service");

        if(!defined($show)) {
            $self->error("Found service unit $detail->{name} with ",
                        "state $state but systemctl_show returned undef. ",
                        "Skipping this unit");
            next;
        };

        my $load = $show->{LoadState};
        my $active = $show->{ActiveState};

        $self->verbose("Found service unit $detail->{name} with ",
                       "state $state LoadState $load ActiveState $active");

        my $wanted = $show->{WantedBy};
        $detail->{targets} = [];
        if (defined($wanted)) {
            # TODO resolve further implied targets? 
            #   e.g. if multi-user.target is wanted-by graphical.target, do we add
            #   graphical.target here too? 
            foreach my $target (@$wanted) {
                # strip .target
                $target =~ s/\.target$//;
                push(@{$detail->{targets}}, $target);
            }
        } else {
            $self->verbose("No WantedBy defined for service unit $detail->{name}");
        }
        
        if($load eq 'not-found') {
            # also has active eq 'inactive'?
            $self->error("Component issue: found service $detail->{name} ",
                         "with LoadState $load ActiveState $active; ",
                         "expected active 'inactive'. Contact developers.") 
                         if ($active ne 'inactive');
            # unit file present, not coupled to any target
            $detail->{state} = 'off';
        } else {
            $detail->{state} = 'on';
        }

        $self->verbose("current_services added unit file service $detail->{name}");
        $self->debug(1, "current_services added unit file ", $self->service_text($detail));
        $current{$servicename} = $detail;
    }

    return \%current;
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
