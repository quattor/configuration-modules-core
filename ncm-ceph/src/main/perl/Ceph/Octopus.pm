#${PMpre} NCM::Component::Ceph::Octopus${PMpost}

=head1 NAME

ncm-${project.artifactId}: Configuration module for CEPH

=head1 DESCRIPTION

Configuration module for CEPH
This is the module for Ceph versions > 15.2.0 and schema version v2 with orchestrator

=head1 IMPLEMENTED FEATURES

Features that are implemented at this moment:

=over

=item * Generating orchestrator yaml files and management of existing cluster (bootstrap not implemented)

=item * Configuration file generation

=item * All daemons should already be adopted for cephadm, and ceph orchestrator should be configured.
        This is either part of the adoption process https://docs.ceph.com/en/latest/cephadm/adoption/
        or by bootstraping a new cluster (see initial creation)

=back

=head1 INITIAL CREATION

- The schema details are annotated in the schema file.

- Example pan files are included in the examples folder and also in the test folders.


To set up the initial cluster, some steps should be taken:

=over

=item 1. The mgr(s) should have passwordless ssh access to all the hosts of the cluster
        e.g. by distributing the public key(s) of the ceph-deploy host(s) over the cluster hosts
            (As described in the cephadm documentation:
                        https://docs.ceph.com/en/latest/cephadm/install/#add-hosts-to-the-cluster)

=item 2. Run the bootstrap command:
        See https://docs.ceph.com/en/latest/cephadm/install/#bootstrap-a-new-cluster

=item 3. You'll need the generated pubkey and admin keyring to distribute over cluster

=item 4. Run the component to start the configuration of the new cluster


=back

=head1 RESOURCES

=head2 /software/components/${project.artifactId}

The configuration information for the component.  Each field should
be described in this section.

=head1 DEPENDENCIES

The component is tested with Ceph version 15.2.8

=cut


use parent qw(NCM::Component NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use NCM::Component::Ceph::Orchestrator;
use Readonly;
use JSON::XS;
use Data::Dumper;
use Text::Glob qw(match_glob);

use LC::Exception;

our $EC = LC::Exception::Context->new->will_store_all;

# Checks if the version of ceph is corresponding with the schema value
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
    return 1;
}

sub Configure
{
    my ($self, $config) = @_;
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    $self->check_versions($t->{ceph_version}) or return 0;

    if ($t->{minconfig}) {
        $self->verbose('Running Ceph configfile component');
        my $cfgin = 'minconfig';
        $self->debug(1, "Using config input from $cfgin");
        my $cfgfile = NCM::Component::Ceph::Cfgfile->new($config, $self, $self->prefix()."/$cfgin");
        $cfgfile->configure() or return;
    }

    my $orch = $t->{orchestrator};

    if ($orch) {
        $self->verbose('Running Ceph orchestrator component');
        my $cluster = NCM::Component::Ceph::Orchestrator->new($config, $self);
        $cluster->configure() or return;
    }

    return 1;
}

1; # Required for perl module!
