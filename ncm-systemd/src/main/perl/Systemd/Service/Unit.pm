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
use NCM::Component::Systemd::Systemctl qw(systemctl_show systemctl_list_units systemctl_list_unit_files);

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

# Cache of the unitfiles for service and target
my $unit_cache = {service => {}, target => {}};

# Mapping of alias name to real name
my $unit_alias = {service => {}, target => {}};

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

=pod

=item current_services

Return hash reference with current configured services 
determined via C<systemctl list-unit-files>.

Specify C<type> (C<service> or C<target>; 
type can't be C<sysv> as those have no unit files).

This method also rebuilds the

=cut

sub current_services
{
    my ($self) = @_;

    # TODO: always update cache?
    $self->make_cache_alias($TYPE_SERVICE);

    my %current;
    
    while (my ($name,$data) = each %{$unit_cache->{$TYPE_SERVICE}}) {
        my $detail = {name => $name, type => $TYPE_SERVICE, startstop => $DEFAULT_STARTSTOP};

        my $show = $data->{show};
        if(! defined($show)) {
            if ($data->{baseinstance}) {
                $self->verbose("Base instance $name is not an actual runnable service. Skipping.");
            } else {
                $self->error("Found name $name without any show data. Skipping.");
            }    
            next;
        }

        my $load = $show->{LoadState};
        my $active = $show->{ActiveState};

        $self->verbose("Found service unit $detail->{name} with ",
                       "LoadState $load ActiveState $active");

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
        $current{$name} = $detail;
    }

    return \%current;
}

=pod

=back

=head2 Private methods

=over

=item make_cache_alias

(Re)generate the C<unit_cache> and C<unit_alias> map 
based on current unit files for C<type>. 

Each found unit is also added as it's own alias.

Supported types are C<service> and C<target>.

Returns the generated cache and alias map for unittesting purposes.

=cut

sub make_cache_alias
{
    my ($self, $type) = @_;

    my $treg = '^(' . join('|', $TYPE_SERVICE, $TYPE_TARGET) . ')$';
    if (!($type && $type =~ m/$treg/)) {
        $self->error("Undefined or wrong type $type for systemctl list-unit-files");
        return;
    }

    # reset cache and alias for current type
    $unit_cache->{$type} = {};
    $unit_alias->{$type} = {};

    my $units = systemctl_list_units($self, $type);
    my $unit_files = systemctl_list_unit_files($self, $type);
    
    # Join them, keep data
    while (my ($name, $data) = each %$units) {
        $unit_cache->{$type}->{$name}->{unit} = $data;
    }
    while (my ($name, $data) = each %$unit_files) {
        $unit_cache->{$type}->{$name}->{unit_file} = $data;
    }

    # Unknown names, to be checked if aliases
    my @unknown;
    while (my ($name, $data) = each %{$unit_cache->{$type}}) {
        # check for instances
        my $instance;
        if ($name =~ m/^(.*?)\@(.*)?$/) {
            $instance = $2;

            if ($instance eq "") {
                # A unit-file for instance-units (this shouldn't be an instance / unit).
                $data->{baseinstance} = 1;

                if (exists $data->{unit}) {
                    $self->error("$name is an instance base unit-file; should not be listed as a unit.");
                } else {
                    $self->verbose("$name is an instance base unit-file; nothing to show");
                }

                next;
            } else {
                $self->verbose("Name $name is an instance ($instance)");
                $data->{instance} = $instance;
            }
        }

        my $fullname = "$name.$type";
        my $show = systemctl_show($self, $fullname);

        if(!defined($show)) {
            $self->error("Found $type unit $name but systemctl_show returned undef. ",
                        "Skipping this unit");
            next;
        };

        my $pattern = '^(.*)\.'.$type.'$';
        my $id;
        if ($show->{Id} =~ m/$pattern/) {
            $id = $1;
            if ($id eq $name) {
                $data->{show} = $show;            
                $self->verbose("Added type $type name $name to cache.");
            } else {
                $self->verbose("Found id $id that doesn't match name $name.",
                               "Adding as unknown and skipping further handling.");
                # in particular, no aliases are processed/followed 
                # not to risk anything being overwritten
                push(@unknown, [$name, $id, $show]);
                next;
            }
        } else {
            $self->error("Found Id $show->{Id} for name $name type $type that ",
                         "doesn't match expected pattern '$pattern'. ",
                         "Skipping this unit.");
            next;
        }

        foreach my $alias (@{$show->{Names}}) {
            if ($alias =~ m/$pattern/) {
                $unit_alias->{$type}->{$1} = $id;
                $self->verbose("Added type $type alias $1 of id $id to map.");
            } else {
                $self->error("Found alias $alias that doesn't match expected pattern '$pattern'. Skipping.");
            }
        }
    }

    # Check if each alias' real name has an existing entry in cache
    while (my ($alias, $name) = each %{$unit_alias->{$type}} ) {
        if($alias ne $name) {
            # removing any aliases that got in the unit_cache
            delete $unit_cache->{$type}->{$alias};
        }

        if (! defined $unit_cache->{$type}->{$name}) {
            $self->error("Real unit $name.$type of alias $alias has no entry in cache");
            next;
        }

    }

    # Check the unknowns
    foreach my $unknown (@unknown) {
        my ($name, $id, $show) = @$unknown;

        my $realname = $unit_alias->{$type}->{$name};
        if(defined $realname) {
            $self->verbose("Unknown $name / $id is an alias for $realname");
        } else {
            # Most likely the realname does not list this name in its Names list
            # Maybe this is an alias of an alias? (We don't process the aliases, 
            # so their aliases are not added)
            # TODO: add it as alias or always error?
            my $realid = $unit_alias->{$type}->{$id};
            if (defined $realid) {
                my $cache = $unit_cache->{$type}->{$realid};
                if ($cache->{baseinstance}) {
                    $self->verbose("Unknown $name / $id is base instance and has missing alias entry.",
                                   " Adding it.");
                } else {
                    my $realshow = $cache->{show};
                    $self->verbose("Unknown $name / $id has missing alias entry. Adding it.",
                                   " Names ", join(', ', @{$show->{Names}}),
                                   " real Names ", join(', ', @{$realshow->{Names}}),
                                   ".");
                }
                $unit_alias->{$type}->{$name} = $realid;
            } else {
                $self->error("Found unknown name $name for type $type with ",
                             "id $id (full $show->{Id}) names ", 
                             join(', ', @{$show->{Names}}), 
                             ".");
            }                    
        }
    }

    # For unittesting purposes    
    return $unit_cache->{$type},$unit_alias->{$type}
}

=pod

=item target_build_dependency_tree

Build the dependency tree C<target_tree> for all targets.

=cut

sub target_build_dependency_tree
{
    my $self = shift;

    
}

=pod

=item target_requires

Given C<target>, returns (recursive) hash reference of all targets that are required.

The keys are the target names, the values have no significance (but using hash 
allows easy lookup).

No ordering information is preserved (the whole dependency tree is squashed).

=cut

sub target_requires
{
    my ($self, $target) = @_;
}

=pod

=back

=cut 

1;
