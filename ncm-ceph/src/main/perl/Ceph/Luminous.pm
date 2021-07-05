#${PMpre} NCM::Component::Ceph::Luminous${PMpost}

=head1 NAME

ncm-${project.artifactId}: Configuration module for CEPH

=head1 DESCRIPTION

Configuration module for CEPH
This is the module for Ceph versions > 12.2.2 and schema version v2

=head1 IMPLEMENTED FEATURES

Features that are implemented at this moment:

=over

=item * Creating cluster (manual step involved)

=item * Set admin hosts for monitors

=item * Configuration file generation

=item * Checking/adding Monitors and Managers on deployhost

=item * Checking/adding OSDs per OSD host

=item * Checking/adding MDSs on deployhost

=item * Wildcard support in version numbers

=back

The implementation has some safety features. Therefore:

=over

=item * The config of MON, OSD and MDSs are first checked. If no errors were found, the actual changes will be deployed.

=item * No removals of MONs, OSDs or MDSs are done. No zapping of disks is implemented.

=item * When something is not right and returns an error, the whole component exits.

=item * You can set the version of ceph and ceph-deploy in the Quattor scheme. The component will then only run if the versions of ceph and ceph-deploy match with those versions.

=back

=head1 INITIAL CREATION

- The schema details are annotated in the schema file.

- Example pan files are included in the examples folder and also in the test folders.


To set up the initial cluster, some steps should be taken:

=over

=item 1. First create a ceph user on all the hosts, using ceph-user.pan

=item 2. The deployhost(s) should have passwordless ssh access to all the hosts of the cluster
        e.g. by distributing the public key(s) of the ceph-deploy host(s) over the cluster hosts
            (As described in the ceph-deploy documentation:
                        http://ceph.com/docs/master/start/quick-start-preflight/)

=item 3. The user should be able to run commands with sudo without password included in sudo.pan

=item 4. Run the component a first time.
            It shall fail, but you should get the initial command for your cluster

=item 5. Run this command

=item 6. Run the component again to start the configuration of the new cluster

=item 7. When the component now runs on OSD servers, it will deploy the local OSDs

=back

=head1 RESOURCES

=head2 /software/components/${project.artifactId}

The configuration information for the component.  Each field should
be described in this section.

=head1 DEPENDENCIES

The component is tested with Ceph version 12.2.2 and ceph-deploy version 1.5.39.


=cut


use parent qw(NCM::Component NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use NCM::Component::Ceph::OSDserver;
use NCM::Component::Ceph::Cluster;
use Readonly;
use JSON::XS;
use Data::Dumper;
use Text::Glob qw(match_glob);

use LC::Exception;

our $EC = LC::Exception::Context->new->will_store_all;

# Checks if the versions of ceph and ceph-deploy are corresponding with the schema values
sub check_versions
{
    my ($self, $qceph, $qdeploy) = @_;
    my ($ec, $cversion) = $self->run_ceph_command([qw(--version)], 'get ceph version');
    my @vl = split(' ', $cversion);
    my $cephv = $vl[2];
    if ($qceph && (!match_glob($qceph, $cephv))) {
        $self->error("Ceph version not corresponding! ",
            "Ceph: $cephv, Quattor: $qceph");
        return;
    }
    if ($qdeploy){
        my ($stdout, $deplv) = $self->run_ceph_deploy_command([qw(--version)], 'get ceph-deploy version');
        if ($deplv) {
            chomp($deplv);
        }
        if (!match_glob($qdeploy, $deplv)) {
            $self->error("Ceph-deploy version not corresponding! ",
                "Ceph-deploy: $deplv, Quattor: $qdeploy");
            return;
        }
    }
    return 1;
}

sub Configure
{
    my ($self, $config) = @_;
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    my $netw = $config->getElement('/system/network')->getTree();
    my $hostname = $netw->{hostname};
    $self->check_versions($t->{ceph_version}, $t->{deploy_version}) or return 0;

    if ($t->{minconfig} || $t->{config}) {
        $self->verbose('Running Ceph configfile component');
        my $cfgin = $t->{minconfig} ? 'minconfig' : 'config';
        $self->debug(1, "Using config input from $cfgin");
        my $cfgfile = NCM::Component::Ceph::Cfgfile->new($config, $self, $self->prefix()."/$cfgin");
        $cfgfile->configure() or return;
    }

    my $cl = $t->{cluster};

    if ($cl && $cl->{deployhosts}->{$hostname}) {
        $self->verbose('Running Ceph cluster component');
        my $cluster = NCM::Component::Ceph::Cluster->new($config, $self, $self->prefix());
        $cluster->configure() or return;
    }

    if ($t->{daemons}) {
        $self->verbose('Running Ceph OSD component');
        my $osds = NCM::Component::Ceph::OSDserver->new($config, $self, $self->prefix());
        $osds->configure() or return;
    }

    return 1;
}

1; # Required for perl module!
