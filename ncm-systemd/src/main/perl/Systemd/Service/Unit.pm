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

use Readonly;

Readonly my $TARGET_DEFAULT => "default";
Readonly my $TARGET_RESCUE => "rescue";
Readonly my $TARGET_MULTIUSER => "multi-user";
Readonly my $TARGET_GRAPHICAL => "graphical";
Readonly my $TARGET_POWEROFF => "poweroff";
Readonly my $TARGET_REBOOT => "reboot";
Readonly my $DEFAULT_TARGET => $TARGET_MULTIUSER; # default level (if default.target is not responding)

Readonly::Array my @TARGETS => qw($TARGET_DEFAULT $TARGET_RESCUE $TARGET_MULTIUSER $TARGET_GRAPHICAL
                                $TARGET_POWEROFF $TARGET_REBOOT);

our @EXPORT_OK = qw(@TARGETS $DEFAULT_TARGET);
push(@EXPORT_OK, @TARGETS);

our %EXPORT_TAGS = (
    targets => [@TARGETS],
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
    $self->{log}  = $opts{log}  if $opts{log};

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
    $text .= "targets ".join(",", @{$detail->{targets}});
    $text .= ")";
    
    return $text;
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
