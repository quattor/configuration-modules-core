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
use EDG::WP4::CCM::Element qw(unescape);
use NCM::Component::Systemd::Systemctl qw(
    systemctl_show
    systemctl_list_units systemctl_list_unit_files
    systemctl_list_deps
    );

use Readonly;

Readonly our $TARGET_DEFAULT   => "default";
Readonly our $TARGET_RESCUE    => "rescue";
Readonly our $TARGET_MULTIUSER => "multi-user";
Readonly our $TARGET_GRAPHICAL => "graphical";
Readonly our $TARGET_POWEROFF  => "poweroff";
Readonly our $TARGET_REBOOT    => "reboot";

# default level (if default.target is not responding)
Readonly our $DEFAULT_TARGET => $TARGET_MULTIUSER;

Readonly::Array my @TARGETS => qw($TARGET_DEFAULT
    $TARGET_RESCUE $TARGET_MULTIUSER $TARGET_GRAPHICAL
    $TARGET_POWEROFF $TARGET_REBOOT);

Readonly our $TYPE_SERVICE => 'service';
Readonly our $TYPE_TARGET  => 'target';
Readonly our $TYPE_MOUNT  => 'mount';
Readonly our $TYPE_SOCKET  => 'socket';
Readonly our $TYPE_TIMER  => 'timer';
Readonly our $TYPE_PATH  => 'path';
Readonly our $TYPE_SWAP  => 'swap';
Readonly our $TYPE_AUTOMOUNT  => 'automount';
Readonly our $TYPE_SLICE  => 'slice';
Readonly our $TYPE_SCOPE  => 'scope';
Readonly our $TYPE_SNAPSHOT  => 'snapshot';

Readonly our $TYPE_SYSV    => $TYPE_SERVICE;

# These are default/fallback and supported types for get_type_cachename
Readonly our $TYPE_DEFAULT => $TYPE_SERVICE;
Readonly::Array my @TYPES_SUPPORTED => (
    $TYPE_SERVICE, $TYPE_TARGET, $TYPE_MOUNT, 
    $TYPE_SOCKET, $TYPE_TIMER, $TYPE_PATH,
    $TYPE_SWAP, $TYPE_AUTOMOUNT, $TYPE_SLICE,
    $TYPE_SCOPE, $TYPE_SNAPSHOT,
);

Readonly::Array my @TYPES => qw($TYPE_SYSV $TYPE_DEFAULT
    $TYPE_SERVICE $TYPE_TARGET $TYPE_MOUNT 
    $TYPE_SOCKET $TYPE_TIMER $TYPE_PATH
    $TYPE_SWAP $TYPE_AUTOMOUNT $TYPE_SLICE
    $TYPE_SCOPE $TYPE_SNAPSHOT
);

# Allowed states: enabled, disabled, masked
# Disabled does not imply OFF (can be started by other
#   enabled service which has the disabled service as dependency)
# Use 'masked' if you really don't want something to be started/running.
# is_ufstate assumes -runtime is not what you want supported.
Readonly our $STATE_ENABLED => "enabled";
Readonly our $STATE_DISABLED => "disabled";
Readonly our $STATE_MASKED => "masked";

Readonly::Array my @STATES => qw($STATE_ENABLED $STATE_DISABLED $STATE_MASKED);

# TODO should match schema default
Readonly our $DEFAULT_STARTSTOP => 1; # startstop true by default
Readonly our $DEFAULT_STATE => $STATE_ENABLED; # state on by default

our @EXPORT_OK = qw($DEFAULT_TARGET $DEFAULT_STARTSTOP $DEFAULT_STATE);
push @EXPORT_OK, @TARGETS, @TYPES, @STATES;

our %EXPORT_TAGS = (
    targets => \@TARGETS,
    types   => \@TYPES,
    states  => \@STATES,
);

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

    return SUCCESS;
}

=pod

=item service_text

Convert service C<detail> hash to human readable string.

Generates errors for missing attributes.

=cut

sub service_text
{
    my ($self, $detail) = @_;

    my $text;
    if(exists($detail->{name})) {
        $text = "service $detail->{name} (";
    } else {
        $self->error("Service detail is missing name");
        return;
    }

    my @attributes = qw(state startstop type fullname targets);
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
            $self->error("Service $detail->{name} details is missing attribute $attr");
        }
    }

    $text .= join(' ', @attrtxt) . ")";

    return $text;
}

=pod

=item current_services

Return hash reference with current configured services
determined via C<make_cache_alias>.

All additional arguments are a list of C<units>
that is passed to C<make_cache_alias>.

This method initialises the cache and alias map if 
empty and updates the cache and map.

=cut

sub current_services
{
    my ($self, @units) = @_;

    # TODO: always update cache?
    if (! defined($unit_cache->{$TYPE_SERVICE}) ||
        ! defined($unit_alias->{$TYPE_SERVICE})) {
        $self->init_cache($TYPE_SERVICE);
    }

    $self->make_cache_alias($TYPE_SERVICE, @units);

    my %current;

    # Dangerous to use unit_cache and 'each' here. 
    # Lots of calls can lead to an update of the hash, 
    # which results in undefined behaviour for 'each'
    foreach my $name (sort keys %{$unit_cache->{$TYPE_SERVICE}}) {
        my $data = $unit_cache->{$TYPE_SERVICE}->{$name};
        my $detail = {name => $name, type => $TYPE_SERVICE};

        # TODO: can we refine this somehow? Or does it make no sense.
        $detail->{startstop} = $DEFAULT_STARTSTOP;

        my $show = $data->{show};
        if(! defined($show)) {
            if ($data->{baseinstance}) {
                $self->verbose("Base instance $name is not an actual runnable service. Skipping.");
            } elsif(@units) {
                # Lots of units that have no show data, because they aren't queried all.
                $self->verbose("Found name $name without any show data; ",
                               "only selected units were queried. Skipping.");
            } else {
                $self->error("Found name $name without any show data. Skipping.");
            }
            next;
        }

        $detail->{fullname} = $show->{Id};

        my $load = $show->{LoadState};
        my $active = $show->{ActiveState};
        my $substate = $show->{SubState};

        $self->debug(1, "Found service unit $detail->{name} with ",
                       "LoadState $load ActiveState $active");

        # Intentionally not using the full recursive list from get_wantedby method
        my $wanted = $show->{WantedBy};
        $detail->{targets} = [];
        if (defined($wanted)) {
            # TODO resolve further implied targets (a.k.a reverse dependencies)?
            #   e.g. if multi-user.target is wanted-by graphical.target, do we add
            #   graphical.target here too?
            foreach my $target (@$wanted) {
                # strip .target (but there can be non .target reverse dependencies)
                $target =~ s/\.target$//;
                push(@{$detail->{targets}}, $target);
            }
        } else {
            $self->verbose("No WantedBy defined for service unit $detail->{name}");
        }

        # This can return other states then the enabled/disabled/masked.
        my ($ufstate, $derived) = $self->get_ufstate($detail->{fullname});
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

        $self->debug(1, "current_services added unit file service $detail->{name}");
        $self->debug(2, "current_services added unit file ", $self->service_text($detail));
        $current{$name} = $detail;
    }

    return \%current;
}

=pod

=item current_target

Return the current target.

TODO: implement this. systemctl list-units --type target
lists all current targets (yes, with an s).

=cut

=pod

=item default_target

Return the default target.

=cut

sub default_target
{
    my ($self) = @_;

    my $default = "$TARGET_DEFAULT.target";

    # TODO: use cache?
    my $show = systemctl_show($self, $default);

    my $id = $show->{Id};

    if ($id) {
        $self->verbose("Default target based on $default corresponds with Id $id");
    } else {
        $self->error("Can't determine default target based on $default. Using $DEFAULT_TARGET as fall-back.");
        $id = $DEFAULT_TARGET;
    }

    $id =~ s/\.target$//;

    return $id;
}

=pod

=item configured_services

C<configured_services> parses the C<tree> hash reference and builds up the
services to be configured. It returns a hash reference with key the service name and
values the details of the service.

(C<tree> is typically C<$config->getElement('/software/components/systemd/service')->getTree>.)

=cut

sub configured_services
{
    my ($self, $tree) = @_;

    my %services;

    while (my ($service, $detail) = each %$tree) {
        # only set the name (not mandatory in new schema, to be added here)
        $detail->{name} = unescape($service) if (! exists($detail->{name}));

        # all new services are assumed type service
        $detail->{type} = $TYPE_SERVICE if (! exists($detail->{type}));

        # Suffix the type if no suffix is found
        $detail->{fullname} = $detail->{name};
        my $pat = '\.'.$detail->{type}.'$';
        # TODO: '.' should be encoded with systemd tool (if exists?)
        $detail->{fullname} .= ".$detail->{type}" if ($detail->{fullname} !~ m/$pat/);

        $self->verbose("Add service name $detail->{name} (service $service)");
        $self->debug(1, "Add ", $self->service_text($detail));

        $services{$detail->{name}} = $detail;
    }

    # TODO figure out a way to specify what off-targets and what on-targets mean.
    # If on is defined, all other targets are off
    # If off is defined, all others are on or also off? (2nd case: off means off everywhere)

    return \%services;
}

=pod

=head2 get_aliases

Given a arrayref of C<units>, return a hashref with key the unit (from the list) that is an 
alias for another unit (not necessarily from the list); and the other unit's fullname 
is the value.

The C<unit_alias> cache is used for lookup.

Supported options

=over

=item force

The force flag is passed to the C<fill_cache> method

=item type

The type flag is passed to the C<get_type_cachename> method.

=back

=cut

sub get_aliases
{
    my ($self, $units, %opts) = @_;
    
    my $res = {};

    $self->fill_cache($opts{force}, @$units);

    foreach my $unit (@$units) {
        my ($type, $cname) = $self->get_type_cachename($unit, $opts{type});
        
        my $realname = $unit_alias->{$type}->{$cname};
        if($realname ne $cname) {
            $self->verbose("Unit $unit ($cname) is an alias for $realname");
            $res->{$unit} = "$realname";
        }
    }
    
    return $res;
}

=pod

=back

=head2 Private methods

=over

=item init_cache

(Re)Initialise all unit caches. If a C<type> is specified,
only those cache will be (re)initialised.

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
    my ($self, $type) = @_;

    if(defined $type) {
        $self->verbose("Initialisation of all caches for type $type.");

        # reset unit_cache and alias for current type
        $unit_cache->{$type} = {};
        $unit_alias->{$type} = {};

        $self->verbose("Type $type initiliasation of dependency_cache not supported.");
    } else {
        $self->verbose("Initialisation of all caches.");

        $unit_cache = {
            service => {},
            target => {}
        };

        $unit_alias = {
            service => {},
            target => {}
        };

        $dependency_cache = {
            deps => {},
            rev => {},
        };
    }

    # For unittesting
    return $unit_cache, $unit_alias, $dependency_cache;
}

=pod

=item get_type_cachename

C<get_type_cachename> returns the type and cache name based on the
C<unit> and optional C<type>.

If the C<type> is not specified, it will be derived using the supported types.
If the type can't be determined this way, the default type will be used.

=cut

sub get_type_cachename
{
    my ($self, $unit, $type) = @_;

    my $treg = '\.(' . join('|', @TYPES_SUPPORTED) . ')$';
    if ($type) {
        $self->debug(1, "get_type_cachename: set type $type for unit $unit.");
    } elsif ($unit =~ m/$treg/) {
        $type = $1;
        $self->debug(1, "get_type_cachename: found type $type based on unit $unit.");
    } else {
        $type = $TYPE_DEFAULT;
        $self->verbose("get_type_cachename: could not determine type based on unit $unit ",
                       "and pattern $treg. Using default type $type.");
    }

    # The cache unit name
    my $cname = $unit;
    my $reg = '\.'.$type.'$';
    $cname =~ s/$reg//;

    return $type, $cname;
}


=pod

=item make_cache_alias

(Re)generate the C<unit_cache> and C<unit_alias> map
based on current units and unitfiles for C<type>.

Details for each unit from C<units> are also added.
If C<relevant_units> is empty/undef, all found units and unitfiles
are. Units without a type specifier are assumed of type
C<type>.

Each found unit is also added as it's own alias.

Supported types are C<service> and C<target>.

Returns the generated cache and alias map for unittesting purposes.

=cut

sub make_cache_alias
{
    my ($self, $type, @relevant_units) = @_;

    my $treg = '^(' . join('|', @TYPES_SUPPORTED) . ')$';
    if (!($type && $type =~ m/$treg/)) {
        $self->error("Undefined or wrong type $type for systemctl list-unit-files / list-units");
        return;
    }

    my $list_units = systemctl_list_units($self, $type);
    my $list_unit_files = systemctl_list_unit_files($self, $type);

    # Join them, keep data
    while (my ($name, $data) = each %$list_units) {
        $unit_cache->{$type}->{$name}->{unit} = $data;
    }
    while (my ($name, $data) = each %$list_unit_files) {
        $unit_cache->{$type}->{$name}->{unit_file} = $data;
    }

    # Unknown names, to be checked if aliases
    my @units;
    if (@relevant_units) {
        foreach my $name (@relevant_units) {
            # tmptype should be equal too type
            # cname is the unit name in the cache
            my ($tmptype, $cname) = $self->get_type_cachename($name, $type);
            push(@units, $cname);
        }
    } else {
        @units = sort keys %{$unit_cache->{$type}};
    }

    my @unknown;
    foreach my $name (@units) {
        my $data = $unit_cache->{$type}->{$name};

        if (! defined $data) {
            # no entry in cache from units or unitfiles
            $self->error("Trying to add details of unit $name type $type ",
                         "but no entry in cache after adding all units and unitfiles. ",
                         "Ignoring this unit.");
            next;
        }

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
                $self->debug(1, "Name $name is an instance ($instance)");
                # TODO: use systemd-escape -u to decode the instance name?
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
                $self->debug(1, "Added type $type name $name to cache.");
            } else {
                $self->verbose("Found id $id that doesn't match name $name. ",
                               "Adding as unknown and skipping further handling.");
                # in particular, no aliases are processed/followed
                # not to risk anything being overwritten

                # add the real name to the list of units to check
                # TODO potential issue for infinite loop because the type is removed?
                if(! grep {$id eq $_} @units) {
                    $self->verbose("Adding the id $id from unkown name $name to list of units");
                    push(@units, $id);
                };

                push(@unknown, [$name, $id, $show]);
                next;
            }
        } else {
            $self->error("Found Id $show->{Id} for name $name type $type that ",
                         "doesn't match expected pattern '$pattern'. ",
                         "Skipping this unit.");
            next;
        }

        # All Names, incl the unit itself
        foreach my $alias (@{$show->{Names}}) {
            if ($alias =~ m/$pattern/) {
                $unit_alias->{$type}->{$1} = $id;
                $self->debug(1, "Added type $type alias $1 of id $id to map.");
            } else {
                $self->error("Found alias $alias that doesn't match expected pattern '$pattern'. Skipping.");
            }
        }
    }

    # Check the unknowns (this completes the aliases)
    foreach my $unknown (@unknown) {
        my ($name, $id, $show) = @$unknown;

        my $realname = $unit_alias->{$type}->{$name};
        if(defined $realname) {
            $self->debug(1 ,"Unknown $name / $id is an alias for $type $realname");
        } else {
            # Most likely the realname does not list this name in its Names list
            # Maybe this is an alias of an alias? (We don't process the aliases,
            # so their aliases are not added)
            # TODO: add it as alias or always error?
            my $realid = $unit_alias->{$type}->{$id};
            if (defined $realid) {
                my $cache = $unit_cache->{$type}->{$realid};
                if ($cache->{baseinstance}) {
                    $self->verbose("Unknown $name / $id is $type base instance and has missing alias entry.",
                                   " Adding it.");
                } else {
                    my $realshow = $cache->{show};
                    $self->verbose("Unknown $name / $id has missing $type alias entry. Adding it.",
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

    # Check if each alias' real name has an existing entry in cache
    while (my ($alias, $name) = each %{$unit_alias->{$type}} ) {
        if($alias ne $name && exists($unit_cache->{$type}->{$alias})) {
            # removing any aliases that got in the unit_cache
            $self->debug(1, "Removing alias $alias of $name from $type cache");
            delete $unit_cache->{$type}->{$alias};
        }

        if (! defined $unit_cache->{$type}->{$name}) {
            $self->error("Real unit $name.$type of alias $alias has no entry in $type cache");
            next;
        }

    }

    # For unittesting purposes
    return $unit_cache->{$type}, $unit_alias->{$type};
}


=pod

=item fill_cache

Fill the unit_cache and unit_alias map for the C<units> provided.
The type of the unit is derived using the C<get_type_cachename> method.

The cache is updated via the C<make_cache_alias> method if the unit
is missing from the unit_alias map or if C<force> is true.

=cut

sub fill_cache
{
    my ($self, $force, @units) = @_;

    my %update = map { $_ => [] } @TYPES_SUPPORTED;

    foreach my $unit (@units) {
        my ($type, $cachename) = $self->get_type_cachename($unit);
        # Only update the cache if force=1 or the unit is not in the unit_alias cache
        if ($force || (! defined($unit_alias->{$type}->{$cachename}))) {
            # use full name, not cachename (both should work though)
            push(@{$update{$type}}, $unit);
        };
    }

    foreach my $type (@TYPES_SUPPORTED) {
        my @type_units = @{$update{$type}};
        if (@type_units) {
            $self->verbose("fill_cache: type $type units ", join(", ", @type_units));
            $self->make_cache_alias($type, @type_units);
        }
    }

    # for unittests only
    return \%update;
}

=pod

=item get_unit_show

Return the show C<attribute> for C<unit> from the
unit_cache and unit_alias map.

Supported options

=over

=item force

Force cache refresh.

=item 

Specify the C<type> of the unit (passed to C<get_type_cachename>).

=back

=cut

sub get_unit_show
{
    my ($self, $unit, $attribute, %opts) = @_;

    my $force = exists($opts{force}) ? $opts{force} : 0;

    my ($type, $cname) = $self->get_type_cachename($unit, $opts{type});

    if ($force) {
        $self->verbose("get_unit_show force updating the cache for ",
                       "unit $unit and type $type.");
        $self->make_cache_alias($type, $unit);
    }

    my $realname = $unit_alias->{$type}->{$cname};
    if(! defined($realname)) {
        $self->error("get_unit_show: no alias for unit $unit (cname $cname) defined. (Forgot to update cache?)");
        return;
    }
    $self->debug(1, "get_unit_show found realname $realname for cname $cname");

    my $unittxt = "unit $unit";
    if ($unit ne "$cname.$type") {
        $unittxt .= " cname $cname";
    }
    if ($realname ne $cname) {
        $unittxt .= " realname $realname";
    }

    my $val = $unit_cache->{$type}->{$realname}->{show}->{$attribute};

    $self->verbose("get_unit_show $unittxt attribute $attribute value ",
                   defined($val) ? "$val" : "<undefined>");

    return $val;
}

=pod

=item get_wantedby

Return a hashref of all units that "want" C<service>
(hashref is used for easy lookup; the key is the full unit
name, the value is a boolean).

Any unit can be passed as C<service>; but in
absence of a type specifier C<service> will be used.

It uses the dependecy_cache for reverse dependencies

Supported options

=over

=item force

Force cache update.

=item ignoreself

By default, the reverse dependency list conatins the unit itself too.
With C<ignoreself> true, the unit itself is not returned 
(but stored in cache).

=back

=cut

sub get_wantedby
{
    my ($self, $service, %opts) = @_;

    my $force = exists($opts{force}) ? $opts{force} : 0;

    if($service !~ m/\.\w+$/) {
        $service .= ".$TYPE_SERVICE";
    }

    # Try lookup from reverse cache.
    # If not found in cache, look it up via systemctl_list_deps
    # with reverse enabled.
    if($force || (! defined($dependency_cache->{rev}->{$service}))) {
        $self->debug(1, "get_wantedby: force / no cache for dependency for service $service.");
        my $deps = systemctl_list_deps($self, $service, 1);
        if (! defined($deps)) {
            # In case of failure.
            $self->error("get_wantedby: systemctl_list_deps for unit $service and reverse=1 returned undef. ",
                         "Returning empy hashref here, not storing it in cache.");
            return {};
        }

        $dependency_cache->{rev}->{$service} = $deps;
    } else {
        $self->debug(1, "Dependency for service $service in cache.");
    }

    # Make copy (shallow is ok, values are 1s)
    my $res = { %{$dependency_cache->{rev}->{$service}} };

    if ($opts{ignoreself}) {
        delete $res->{$service};
    }

    return $res;
}

=pod

=item is_wantedby

Return if C<service> is wanted by C<target>.

Any unit can be passed as C<service> or C<target>; but in
absence of a type specifier resp. C<service> and C<target> will
be used.

It uses the C<get_wantedby> method for the dependency lookup.

Supported options

=over

=item force

Force cache update (passed to C<get_wantedby>).

=back

=cut

sub is_wantedby
{
    my ($self, $service, $target, %opts) = @_;

    if($target !~ m/\.\w+$/) {
        $target .= ".$TYPE_TARGET";
    }

    my $wantedby = $self->get_wantedby($service, force => $opts{force});

    my $res = $wantedby->{$target};

    $self->verbose("Service $service is ", $res ? "" : " not ", "wanted by target $target");

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

=item type

Specify the C<type> of the unit (passed to C<get_unit_show>).

=back

=cut

sub is_active
{
    my ($self, $unit, %opts) = @_;

    my $sleep = exists($opts{sleep}) ? $opts{sleep} : 1;
    my $max = exists($opts{max}) ? $opts{max} : 3;

    $self->verbose("Running is_active (sleep=$sleep max=$max)");

    my $unittxt = "unit $unit";

    my $active = $self->get_unit_show($unit, 'ActiveState', 
                                      force => $opts{force}, type => $opts{type});
    if (! defined($active)) {
        $self->error("is_active no ActiveState for $unittxt found.");
        return;
    }

    # Possible ActiveState values from systemd dbus interface
    # http://www.freedesktop.org/wiki/Software/systemd/dbus/

    my @inter = qw(reloading activating deactivating);

    my $tries = 0;
    while ((grep {$_ eq $active} @inter)) {
        my $msg = "the cache for the $unittxt due to intermittent state $active";
        if ($tries < $max) {
            sleep($sleep);
            $active = $self->get_unit_show($unit, 'ActiveState', force => 1);
            if (! defined($active)) {
                $self->error("is_active no ActiveState for $unittxt found ($tries of max $max).");
                return;
            }
            $self->verbose("is_active updating $msg. New state $active.");
            $tries++;
        } else {
            # Map the intermediate states to a final state.
            # We are going to assume all will be fine.
            if($active eq 'deactivating') {
                $active = 'inactive';
            } else {
                $active = 'active';
            }
            $self->verbose("is_active max tries for updating $msg. Forced mapping to $active.");
        }
    }

    # Must be one of the final states now.
    my @final = qw(active inactive failed);
    if (grep {$_ eq $active} @final) {
        my $msg = "is_active: active $active for $unittxt, is_active ";
        if ($active eq 'active') {
            $self->verbose("$msg true");
            return 1;
        } else {
            $self->verbose("$msg false");
            return 0;
        }
    } else {
        $self->error("is_active: unsupported ActiveState $active. ",
                     "(Component version too old?)");
        return;
    }
}

=pod

=item get_ufstate

Return the state of the C<unit> using the UnitFileState and
the derived state from the state of the WantedBy units.

The returned state can be more then the usual supported states (e.g. static).

The following options are supported

=over

=item force

Force cache refresh (passed to C<get_unit_show> and C<fill_cache>)

=back

=cut

sub get_ufstate
{
    my ($self, $unit, %opts) = @_;

    $self->verbose("get_ufstate for unit $unit");

    my $ufstate = $self->get_unit_show($unit, 'UnitFileState', force => $opts{force});

    # The derived state is based on the ufstate of any of the WantedBy units
    # Using the recursive reverse dependecy list rather than
    # walking the ->{show}->{WantedBy} attribute tree ourself.
    # TODO: For now, it can only be STATE_ENABLED or STATE_DISABLED.

    my $wantedby = $self->get_wantedby($unit, ignoreself => 1);

    my $derived;
    if ($wantedby) {
        $self->fill_cache($opts{force}, keys %$wantedby);
        foreach my $wunit (sort keys %$wantedby) {
            my $wufstate = $self->get_unit_show($wunit, 'UnitFileState', force => $opts{force});
            if (! defined($wufstate)) {
                $self->verbose("Undefined UnitFileState for unit $wunit");
                next;
            } elsif ($wufstate eq $STATE_ENABLED) {
                $derived = $STATE_ENABLED;
                $self->verbose("get_ufstate: unit $unit found wantedby unit $wunit in state $STATE_ENABLED. ",
                               "Setting derived state to $derived.");
                # TODO: break or check all of them?
            } else {
                $self->verbose("get_ufstate: unit $unit found wantedby unit $wunit in state $wufstate.");
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
UnitFile state of C<unit> matches the (simplified) C<state>.

An error is logged  and undef returned if the unit can't be queried.

The following options are supported

=over

=item force
=item type

Both C<force> and C<type> are passed to C<get_ufstate> method.

=back

=cut

sub is_ufstate
{
    my ($self, $unit, $state, %opts) = @_;

    $self->verbose("is_ufstate for unit $unit and state $state");

    my ($ufstate, $derived) = $self->get_ufstate($unit, type => $opts{type}, force => $opts{force});

    if(! $ufstate) {
        $self->verbose("No ufstate could be determined. Using derived state $derived.");
        $ufstate = $derived;
        
        if(! $ufstate) {
            $self->error("is_ufstate: unable to use ufstate.");
            return;
        };
    };

    # Possible UnitFileState values from systemd dbus interface
    # http://www.freedesktop.org/wiki/Software/systemd/dbus/

    my $msg = "is_ufstate: unit $unit with UnitFileState '$ufstate'";
    if ($state eq $ufstate) {
        $self->verbose("$msg as wanted.");
        return 1;
    }

    # possible states:
    #   enabled, enabled-runtime, linked, linked-runtime, masked, masked-runtime, static, disabled, invalid

    # static units shouldn't be enabled/or disabled, they are static because they
    # are required by another unit (and will be started when the other unit is).
    # (the unit-file misses the [Install] section)
    # we can force enable/disable/mask them by symlinking, but we shouldn't.
    # TODO: support expert mode that allows this.
    elsif ($ufstate eq 'static') {
        $self->info("$msg is a static unit. ",
                    "Not going to force the state to $state and assume this is ok.");
        return 1;
    }

    # warn for invalid states (although not much can be done about it)
    elsif ($ufstate eq 'invalid') {
        $self->warn("$msg uncertain/unsupported behaviour. Assuming this is not the state $state.");
        return 0;
    }

    # linked states: try to resolve the symlink? is this expert mode?
    # TODO: this is a serious assumption.
    elsif ($ufstate eq 'linked') {
        $self->warn("$msg uncertain/unsupported behaviour. Assuming this is the state $state.");
        return 1;
    }

    # all -runtime are non-permanent, so not supported here.
    elsif ($ufstate =~ m/-runtime$/) {
        $self->info("$msg is non-permanent and thus not the wanted state $state.");
        return 0;
    }

    # the rest
    else {
        $self->verbose("$msg not the wanted state $state.");
        return 0;
    }
}

=pod

=back

=cut

1;
