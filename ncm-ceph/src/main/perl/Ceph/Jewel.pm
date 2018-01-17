#${PMpre} NCM::Component::Ceph::Jewel${PMpost}

# This component needs a 'ceph' user.
# The user should be able to run these commands with sudo without password:
# /usr/bin/ceph-deploy
# /usr/bin/python -c import sys;exec(eval(sys.stdin.readline()))
# /usr/bin/python -u -c import sys;exec(eval(sys.stdin.readline()))
# /bin/mkdir
#


=head1 NAME

ncm-${project.artifactId}: Configuration module for CEPH

=head1 DESCRIPTION

Configuration module for CEPH
This is the old, deprecated version of the component for older versions of ceph

=head1 IMPLEMENTED FEATURES

Features that are implemented at this moment:

=over

=item * Creating cluster (manual step involved)

=item * Set admin hosts and push config

=item * Fine configuration control (per daemon and/or host)

=item * Tollerates unreachable new or marked-for-deletion hosts

=item * Checking/adding/removing Monitors

=item * Checking/adding/removing OSDs

=item * Checking/adding/removing MDSs

=item * Building up/changing a crushmap, with support for erasure code

=item * OSD based objectstore

=item * Wildcard support in version numbers

=back

The implementation keeps safety as top priority. Therefore:

=over

=item * The config of MON, OSD and MDSs are first checked completely. Only if no errors were found, the actual changes will be deployed.

=item * No removals of MONs, OSDs or MDSs are actually done at this moment. Instead of removing itself, it prints the commands to use.

=item * Configfiles and decompiled crushmap files are saved into a git repo. This repo can be found in the 'ncm-ceph' folder in the home directory of the ceph user

=item * When something is not right and returns an error, the whole component exits.

=item * You can set the version of ceph and ceph-deploy in the Quattor scheme. The component will then only run if the versions of ceph and ceph-deploy match with those versions.

=back

=head1 INITIAL CREATION

- The schema details are annotated in the schema file.

- Example pan files are included in the examples folder and also in the test folders.


To set up the initial cluster, some steps should be taken:

=over

=item 1. First create a ceph user on all the hosts.

=item 2. The deployhost(s) should have passwordless ssh access to all the hosts of the cluster
        e.g. by distributing the public key(s) of the ceph-deploy host(s) over the cluster hosts
            (As described in the ceph-deploy documentation:
                        http://ceph.com/docs/master/start/quick-start-preflight/)

=item 3. Run the component a first time.
            It shall fail, but you should get the initial command for your cluster

=item 4. Run this command

=item 5. Run the component again to start the configuration of the new cluster

=back

=head1 RESOURCES

=head2 /software/components/${project.artifactId}

The configuration information for the component.  Each field should
be described in this section.

=head1 DEPENDENCIES

The component is tested with Ceph version 0.84-0.89 and ceph-deploy version 1.5.11 and 1.5.21.
Note: ceph-deploy versions 1.5.12-20 contain a bug where gatherkeys returned a wrong exitcode, which
caused a wrong error message in ncm-ceph. This is solved again in 1.5.21 .

This version of Data-Compare can be found on http://www.city-fan.org/ftp/contrib/perl-modules/

Attention: Some repositories (e.g. rpmforge) are shipping some versions like 1.2101 and 1.2102.


=cut

use 5.10.1;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use base qw(NCM::Component NCM::Component::Ceph::commands NCM::Component::Ceph::crushmap
    NCM::Component::Ceph::daemon NCM::Component::Ceph::config NCM::Component::Ceph::compare );

use LC::Exception;
use LC::Find;
use LC::File qw(makedir);

use File::Path qw(make_path);
use File::Copy qw(copy move);
use Git::Repository;
use JSON::XS;
use Text::Glob qw(match_glob);
our $EC=LC::Exception::Context->new->will_store_all;

# Initiates gitrepo
sub init_git {
    my ($self, $qdir) = @_;
    if (!-d "$qdir/.git"){
        Git::Repository->run( init => $qdir );
    } # Access with my $gitr = Git::Repository->new( work_tree => $qdir );
}

# Make sure  a temporary directory is created for push and pulls
sub init_qdepl {
    my ($self, $config, $cephusr) = @_;
    my $qdir = $cephusr->{homeDir} . '/ncm-ceph/';
    my $crushdir = $qdir . 'crushmap/' ;
    make_path($qdir, $crushdir, {owner=>$cephusr->{uid}, group=>$cephusr->{gid}, error => \my $err});
    if (@$err) {
        $self->error("make_path returned errors:");
        for my $diag (@$err) {
            my ($file, $message) = %$diag;
            $self->error("file $file: $message");
        }
        return 0;
    }
    $self->init_git($qdir);
    return $qdir;
}

# Checks if cluster is configured on this node.
sub cluster_exists_check {
    my ($self, $cluster, $gvalues) = @_;
    # Check If something is not configured or there is no existing cluster
    my $cephusr = $gvalues->{cephusr};
    my $key_accept = $gvalues->{key_accept};
    my $hosts = $cluster->{config}->{mon_host};
    my $ok= 0;
    my $okhost;
    foreach my $host (@{$hosts}) {
        if ($key_accept) {
            $self->ssh_known_keys($host, $key_accept, $cephusr);
        }
        if ($self->run_ceph_deploy_command([qw(gatherkeys), $host])) {
            $ok = 1;
            $okhost = $host;
            last;
        }
    }
    if (!$ok) {
        # Manual commands for new cluster
        # Run command with ceph-deploy for automation,
        # but take care of race conditions

        my @newcmd = qw(new);
        foreach my $host (@{$hosts}) {
            push (@newcmd, $host);
        }
        if (!-f "$cephusr->{homeDir}/$gvalues->{clname}.mon.keyring"){
            $self->run_ceph_deploy_command([@newcmd]);
        }
        $self->info("To create a new cluster, run this command");
        my $moncr = $self->run_ceph_deploy_command([qw(mon create-initial)],'','',1);
        $self->print_cmds([$moncr]);
        return 0;
    } else {
        return 1;
    }
}

# Fail if cluster not ready and no deploy hosts
sub cluster_ready_check {
    my ($self, $cluster, $is_deploy, $hostname) = @_;

    if (!$self->run_ceph_command([qw(status)])) {
        if ($is_deploy) {
            my @admin = ('admin', $hostname);
            $self->run_ceph_deploy_command(\@admin);
            if (!$self->run_ceph_command([qw(status)])) {
                # This should not happen
                $self->error("Cannot connect to ceph cluster!");
                return 0;
            } else {
                $self->debug(1,"Node ready to receive ceph-commands");
            }
        } else {
            $self->error("Cluster not configured and no ceph deploy host.." .
                "Run on a deploy host!");
            return 0;
        }
    }
    return 1;
}

# Checks the fsid value of the ceph dump with quattor value
sub cluster_fsid_check {
    my ($self, $cluster, $clname) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monhash = decode_json($jstr);
    my $fsid = $monhash->{fsid};
    $self->debug(3, 'fsid from mon dump is '.$fsid);
    if ($cluster->{config}->{fsid} ne $fsid) {
        $self->error("fsid of $clname not matching! ",
            "Quattor value: $cluster->{config}->{fsid}, ",
            "Cluster value: $fsid");
        return 0;
    } else {
        return 1;
    }
}

# generate mon hosts
sub gen_extra_config {
    my ($self, $cluster) = @_;
    my $config = $cluster->{config};
    $config->{mon_host} = [];
    foreach my $host (sort(keys(%{$cluster->{monitors}}))) {
        push (@{$config->{mon_host}}, $cluster->{monitors}->{$host}->{fqdn});
    }
    if (!$config->{osd_crush_update_on_start}) {
        $config->{osd_crush_update_on_start} = $cluster->{crushmap} ? 0 : 1 ;
    }
}

# Checks if the versions of ceph and ceph-deploy are compatible
sub check_versions {
    my ($self, $qceph, $qdeploy) = @_;
    $self->use_cluster;
    my $cversion = $self->run_ceph_command([qw(--version)]);
    my @vl = split(' ',$cversion);
    my $cephv = $vl[2];
    my ($stdout, $deplv);
    ($stdout, $deplv) = $self->run_ceph_deploy_command([qw(--version)]) if $qdeploy;
    if ($deplv) {
        chomp($deplv);
    }
    if ($qceph && (!match_glob($qceph, $cephv))) {
        $self->error("Ceph version not corresponding! ",
            "Ceph: $cephv, Quattor: $qceph");
        return 0;
    }
    if ($qdeploy && (!match_glob($qdeploy, $deplv))) {
        $self->error("Ceph-deploy version not corresponding! ",
            "Ceph-deploy: $deplv, Quattor: $qdeploy");
        return 0;
    }
    return 1;
}

# Prepare for ceph-deploy and cluster actions
sub do_prepare_cluster {
    my ($self, $cluster, $gvalues) = @_;
    $self->gen_extra_config($cluster);
    my $qtmp;
    if ($gvalues->{is_deploy}) {
        $qtmp = $self->init_qdepl($cluster->{config}, $gvalues->{cephusr}) or return 0;
        $gvalues->{qtmp} = $qtmp;
        my $clexists = $self->cluster_exists_check($cluster, $gvalues);
        my $cfgfile = "$gvalues->{cephusr}->{homeDir}/$gvalues->{clname}.conf";
        $self->write_new_config($cluster->{config}, $cfgfile) or return 0;
        if (!$clexists) {
            return 0;
        }
    }
    $self->cluster_ready_check($cluster, $gvalues->{is_deploy}, $gvalues->{hostname}) or return 0;
    $self->cluster_fsid_check($cluster, $gvalues->{clname}) or return 0;

}

# Main method for configuring the ceph cluster.
# use_cluster sets the active cluster
# do_prepare_cluster checks the cluster_existence and prepares the cluster for ceph-deploy,
# and writes the config file for new clusters from quattor (but does not install it)
# get_ceph_conf and get_quat_conf checks and build config hashes from the actual ceph and quattor config.
# compare_conf checks the differences between the hashes and define the necessary actions to be taken
# set_and_push_configs distributes the full config files per host
# deploy_daemons create daemons when needed.
# destroy_daemons destroys them, and
# restart_daemons can restart the changed ones.
# do_crush_actions builds and installs the crushmap
sub do_configure {
    my ($self, $cluster, $gvalues) = @_;
    $self->use_cluster($gvalues->{clname}) or return 0;
    $self->debug(1,"preparing cluster");
    $self->do_prepare_cluster($cluster, $gvalues) or return 0;
    $self->debug(1,"checking configuration");
    my ($ceph_conf, $mapping, $weights) = $self->get_ceph_conf($gvalues) or return 0;
    my $quat_conf = $self->get_quat_conf($cluster) or return 0;
    my $structures = $self->compare_conf($quat_conf, $ceph_conf,
        $mapping, $gvalues) or return 0;
    $self->debug(1,"configuring daemons");
    my $tinies = $self->set_and_push_configs($structures->{configs}, $gvalues) or return 0;
    $self->deploy_daemons($structures->{deployd}, $tinies, $gvalues, $mapping) or return 0;
    $self->debug(1,"configuring crushmap");
    $self->do_crush_actions($cluster, $gvalues, $structures->{skip}, $weights, $mapping) or return 0;
    $self->destroy_daemons($structures->{destroy}, $mapping) or return 0;
    $self->restart_daemons($structures->{restartd});
    return 1;

}


sub Configure {
    my ($self, $config) = @_;
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    my $netw = $config->getElement('/system/network')->getTree();
    my $cephusr = $config->getElement('/software/components/accounts/users/ceph')->getTree();
    my $group = $config->getElement('/software/components/accounts/groups/ceph')->getTree();
    $cephusr->{gid} = $group->{gid};
    my $hostname = $netw->{hostname};
    $self->debug(5, "Running on host $hostname.");
    $self->check_versions($t->{ceph_version}, $t->{deploy_version}) or return 0;
    $self->set_ssh_command($t->{ssh_multiplex});

    while (my ($clus, $cluster) = each(%{$t->{clusters}})) {
        my $is_deploy = $cluster->{deployhosts}->{$hostname} ? 1 : 0 ;

        $self->{fsid} = $cluster->{config}->{fsid};
        my $gvalues = {
            clname => $clus,
            hostname => $hostname,
            is_deploy => $is_deploy,
            cephusr => $cephusr,
            key_accept => $t->{key_accept},
            max_add_osd_failures_per_host => $t->{max_add_osd_failures_per_host},
        };
        if ($is_deploy) {
            $self->do_configure($cluster, $gvalues) or return 0;
        } else {
            $self->info("No deployhost, aborting configuration");
        }
        return 1;
    }
}

1; # Required for perl module!
