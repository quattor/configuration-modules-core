#${PMpre} NCM::Component::Ceph::Luminous${PMpost}

use 5.10.1;

use parent qw(NCM::Component NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use NCM::Component::Ceph::OSDserver;
use NCM::Component::Ceph::Cluster;
use Readonly;
use JSON::XS;
use Data::Dumper;
use Text::Glob qw(match_glob);

use LC::Exception;

our $EC=LC::Exception::Context->new->will_store_all;

# Checks if the versions of ceph and ceph-deploy are compatible
sub check_versions {
    my ($self, $qceph, $qdeploy) = @_;
    my ($ec, $cversion) = $self->run_ceph_command([qw(--version)], 'get ceph version');
    my @vl = split(' ',$cversion);
    my $cephv = $vl[2];
    my ($stdout, $deplv) = $self->run_ceph_deploy_command([qw(--version)], 'get ceph-deploy version') if $qdeploy;
    if ($deplv) {
        chomp($deplv);
    }
    if ($qceph && (!match_glob($qceph, $cephv))) {
        $self->error("Ceph version not corresponding! ",
            "Ceph: $cephv, Quattor: $qceph");
        return;
    }        
    if ($qdeploy && (!match_glob($qdeploy, $deplv))) {
        $self->error("Ceph-deploy version not corresponding! ",
            "Ceph-deploy: $deplv, Quattor: $qdeploy");
        return;
    }
    return 1;
}

sub Configure {
    my ($self, $config) = @_;
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    my $netw = $config->getElement('/system/network')->getTree();
    my $hostname = $netw->{hostname};
    $self->debug(5, "Running on host $hostname.");
    $self->check_versions($t->{ceph_version}, $t->{deploy_version}) or return 0;

    if ($t->{config}) {
        my $cfgfile = NCM::Component::Ceph::Cfgfile->new($config, $self, $self->prefix()."/config");
        $cfgfile->configure() or return;
    }

    my $cl = $t->{cluster};
        
    if ($cl && $cl->{deployhosts}->{$hostname}) {
        my $cluster = NCM::Component::Ceph::Cluster->new($config, $self, $self->prefix());
        $cluster->configure() or return;
    }
    
    if ($t->{daemons}) {
        my $osds = NCM::Component::Ceph::OSDserver->new($config, $self, $self->prefix());
        $osds->configure() or return;
    }

    return 1;
}

1; # Required for perl module!
