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
use EDG::WP4::CCM::Path qw(unescape);

use NCM::Component::Systemd::UnitFile;
use NCM::Component::Systemd::Systemctl qw(
    systemctl_show
    systemctl_daemon_reload
    systemctl_list_units systemctl_list_unit_files
    systemctl_list_deps
    systemctl_is_enabled
    :properties
    );

use Readonly;

Readonly our $TARGET_DEFAULT   => "default";
Readonly our $TARGET_GRAPHICAL => "graphical";
Readonly our $TARGET_MULTIUSER => "multi-user";
Readonly our $TARGET_POWEROFF  => "poweroff";
Readonly our $TARGET_REBOOT    => "reboot";
Readonly our $TARGET_RESCUE    => "rescue";

# default level (if default.target is not responding)
Readonly our $DEFAULT_TARGET => $TARGET_MULTIUSER;

Readonly::Array my @TARGETS => qw($TARGET_DEFAULT
    $TARGET_GRAPHICAL $TARGET_MULTIUSER
    $TARGET_POWEROFF $TARGET_REBOOT
    $TARGET_RESCUE
);

Readonly our $TYPE_AUTOMOUNT  => 'automount';
Readonly our $TYPE_DEVICE  => 'device';
Readonly our $TYPE_MOUNT  => 'mount';
Readonly our $TYPE_PATH  => 'path';
Readonly our $TYPE_SCOPE  => 'scope';
Readonly our $TYPE_SERVICE => 'service';
Readonly our $TYPE_SLICE  => 'slice';
Readonly our $TYPE_SNAPSHOT  => 'snapshot';
Readonly our $TYPE_SOCKET  => 'socket';
Readonly our $TYPE_SWAP  => 'swap';
Readonly our $TYPE_TARGET  => 'target';
Readonly our $TYPE_TIMER  => 'timer';

Readonly our $TYPE_SYSV    => $TYPE_SERVICE;

# These are default/fallback and supported types for get_type_shortname
Readonly our $DEFAULT_TYPE => $TYPE_SERVICE;

Readonly::Array my @TYPES_SUPPORTED => (
    $TYPE_AUTOMOUNT, $TYPE_DEVICE, $TYPE_MOUNT,
    $TYPE_PATH, $TYPE_SCOPE, $TYPE_SERVICE,
    $TYPE_SLICE, $TYPE_SNAPSHOT, $TYPE_SOCKET,
    $TYPE_SWAP, $TYPE_TARGET, $TYPE_TIMER,
);

Readonly::Array my @TYPES => qw($DEFAULT_TYPE
    $TYPE_AUTOMOUNT $TYPE_DEVICE
    $TYPE_MOUNT $TYPE_PATH $TYPE_SCOPE
    $TYPE_SERVICE $TYPE_SLICE $TYPE_SNAPSHOT
    $TYPE_SOCKET $TYPE_SWAP $TYPE_SYSV
    $TYPE_TARGET $TYPE_TIMER
);

# Allowed states: enabled, disabled, masked
# Disabled does not imply OFF (can be started by other
#   enabled service which has the disabled service as dependency)
# Use 'masked' if you really don't want something to be started/running.
# is_ufstate assumes -runtime is not what you want supported.
Readonly our $STATE_DISABLED => "disabled";
Readonly our $STATE_ENABLED => "enabled";
Readonly our $STATE_MASKED => "masked";

Readonly my $UFSTATE_BAD => 'bad';

Readonly::Array my @STATES => qw($STATE_ENABLED $STATE_DISABLED $STATE_MASKED);

# TODO should match schema default
Readonly our $DEFAULT_STARTSTOP => 1; # startstop true by default
Readonly our $DEFAULT_STATE => $STATE_ENABLED; # state on by default

# Possible $PROPERTY_ACTIVESTATE values from systemd dbus interface
# http://www.freedesktop.org/wiki/Software/systemd/dbus/

Readonly my $ACTIVE_ACTIVATING => 'activating';
Readonly my $ACTIVE_ACTIVE => 'active';
Readonly my $ACTIVE_DEACTIVATING => 'deactivating';
Readonly my $ACTIVE_FAILED => 'failed';
Readonly my $ACTIVE_INACTIVE => 'inactive';
Readonly my $ACTIVE_RELOADING => 'reloading';

Readonly::Array my @ACTIVES_FINAL => (
    $ACTIVE_ACTIVE, $ACTIVE_FAILED, $ACTIVE_INACTIVE
);
Readonly::Array my @ACTIVES_INTERMEDIATE => (
    $ACTIVE_ACTIVATING, $ACTIVE_DEACTIVATING, $ACTIVE_RELOADING
);

# Possible $PROPERTY_UNITFILESTATE values from systemd dbus interface
# http://www.freedesktop.org/wiki/Software/systemd/dbus/

Readonly my $UNITFILESTATE_DISABLED => 'disabled';
Readonly my $UNITFILESTATE_ENABLED => 'enabled';
Readonly my $UNITFILESTATE_ENABLED_RUNTIME => 'enabled-runtime';
Readonly my $UNITFILESTATE_INVALID => 'invalid';
Readonly my $UNITFILESTATE_LINKED => 'linked';
Readonly my $UNITFILESTATE_LINKED_RUNTIME => 'linked-runtime';
Readonly my $UNITFILESTATE_MASKED => 'masked';
Readonly my $UNITFILESTATE_MASKED_RUNTIME => 'maksed-runtime';
Readonly my $UNITFILESTATE_STATIC => 'static';

Readonly my $UNITFILESTATE_RUNTIME_REGEXP => qr{-runtime$};

Readonly::Array my @UNITFILESTATES => (
    $UNITFILESTATE_DISABLED,
    $UNITFILESTATE_ENABLED, $UNITFILESTATE_ENABLED_RUNTIME,
    $UNITFILESTATE_INVALID,
    $UNITFILESTATE_LINKED, $UNITFILESTATE_LINKED_RUNTIME,
    $UNITFILESTATE_MASKED, $UNITFILESTATE_MASKED_RUNTIME,
    $UNITFILESTATE_STATIC
    );

our @EXPORT_OK = qw($DEFAULT_STARTSTOP $DEFAULT_STATE $DEFAULT_TARGET);
push @EXPORT_OK, @TARGETS, @TYPES, @STATES;

our %EXPORT_TAGS = (
    states  => \@STATES,
    targets => \@TARGETS,
    types   => \@TYPES,
);

# TODO add option or method to modify this default.
# Boolean to indicate that a unit is considered active if there is
# another unit that is active and triggers it.
my $active_trigger_is_active = 1;

# Cache of the unitfiles for service and target
my $unit_cache = {};

# Mapping of alias name to real name
my $unit_alias = {};

# Cache the dependencies and/or reverse dependencies
my $dependency_cache = {};

=pod

=head1 NAME

NCM::Component::Systemd::Service::Unit is a class handling services with units

=head2 Public methods

=over

=item new

Returns a new object, accepts the following options

=over

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=cut

sub _initialize
{
    my ($self, %opts) = @_;

    $self->{log} = $opts{log} if $opts{log};

    # Always daemon-reload on init, to make sure we are dealing with correct units
    systemctl_daemon_reload($self);

    return SUCCESS;
}

=pod

=item unit_text

Convert unit C<detail> hashref to human readable string.

Generates errors for missing attributes.

=cut

sub unit_text
{
    my ($self, $detail) = @_;

    my $text;
    if(exists($detail->{name})) {
        $text = "unit $detail->{name} (";
    } else {
        $self->error("Unit detail is missing name");
        return;
    }

    my @attributes = qw(state startstop type shortname targets possible_missing);
    my @attrtxt;
    foreach my $attr (@attributes) {
        my $val = $detail->{$attr};
        if (defined($val)) {
            my $tmptxt = "$attr ";
            if(ref($val) eq 'ARRAY') {
                $tmptxt .= join(',', @$val);
            } else {
                $tmptxt .= $val;
            }
            push(@attrtxt, $tmptxt);
        } else {
            $self->error("Unit $detail->{name} details is missing attribute $attr");
        }
    }

    my $fullname = "$detail->{shortname}.$detail->{type}";
    if ($detail->{name} ne $fullname) {
        $self->error("Unit $detail->{name} does not match fullname $fullname.");
        return;
    }

    $text .= join(' ', @attrtxt) . ")";

    return $text;
}

=pod

=item current_units

Return hash reference with current units
determined via C<make_cache_alias>.

The array references C<units> and C<possible_missing>
are passed to C<make_cache_alias>.

=cut

sub current_units
{
    my ($self, $units, $possible_missing) = @_;

    $self->make_cache_alias($units, $possible_missing);

    my %current;

    # Dangerous to use unit_cache and 'each' here.
    # Lots of calls can lead to an update of the hashref,
    # which results in undefined behaviour for 'each'
    $self->debug(2, "current_units processing unit_cache units ",
                 join(',', sort keys %$unit_cache));
    foreach my $name (sort keys %$unit_cache) {
        my $data = $unit_cache->{$name};

        my $show = $data->{show};
        if(! defined($show)) {
            if ($data->{baseinstance}) {
                $self->verbose("Base instance $name is not an actual runnable service. Skipping.");
            } elsif($units && @$units) {
                # Lots of units that have no show data, because they aren't queried all.
                $self->debug(1, "Found name $name without any show data; ",
                               "only selected units were queried. Skipping.");
            } else {
                $self->error("Found name $name without any show data. Skipping.");
            }
            next;
        }

        my $id = $show->{$PROPERTY_ID};
        my ($type, $shortname) = $self->get_type_shortname($id);
        my $detail = { name => $id, shortname => $shortname, type => $type };

        # TODO: can we refine this somehow? Or does it make no sense.
        $detail->{startstop} = $DEFAULT_STARTSTOP;

        # Intentionally not using the full recursive list from get_wantedby method
        #   e.g. if multi-user.target is wanted-by graphical.target,
        #   we do not add graphical.target here
        my $wanted = $show->{$PROPERTY_WANTEDBY};
        $detail->{targets} = [];
        if (defined($wanted)) {
            push(@{$detail->{targets}}, @$wanted);
        } else {
            $self->verbose("No $PROPERTY_WANTEDBY defined for unit $detail->{name}");
        }

        # This can return other states then the enabled/disabled/masked.
        my ($ufstate, $derived) = $self->get_ufstate($detail->{name});
        if(! $ufstate) {
            $self->verbose("No ufstate could be determined. Using derived state $derived.");
            $ufstate = $derived;

            if($ufstate) {
                # Track that is a derived state
                $detail->{derived} = 1;
            } else {
                $self->error("is_ufstate: unable to use ufstate.");
                $ufstate = undef;
            };
        };

        $detail->{state} = $ufstate;
        # Does not make much sense for current units, since they are not missing.
        $detail->{possible_missing} = $self->is_possible_missing($detail->{name}, $detail->{state});

        $self->debug(1, "current_services added unit file service $detail->{name}");
        $self->debug(2, "current_services added unit file ", $self->unit_text($detail));
        $current{$name} = $detail;
    }

    $self->debug(1, "current_units found ", scalar keys %current, " units:",
                 join(",", sort keys %current));
    return \%current;
}

=pod

=item current_target

Return the current target.

TODO: implement this. systemctl list-units --type target
lists all current targets (yes, with an s).

=cut

sub current_target
{
    die 'Service/Unit current_target is unimplemented';
}

=pod

=item default_target

Return the default target.

Supported options:

=over

=item force

Force is passed to the C<fill_cache> method.

=back

=cut

# TODO: switch to systemctl get-default

sub default_target
{
    my ($self, %opts) = @_;

    my $default = "$TARGET_DEFAULT.target";

    $self->fill_cache([$default], force => $opts{force} ? 1 : 0);

    my $unit = $unit_alias->{$default};

    if ($unit) {
        $self->verbose("Default target based on $default corresponds with unit $unit");
    } else {
        $self->error("Can't determine default target based on $default. Using $DEFAULT_TARGET as fall-back.");
        $unit = $DEFAULT_TARGET;
    }

    return $unit;
}

=pod

=item configured_units

C<configured_units> parses the C<tree> hash reference and builds up the
units to be configured. It returns a hash reference with key the unit name and
values the details of the unit.

Units with missing types are assumed to be TYPE_SERVICE; targets with
missing type are assumed to be TYPE_TARGET.

(C<tree> is typcially obtained with the C<_getTree> method).

=cut

sub configured_units
{
    my ($self, $tree) = @_;

    my %units;

    foreach my $unit (sort keys %$tree) {
        my $detail = $tree->{$unit};

        # only set the name (not mandatory in new schema, to be added here)
        $detail->{name} = unescape($unit) if (! exists($detail->{name}));

        my ($type, $shortname) = $self->get_type_shortname($detail->{name}, $detail->{type}, $TYPE_SERVICE);

        $detail->{type} = $type;
        $detail->{shortname} = $shortname;
        $detail->{name} = "$shortname.$type";

        my @targets;
        foreach my $target (@{$detail->{targets}}) {
            my ($t_type, $t_short) = $self->get_type_shortname($target, undef, $TYPE_TARGET);
            push(@targets, "$t_short.$t_type");
        }
        $detail->{targets} = \@targets;

        $detail->{possible_missing} = $self->is_possible_missing($detail->{name}, $detail->{state});

        if($detail->{file}) {
            # strip the unitfile details from further unit details
            my $ufile = delete $detail->{file};

            # configure the unitfile
            my $uf = NCM::Component::Systemd::UnitFile->new(
                $detail->{name},
                $ufile->{config},
                custom => $ufile->{custom},
                backup => '.old',
                replace => $ufile->{replace},
                log => $self,
                );

            my $changed = $uf->write();
            if (! defined($changed)) {
                $self->error("Unitfile confiuration failed, skipping the unit ", $self->unit_text($detail));
                next;
            };

            if($ufile->{only}) {
                $self->info("Only unitfile configuration for ", $self->unit_text($detail));
                next;
            }

        }

        $self->verbose("Add unit name $detail->{name} (unit $unit)");
        $self->debug(1, "Add ", $self->unit_text($detail));

        $units{$detail->{name}} = $detail;
    }

    # TODO figure out a way to specify what off-targets and what on-targets mean.
    #   If on is defined, all other targets are off
    #   If off is defined, all others are on or also off? (2nd case: off means off everywhere)

    $self->debug(1, "configured_units found ", scalar keys %units, " units:",
                 join(",", sort keys %units));
    return \%units;
}

=pod

=item get_aliases

Given an arrayref of C<units>, return a hashref with key the unit (from the list)
that is an alias for another unit (not necessarily from the list);
and the other unit's name is the value.

The C<unit_alias> cache is used for lookup.

The C<possible_missing> arrayref is passed to the C<fill_cache> method

Supported options

=over

=item force

The force flag is passed to the C<fill_cache> method

=item possible_missing

The C<possible_missing> arrayref is passed to C<make_cache_alias>.

=back

=cut

sub get_aliases
{
    my ($self, $units, %opts) = @_;

    my $res = {};

    $self->fill_cache($units,
                      force => $opts{force} ? 1 : 0,
                      possible_missing => $opts{possible_missing});

    foreach my $unit (@$units) {
        my $realname = $unit_alias->{$unit};
        if($realname && $realname ne $unit) {
            $self->debug(1, "Unit $unit is an alias for $realname");
            $res->{$unit} = $realname;
        }
    }

    return $res;
}

=pod

=item possible_missing

Given the hashref C<units> with key unit and value the unit's details,
return a array ref with units that are "possible missing".
Such units will not cause an error to be logged if they are not
found in the cache during certain methods (e.g. C<make_cache_alias>).

=cut

sub possible_missing
{
    my ($self, $units) = @_;

    my @p_m;
    foreach my $unit (sort keys %$units) {
        push(@p_m, $unit) if ($units->{$unit}->{possible_missing});
    }

    $self->verbose("Found ", scalar @p_m, " possible missing units: ",
                   join(",", @p_m));

    return \@p_m;
}

=pod

=back

=head2 Private methods

=over

=item is_possible_missing

Determine if C<unit> is C<possible_missing>
(see C<make_cache_alias>). (Returns 0 or 1).

A unit is possible_missing if

=over

=item the unit is in state masked (i.e. unit that is not expected
to be running anyway). Unit in state disabled is not "possible missing"
(they can be dependency for other units).

=back

=cut


sub is_possible_missing
{
    my ($self, $unit, $state) = @_;

    if ($state eq $STATE_MASKED) {
        $self->debug(1, "Unit $unit with state $STATE_MASKED is possible_missing");
        return 1;
    }

    # Default
    $self->debug(2, "Unit $unit is not possible_missing");
    return 0;
}

=pod

=item init_cache

(Re)Initialise all unit caches.

Returns the caches (for unittestung mainly).

Affected caches are

=over

=item unit_cache

=item unit_alias

=item dependency_cache

=back

=cut

sub init_cache
{
    my ($self) = @_;

    $unit_alias = {};
    $unit_cache = {};

    $dependency_cache = {
        deps => {},
        rev => {},
    };

    # For unittesting
    return $unit_cache, $unit_alias, $dependency_cache;
}

=pod

=item get_type_shortname

C<get_type_shortname> returns the type and shortname based on the
C<unit> and optional C<type>.

If the C<type> is not specified, it will be derived using the supported types.

If the type can't be determined based on the supported types,
the C<defaulttype> will be used. If in this case the C<defaulttype>
is undefined, DEFAULT_TYPE will be used and error will be logged.
If the C<defaulttype> is defined,

=cut

sub get_type_shortname
{
    my ($self, $unit, $type, $defaulttype) = @_;

    my $type_pattern = '\.(' . join('|', @TYPES_SUPPORTED) . ')$';
    if ($type) {
        $self->debug(1, "get_type_shortname: set type $type for unit $unit.");
    } elsif ($unit =~ m/$type_pattern/) {
        $type = $1;
        $self->debug(1, "get_type_shortname: found type $type based on unit $unit.");
    } elsif($defaulttype) {
        $type = $defaulttype;
        $self->verbose("get_type_shortname: could not determine type based on unit $unit ",
                       "and pattern $type_pattern. Using defaulttype $defaulttype.");
    } else {
        $type = $DEFAULT_TYPE;
        $self->error("get_type_shortname: could not determine type based on unit $unit ",
                     "and pattern $type_pattern. Using fallback default type $DEFAULT_TYPE.");
    }

    # The short unit name
    my $shortname = $unit;
    my $reg = '\.'.$type.'$';
    # TODO: actually check that this replaces something?
    #    not in case of default type
    $shortname =~ s/$reg//;

    return $type, $shortname;
}


=pod

=item make_cache_alias

(Re)generate the C<unit_cache> and C<unit_alias> map
based on current units and unitfiles from the C<systemctl_list_units>
and C<systemctl_list_unit_files> methods.

Details for each unit from arrayref C<units> are also added.
If C<units> is empty/undef, all found units and unitfiles
are.

If a unit is an alias of an other unit, it is added to the alias map.
Each non-alias unit is also added as it's own alias.

Units in the C<possible_missing> arrayref can be missing, and no error
is logged if they are. For any other unit, an error is logged when
neither the C<systemctl_list_units>
and C<systemctl_list_unit_files> methods provide any information about it.

Returns the generated cache and alias map for unittesting purposes.

=cut

sub make_cache_alias
{
    my ($self, $units, $possible_missing) = @_;

    $possible_missing ||= [];

    my $list_units = systemctl_list_units($self);
    my $list_unit_files = systemctl_list_unit_files($self);

    # Join them, keep existing non-related data
    foreach my $unit (sort keys %$list_units) {
        $unit_cache->{$unit}->{unit} = $list_units->{$unit};
    }
    foreach my $unit (sort keys %$list_unit_files) {
        $unit_cache->{$unit}->{unit_file} = $list_unit_files->{$unit};
    }

    my @units;
    if ($units && @$units) {
        @units = @$units;
    } else {
        @units = sort keys %$unit_cache;
    }

    $self->debug(1, "make_cache_alias with ", scalar @units, " units");

    my @unknown;
    foreach my $unit (@units) {
        my $is_possible_missing = (grep {$_ eq $unit} @$possible_missing) ? 1 : 0;
        my $data = $unit_cache->{$unit};
        my $show;

        if (! defined($data)) {
            my $log_method = "error";
            my $continue;

            # Always try to get show information, even for possible missing units
            $show = systemctl_show($self, $unit, no_error => $is_possible_missing);
            if(defined($show->{$PROPERTY_ID})) {
                $self->debug(1, "Unit $unit not listed but has show data.");
                $log_method = "verbose";
                $continue = "Found unit via systemctl show.";
                # Insert unit in cache
                $unit_cache->{$unit}->{showonly} = 1;
                # Reassign $data
                $data = $unit_cache->{$unit};
            } else {
                $self->debug(1, "Unit $unit not listed and has no show data.");
                if ($is_possible_missing) {
                    $self->debug(1, "Unit $unit is in possible_missing (and not found). ",
                                 "No error will be logged.");
                    $log_method = "verbose";
                }
            }

            # no entry in cache from units or unitfiles
            $self->$log_method("Trying to add details of unit $unit ",
                         "but no entry in cache after adding all units and unitfiles. ",
                         $continue ? $continue : "Ignoring this unit.");

            next if (! $continue);
        }

        # check for instances
        my $instance_pattern = '^(.*?)\@(.*)?\.(' . join('|', @TYPES_SUPPORTED) . ')$';
        my $instance;
        if ($unit =~ m/$instance_pattern/) {
            $instance = $2;

            if ($instance eq "") {
                # A unit-file for instance-units (this shouldn't be an instance / unit itself).
                $data->{baseinstance} = 1;
                my $msg = "$unit is an instance base unit-file;";
                if ($data->{unit}) {
                    $self->error("$msg should not be listed as a unit.");
                } else {
                    $self->debug(1, "$msg nothing to show");
                }

                next;
            } else {
                $self->debug(1, "Unit $unit is an instance ($instance)");
                # TODO: use systemd-escape -u to decode the instance name?
                #    only in recent systemd versions.
                $data->{instance} = $instance;
            }
        }

        $show = systemctl_show($self, $unit, no_error => $is_possible_missing) if (! defined($show));

        if(!defined($show)) {
            my $log_method = 'error';
            my $msg = '';

            my $data_unit = $data->{unit};
            if ($is_possible_missing &&
                $data_unit->{loaded} && $data_unit->{loaded} eq 'not-found' &&
                $data_unit->{active} && $data_unit->{active} eq $ACTIVE_INACTIVE &&
                $data_unit->{running} && $data_unit->{running} eq 'dead') {
                # It's safe to skip this unit without error
                $log_method = 'verbose';
                $msg = " and unit is not-found/$ACTIVE_INACTIVE/dead"
            };
            $self->$log_method("Found unit $unit but systemctl_show returned undef$msg. ",
                               "Skipping this unit");
            next;
        };

        my $pattern = '^(.*)\.(' . join('|', @TYPES_SUPPORTED) . ')$';
        my $id = $show->{$PROPERTY_ID};

        if ($id ne $unit) {
            if ($show->{$PROPERTY_ID} =~ m/$pattern/) {
                $self->debug(1, "Found id $id that doesn't match unit $unit. ",
                             "Adding as unknown and skipping further handling.");
                # in particular, no aliases are processed/followed
                # not to risk anything being overwritten

                # add the real name to the list of units to check
                if(! grep {$id eq $_} @units) {
                    $self->verbose("Adding the id $id from unkown unit $unit to list of units");
                    push(@units, $id);
                };

                push(@unknown, [$unit, $id, $show]);
            } else {
                $self->error("Found $PROPERTY_ID $show->{$PROPERTY_ID} for unit $unit that ",
                             "doesn't match expected pattern '$pattern'. ",
                             "Skipping this unit.");
            }

            next;
        }

        $data->{show} = $show;
        $self->debug(1, "Added unit $unit to cache.");

        # All $PROPERTY_NAMES, incl the unit itself
        foreach my $alias (@{$show->{$PROPERTY_NAMES}}) {
            if ($alias =~ m/$pattern/) {
                $unit_alias->{$alias} = $id;
                $self->debug(1, "Added alias $alias of id $id to map.");
            } else {
                $self->error("Found alias $alias for unit $unit that doesn't match ",
                             "expected pattern '$pattern'. Skipping.");
                next; # in case future code is added after the else block.
            }
        }
    }

    # Check the unknowns (this completes the aliases)
    foreach my $unknown (@unknown) {
        my ($unit, $id, $show) = @$unknown;

        my $realname = $unit_alias->{$unit};
        if(defined($realname)) {
            $self->debug(1 ,"Unknown $unit / $id is an alias for $realname");
        } else {
            # Most likely the realname does not list this name in its Names list
            # Maybe this is an alias of an alias? (We don't process the aliases,
            # so their aliases are not added)
            # TODO: add it as alias or always error?
            my $realid = $unit_alias->{$id};
            if (defined($realid)) {
                my $cache = $unit_cache->{$realid};
                if ($cache->{baseinstance}) {
                    $self->verbose("Unknown $unit / $id is base instance and ",
                                   "has missing alias entry. Adding it.");
                } else {
                    my $realshow = $cache->{show};
                    $self->verbose("Unknown $unit / $id has missing alias entry. Adding it. ",
                                   "$PROPERTY_NAMES ", join(', ', @{$show->{$PROPERTY_NAMES}}),
                                   " real $PROPERTY_NAMES ", join(', ', @{$realshow->{$PROPERTY_NAMES}}),
                                   ".");
                }
                $unit_alias->{$unit} = $realid;
            } else {
                $self->error("Found unknown unit $unit with ",
                             "id $id (full $show->{$PROPERTY_ID}) $PROPERTY_NAMES ",
                             join(', ', @{$show->{$PROPERTY_NAMES}}),
                             ".");
            }
        }
    }

    # Check if each alias' real name has an existing entry in cache
    foreach my $alias (sort keys %$unit_alias) {
        my $realunit = $unit_alias->{$alias};
        if($alias ne $realunit && $unit_cache->{$alias}) {
            # removing any aliases that somehow got in the unit_cache
            $self->debug(1, "Removing alias $alias of $realunit from cache");
            delete $unit_cache->{$alias};
        }

        if (! defined($unit_cache->{$realunit})) {
            $self->error("Real unit $realunit of alias $alias has no entry in cache");
            next;
        }

    }

    $self->verbose("make_cache_alias completed with ",
        scalar keys %$unit_cache, " cached units ",
        scalar keys %$unit_alias, " alias units"
        );
    # For unittesting purposes
    return $unit_cache, $unit_alias;
}


=pod

=item fill_cache

Fill the C<unit_cache> and C<unit_alias map>
for the arrayref C<units> provided.

The cache is updated via the C<make_cache_alias> method if the unit
is missing from the unit_alias map or if C<force> is true.

Supported options

=over

=item force

Force cache refresh.

=item possible_missing

The C<possible_missing> arrayref is passed to C<make_cache_alias>.

=back

=cut

sub fill_cache
{
    my ($self, $units, %opts) = @_;

    my $force =  $opts{force} ? 1 : 0;

    $opts{possible_missing} ||= [];

    my @updates;
    foreach my $unit (@$units) {
        # Only update the cache if force=1 or the unit is not in the unit_alias cache
        if ($force || (! defined($unit_alias->{$unit}))) {
            push(@updates, $unit);
        };
    }

    $self->debug(1, "fill_cache: update cache for units ", join(", ", @$units),
                 " with to be updated: ", join(', ', @updates),
                 " and possible_missing ", join(', ', @{$opts{possible_missing}}));
    $self->make_cache_alias(\@updates, $opts{possible_missing}) if (@updates);

    # for unittests only
    return \@updates;
}


=pod

=item get_unit_show

Return the show C<property> for C<unit> from the
unit_cache and unit_alias map.

Supported options

=over

=item force

Force cache refresh.

=item possible_missing

If true, this unit is "possible missing" (see C<make_cache_alias>)

=back

=cut

sub get_unit_show
{
    my ($self, $unit, $property, %opts) = @_;

    my $force = exists($opts{force}) ? $opts{force} : 0;

    if ($force) {
        $self->debug(1, "get_unit_show force updating the cache for unit $unit.");
        $self->make_cache_alias([$unit], $opts{possible_missing} ? [$unit] : []);
    }

    my $realname = $unit_alias->{$unit};
    if(! $realname) {
        my $msg = "get_unit_show: no alias for unit $unit defined";
        if ($opts{possible_missing}) {
            $self->verbose("$msg and unit is possible missing.");
        } else {
            $self->error("$msg. (Forgot to update cache?)");
        }
        return;
    }
    $self->debug(1, "get_unit_show found realname $realname for unit $unit");

    my $unittxt = "unit $unit";
    if ($realname ne $unit) {
        $unittxt .= " realname $realname";
    }

    my $show = $unit_cache->{$realname}->{show};
    if(! $show) {
        $self->error("get_unit_show: no show data for $unittxt. (Forgot to update cache?)");
        return;
    }

    my $val = $show->{$property};

    my $msg;
    if(ref($val) eq "ARRAY") {
        $msg = join(',', @$val);
    } elsif(defined($val)) {
        $msg = "$val";
    } else {
        $msg = "<undefined>";
    }

    $self->verbose("get_unit_show $unittxt property $property value $msg.");

    return $val;
}

=pod

=item get_wantedby

Return a hashref of all units that "want" C<unit>
(hashref is used for easy lookup; the key is the unit,
the value is a boolean).

It uses the C<dependency_cache> for reverse dependencies
(missing cache entries are added).

Supported options

=over

=item force

Force cache update.

=item ignoreself

By default, the reverse dependency list contains the unit itself too.
With C<ignoreself> true, the unit itself is not returned
(but still stored in cache).

=back

=cut

sub get_wantedby
{
    my ($self, $unit, %opts) = @_;

    my $force = exists($opts{force}) ? $opts{force} : 0;

    # Try lookup from reverse cache.
    # If not found in cache, look it up via systemctl_list_deps
    # with reverse enabled.
    if($force || (! defined($dependency_cache->{rev}->{$unit}))) {
        $self->debug(1, "get_wantedby: force / no cache for dependency for unit $unit.");
        my $deps = systemctl_list_deps($self, $unit, 1);
        if (! defined($deps)) {
            # In case of failure.
            $self->error("get_wantedby: systemctl_list_deps for unit $unit and reverse=1 returned undef. ",
                         "Returning empty hashref here, not storing it in cache.");
            return {};
        }

        $dependency_cache->{rev}->{$unit} = $deps;
    } else {
        $self->debug(1, "Dependency for unit $unit in cache.");
    }

    # Make copy (shallow is ok, values are 1s)
    my $res = { %{$dependency_cache->{rev}->{$unit}} };

    if ($opts{ignoreself}) {
        $self->debug(1, "Removing the unit $unit itself from the returned result");
        delete $res->{$unit};
    }

    return $res;
}

=pod

=item is_wantedby

Return if C<unit> is wanted by C<target>.

Any unit can be passed as C<target> (it does not have to be
a unit of type 'target').

It uses the C<get_wantedby> method for the dependency lookup.

Supported options

=over

=item force

Force cache update (passed to C<get_wantedby>).

=back

=cut

sub is_wantedby
{
    my ($self, $unit, $target, %opts) = @_;

    my $wantedby = $self->get_wantedby($unit, force => $opts{force});

    my $res = $wantedby->{$target};

    $self->debug(1, "Unit $unit is ", $res ? "" : " not ", "wanted by target $target");

    return $res;
}


=pod

=item is_active

C<is_active> returns true or false and reflects if a unit is "running" or not.

The following options are supported

=over

=item sleeptime
=item max

Units that are 'reloading', 'activating' and 'deactivating' are refreshed with
C<sleep> (default 1 sec) and C<max> number of tries (default 3). Until

=item force

Force cache refresh (passed to C<get_unit_show>).

=back

=cut

# TODO: add support for enabled inactive units that are triggerd by other enabled active units
#    e.g. the resp. cups.service and cups.socket units
# TODO or simply use is-active?

sub is_active
{
    my ($self, $unit, %opts) = @_;

    my $sleep = exists($opts{sleep}) ? $opts{sleep} : 1;
    my $max = exists($opts{max}) ? $opts{max} : 3;

    my $unittxt = "unit $unit";

    $self->debug(1, "is_active $unittxt (sleep=$sleep max=$max)");

    my $active = $self->get_unit_show($unit, $PROPERTY_ACTIVESTATE, force => $opts{force});
    if (! defined($active)) {
        $self->error("is_active no $PROPERTY_ACTIVESTATE for $unittxt found.");
        return;
    }

    my $tries = 0;
    while ((grep {$_ eq $active} @ACTIVES_INTERMEDIATE)) {
        my $msg = "the cache for the $unittxt due to intermittent state $active";
        if ($tries < $max) {
            sleep($sleep);
            $active = $self->get_unit_show($unit, $PROPERTY_ACTIVESTATE, force => 1);
            if (! defined($active)) {
                $self->error("is_active no $PROPERTY_ACTIVESTATE for $unittxt found ($tries of max $max).");
                return;
            }
            $self->verbose("is_active updating $msg. New state $active.");
            $tries++;
        } else {
            # Map the intermediate states to a final state.
            # We are going to assume all will be fine.
            if($active eq $ACTIVE_DEACTIVATING) {
                $active = $ACTIVE_INACTIVE;
            } else {
                $active = $ACTIVE_ACTIVE;
            }
            $self->verbose("is_active max tries $tries reached for updating $msg. ",
                           "Forced mapping to $active.");
        }
    }

    # Always parse this, even if active_trigger_is_active is false,
    # because you can get messages from systemctl like
    #   Warning: Stopping X.service, but it can still be activated by:
    #       X.socket
    if ($active ne $ACTIVE_ACTIVE) {
        # Look for any active TriggeredBy units
        my $triggeredby = $self->get_unit_show($unit, $PROPERTY_TRIGGEREDBY, force => $opts{force});
        if ($triggeredby && @$triggeredby) {
            $self->fill_cache($triggeredby, force => $opts{force});
            foreach my $unit_that_triggers (@$triggeredby) {
                if($self->is_active($unit_that_triggers, %opts)) {
                    my $msg = '';
                    if ($active_trigger_is_active) {
                        $active = $ACTIVE_ACTIVE;
                    } else {
                        $msg = "not ";
                    }
                    $self->verbose("is_active: unit $unit itself is not active (is $active), ",
                                   "but has active unit $unit_that_triggers that triggers it. ",
                                   "This unit is considered ${msg}active.");

                }
            }
        }
    }

    # Must be one of the final states now.
    if (grep {$_ eq $active} @ACTIVES_FINAL) {
        my $msg = "is_active: active $active for $unittxt, is_active";
        if ($active eq $ACTIVE_ACTIVE) {
            $self->debug(1, "$msg true");
            return 1;
        } else {
            $self->debug(1, "$msg false");
            return 0;
        }
    } else {
        $self->error("is_active: unsupported $PROPERTY_ACTIVESTATE $active. ",
                     "(Component version too old?)");
        return;
    }
}

=pod

=item get_ufstate

Return the state of the C<unit> using the UnitFileState and
the derived state from the state of the $PROPERTY_WANTEDBY units.

The returned state can be more then the usual supported states (e.g. static).

The following options are supported

=over

=item force

Force cache refresh (passed to C<get_unit_show> and C<fill_cache>)

=back

=cut

# TODO: simply use is-enabled? or at least for derived?

sub get_ufstate
{
    my ($self, $unit, %opts) = @_;

    $self->verbose("get_ufstate for unit $unit");

    my $ufstate = $self->get_unit_show($unit, $PROPERTY_UNITFILESTATE, force => $opts{force});

    if ($ufstate && $ufstate eq $UFSTATE_BAD) {
        my $msg = "Unit $unit $PROPERTY_UNITFILESTATE $UFSTATE_BAD";
        my $is_enabled = systemctl_is_enabled($self, $unit);
        if ($is_enabled) {
            $self->verbose("$msg is-enabled $is_enabled");
            $ufstate = $is_enabled;
        } else {
            $self->verbose("$msg is-enabled failed");
        }
    }

    # The derived state is based on the ufstate of any of the $PROPERTY_WANTEDBY units
    # Using the recursive reverse dependecy list rather than
    # walking the ->{show}->{$PROPERTY_WANTEDBY} attribute tree ourself.
    # TODO: For now, it can only be STATE_ENABLED or STATE_DISABLED.

    my $wantedby = $self->get_wantedby($unit, ignoreself => 1);

    my $derived;
    if ($wantedby) {
        my @units = keys %$wantedby;
        $self->fill_cache(\@units, force => $opts{force} ? 1 : 0);
        foreach my $wunit (sort keys %$wantedby) {
            my $wufstate = $self->get_unit_show($wunit, $PROPERTY_UNITFILESTATE, force => $opts{force});
            if (! defined($wufstate)) {
                $self->verbose("Undefined $PROPERTY_UNITFILESTATE for unit $wunit");
                next;
            } elsif ($wufstate eq $STATE_ENABLED) {
                $derived = $STATE_ENABLED;
                $self->debug(1, "get_ufstate: unit $unit found wantedby unit $wunit in state $STATE_ENABLED. ",
                             "Setting derived state to $derived.");
                # TODO: break or check all of them?
            } else {
                $self->debug(1, "get_ufstate: unit $unit found wantedby unit $wunit in state $wufstate.");
            }
        }

        if (! defined($derived)) {
            $derived = $STATE_DISABLED;
            $self->verbose("get_ufstate: unit $unit found no wantedby units in state $STATE_ENABLED. ",
                           "Setting derived state to $derived.");
        }
    } else {
        $derived = $STATE_DISABLED;
        $self->verbose("get_ufstate: unit $unit is not wanted by any other unit. ",
                       "Derived state is $derived.");
    }

    return $ufstate, $derived;
}

=pod

=item is_ufstate

C<is_ufstate> returns true or false if the
UnitFileState of C<unit> matches the (simplified) C<state>.

An error is logged  and undef returned if the unit can't be queried.

The following options are supported

=over

=item force

Refresh the cache C<force> (passed to C<get_ufstate> method).

=back

=cut

sub is_ufstate
{
    my ($self, $unit, $state, %opts) = @_;

    $self->debug(1, "is_ufstate for unit $unit and state $state");

    my ($ufstate, $derived) = $self->get_ufstate($unit, force => $opts{force});

    if(! $ufstate) {
        $self->verbose("No ufstate could be determined. Using derived state $derived.");
        $ufstate = $derived;

        if(! $ufstate) {
            $self->error("is_ufstate: unable to use ufstate.");
            return;
        };
    };

    my $msg = "is_ufstate: unit $unit with $PROPERTY_UNITFILESTATE '$ufstate'";
    if ($state eq $ufstate) {
        $self->debug(1, "$msg as wanted.");
        return 1;
    }

    # static units shouldn't be enabled/or disabled, they are static because they
    #   are required by another unit (and will be started when the other unit is).
    #   (the unit-file misses the [Install] section)
    #   we can force enable/disable/mask static units by symlinking, but we probably shouldn't.
    #   TODO: support expert mode that allows this.
    elsif ($ufstate eq $UNITFILESTATE_STATIC) {
        $self->info("$msg is a static unit. ",
                    "Not going to force the state to $state and assume this is ok.");
        return 1;
    }

    # warn for invalid states (although not much can be done about it)
    elsif ($ufstate eq $UNITFILESTATE_INVALID) {
        $self->warn("$msg uncertain/unsupported behaviour. Assuming this is not the state $state.");
        return 0;
    }

    # linked states: try to resolve the symlink? is this expert mode?
    # TODO: this is a serious assumption.
    elsif ($ufstate eq $UNITFILESTATE_LINKED) {
        $self->warn("$msg uncertain/unsupported behaviour. Assuming this is the state $state.");
        return 1;
    }

    # all -runtime are non-permanent, so not supported here.
    elsif ($ufstate =~ m/$UNITFILESTATE_RUNTIME_REGEXP/) {
        $self->info("$msg is runtime/non-permanent and thus not the wanted state $state.");
        return 0;
    }

    # the rest
    else {
        $self->debug(1, "$msg not the wanted state $state.");
        return 0;
    }
}

=pod

=back

=head2 Private methods

=over

=item _getTree

The C<getTree> method is similar to the regular
B<EDG::WP4::CCM::CacheManager::Element::getTree>, except that
it keeps the unitfile configuration as an Element instance
(as required by B<NCM::Component::Systemd::UnitFile>).

It takes as arguments a B<EDG::WP4::CCM::CacheManager::Configuration> instance
C<$config> and a C<$path> to the root of the whole unit tree.

=cut

sub _getTree
{
    my ($self, $config, $path) = @_;

    my $tree = $config->getTree($path);

    # for units, check for file/config, and replace unitfile configuration hashref
    # tree with an element instance (it's what UnitFile needs)

    foreach my $unit (sort keys %$tree) {
        if(exists($tree->{$unit}->{file})) {
            $self->verbose("getTree for unit $unit, replacing file/config with element instance");
            $tree->{$unit}->{file}->{config} = $config->getElement("$path/$unit/file/config");
        }
    }

    return $tree;
}

=pod

=back

=cut

1;
