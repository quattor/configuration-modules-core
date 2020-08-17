#${PMpre} NCM::Component::Ceph::CfgDb${PMpost}

use parent qw(CAF::Object);
use Readonly;
use Data::Dumper;
use JSON::XS;
use EDG::WP4::CCM::Path qw(escape unescape);
Readonly my @CONFIG_DUMP => qw(config dump);


sub _initialize
{
    my ($self, $clusterobj) = @_;

    $self->{log} = $clusterobj;

    $self->{ceph} = {};

    $self->{Cluster} = $clusterobj;
    $self->{quattor} = $clusterobj->{cluster}->{configdb};

    $self->{deploy} = {};
    return 1;
}

# add a config value to the map to deploy
sub add_section
{
    my ($self, $secname, $section) = @_;
    $self->{deploy}->{$secname} = $section;
    return 1;
}

# add a config value to the map to deploy
sub add_config
{
    my ($self, $section, $name, $value) = @_;
    $self->{deploy}->{$section}->{$name} = $value;
    return 1;
}

# Add a config entry to the existing config map
sub add_existing_cfg
{
    my ($self, $section, $name, $cfg) = @_;
    # for now only value field
    $self->{ceph}->{$section}->{$name} = $cfg->{value};
    return 1;
};

# Fill in the map with existing daemons
sub get_existing_cfg
{
    my ($self) = @_;
    my ($ec, $jstr) = $self->{Cluster}->run_ceph_command([@CONFIG_DUMP], 'get config map', nostderr => 1) or return;
    my $configdb = decode_json($jstr);
    foreach my $cfg (@{$configdb}){
        $self->add_existing_cfg($cfg->{section}, $cfg->{name}, $cfg);
    }
    $self->debug(5, "Existing ceph hash:", Dumper($self->{ceph}));
    return 1;
}

# Compare all config of one section
sub compare_section
{
    my ($self, $section) = @_;

    my %qt = %{$self->{quattor}->{$section}};
    my %ceph = %{$self->{ceph}->{$section}};

    foreach my $escname (sort keys %qt) {
        my $name = unescape($escname);
        if ($ceph{$name}){
            if ($qt{$name} ne $ceph{$name}){
                $self->verbose("Changing $section config option $name from $ceph{name} to $qt{name}");
                $self->add_config($section, $name, $qt{$name});
            };
            delete $ceph{$name};
        } else {
            $self->verbose("Adding $section config option $name: $qt{name}");
            $self->add_config($section, $name, $qt{$name});
        }
    }
    if (%ceph) {
        $self->warning("Found deployed config not found in profile: ", join(',', sort keys(%ceph)));
    }
    return 1;
}

# config not existing, add config to deploy
# report leftovers
sub compare_config_maps
{
    my ($self) = @_;
    my %qt = %{$self->{quattor}};
    my %ceph = %{$self->{ceph}};
    foreach my $section (sort keys %qt) {
        if ($ceph{$section}){
            $self->compare_section($section);
            delete $ceph{$section};
        } else {
            $self->add_section($section, $qt{$section});
        };
    }
    if (%ceph) {
        $self->warn('Found deployed section config that is not in profile: ', sort keys(%ceph));
    }
    return 1;
}

# return the map that can be used to deploy new daemons
sub get_deploy_config
{
    my ($self) = @_;
    $self->get_existing_cfg() or return;
    $self->compare_config_maps();
    return $self->{deploy};
}

1;
