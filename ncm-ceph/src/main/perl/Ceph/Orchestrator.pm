#${PMpre} NCM::Component::Ceph::Orchestrator${PMpost}

use parent qw(CAF::Object NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use NCM::Component::Ceph::CfgDb;
use EDG::WP4::CCM::TextRender 20.12.1;
use Readonly;
use JSON::XS;
use Data::Dumper;

Readonly my $CEPH_BOOTSTRAP_CFGFILE => '/etc/ceph/init.conf';
Readonly my @CONFIG_SET => qw(config set);
Readonly my @ORCH_APPLY => qw(orch apply -i);
Readonly my @ORCH_HOST_LS => qw(orch host ls);
Readonly my @ORCH_SECTIONS => qw(mon mgr osd mds); # Sorted for logical deployment
Readonly my @ORCH_SECTIONS_MULTI => qw(hosts mds osd);

sub _initialize
{
    my ($self, $config, $log) = @_;

    $self->{log} = $log;
    $self->{config} = $config;
    $self->{prefix} = $log->prefix()."/orchestrator";
    $self->{tree} = $config->getTree($self->{prefix});

    return 1;
}

# Fail if cluster not ready
sub cluster_ready
{
    my ($self) = @_;

    if ($self->run_ceph_command([qw(status)], 'get cluster status', timeout => 20) &&
        $self->run_ceph_command([qw(orch status)], 'get cluster status', timeout => 20)) {
            $self->debug(1, "Node can reach ceph cluster");
            return 1;
    }
    $self->error("Ceph (orch) not correctly initialized");
    return;
}

# Write config file for bootstrap deployment
sub write_init_cfg
{
    my ($self) = @_;
    my $cfgfile = NCM::Component::Ceph::Cfgfile->new(
        $self->{config}, $self, "$self->{prefix}/initcfg", $CEPH_BOOTSTRAP_CFGFILE, 'ceph');
    if (!$cfgfile->configure()) {
         $self->error('Could not write cfgfile for bootstrap, aborting deployment');
         return;
    }
    $self->debug(1, "Bootstrap config file has been set");
    return 1;

}

# Deploy all config marked for deployment
sub deploy_config
{
    my ($self, $map) = @_;

    $self->debug(5, "deploy hash:", Dumper($map));
    foreach my $section (sort keys(%$map)) {
        foreach my $name (sort keys(%{$map->{$section}})) {
            my $value = $map->{$section}->{$name};
            if (!$self->run_ceph_command([@CONFIG_SET, $section, $name, $value], "setting $section:$name to $value")) {
                $self->error("Could not set configuration option $name in section $section to $value");
                return;
            }
        }
    }
    $self->debug(3, 'Succesfully deployed all config options');
    return 1;
}

# add config settings to centralized config db
sub set_config_db
{
    my ($self) = @_;
    $self->verbose('Deploying configuration');
    my $cfgdb = NCM::Component::Ceph::CfgDb->new($self, $self->{tree}->{configdb});
    # Parse the list and group per section
    my $cfgmap = $cfgdb->get_deploy_config() or return;

    return $self->deploy_config($cfgmap);
}

# write yaml file for specified section and apply to orchestrator
sub deploy_orch_section
{
    my ($self, $section, $ignore) = @_;

    my $yamlfile = "/etc/ceph/orch_$section.yaml";
    my $config = $self->{config}->getElement("$self->{prefix}/cluster/$section");
    my $textmod = grep( /^$section$/, @ORCH_SECTIONS_MULTI ) ? 'yamlmulti' : "yaml";
    $self->debug(5, "Render element for $self->{prefix}/cluster/$section with module $textmod");
    my $trd = EDG::WP4::CCM::TextRender->new($textmod, $config, log => $self);
    my $fh = $trd->filewriter($yamlfile);
    if (!$fh) {
        $self->error("Could not write orchestrator config file $yamlfile: $trd->{fail}");
        return;
    };
    my $changed = $fh->close();
    if ((!$ignore && $changed) || $ignore == 2) {
        return $self->run_ceph_command([@ORCH_APPLY, $yamlfile], "applying $yamlfile");
    }
    $self->info("$yamlfile not changed, not applying to orchestrator");
    return 1;
}

# check hosts are actually in orchestrator and deploy yamlfile accordingly
sub deploy_orch_hosts
{
    my ($self, $config) = @_;

    my ($ec, $jstr) = $self->run_ceph_command([@ORCH_HOST_LS], 'getting hosts in orchestrator') or return;
    my $orchhosts = decode_json($jstr);
    my $hostdb = {};
    foreach my $host (@$orchhosts){
        $hostdb->{$host->{hostname}} = $host;
    }
    my $ignore = 1;
    foreach my $host (keys %$config){
        my $hostname = $config->{$host}->{hostname};
        if (!$hostdb->{$hostname}){
            $self->debug(2, 'missing host, should deploy anyway');
            $ignore = 2;
            last;
        }
    }
    $self->info("Deploying hosts with orchestrator");
    return $self->deploy_orch_section("hosts", $ignore);
}

# Deploy orchestrator yamls for hosts, services, and osds
sub deploy_orchestrator
{
    my ($self) = @_;

    # sections are sorted, especially first the hosts
    if($self->{tree}->{cluster}->{hosts}){
        $self->deploy_orch_hosts($self->{tree}->{cluster}->{hosts}) or return;
    }
    foreach my $section (@ORCH_SECTIONS){
        if($self->{tree}->{cluster}->{$section}){
            $self->info("Deploying $section with orchestrator");
            $self->deploy_orch_section($section) or return;
        }
    }
    return 1;
}

# Apply configdb changes and orchestrator
sub configure
{
    my ($self) = @_;

    $self->cluster_ready() or return;

    if ($self->{tree}->{configdb}) {
        $self->set_config_db() or return;
    }
    $self->deploy_orchestrator();

}

1;
