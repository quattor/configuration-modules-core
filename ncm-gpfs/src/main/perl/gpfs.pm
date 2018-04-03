#${PMcomponent}

=head1 NAME

NCM::gpfs - NCM gpfs configuration component

=cut

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use CAF::Process;
use CAF::FileWriter;

use File::Basename;
use File::Path qw(rmtree);
use Cwd;

use constant TMP_DOWNLOAD => '/tmp/ncm-gpfs-download';
use constant GPFSBIN => '/usr/lpp/mmfs/bin';
use constant GPFSCONFIGDIR => '/var/mmfs';
use constant GPFSCONFIG => '/var/mmfs/gen/mmsdrfs';
use constant GPFSKEYDATA => '/var/mmfs/ssl/stage/genkeyData';
use constant GPFSNODECONFIG => '/var/mmfs/gen/mmfsNodeData';
use constant GPFSRESTORE => 'mmsdrrestore';
use constant GPFSRPMS => qw(
    ^gpfs.base$
    ^gpfs.docs$
    ^gpfs.gpl$
    ^gpfs.gplbin-\d\S+$
    ^gpfs.gui$
    ^gpfs.msg.en_US$
    ^gpfs.ext$
    ^gpfs.gskit$
    ^gpfs.hdfs-protocol$
    ^gpfs.hadoop-connector$
    ^gpfs.smb$
    );

my $_cached_gss;

sub Configure
{
    my ($self, $config) = @_;

    my $tmpfh;

    my $startcwd = $self->create_tmpdir();
    return 1 if ($startcwd eq "1");

    # Save the date.
    my $date = localtime();

    # base rpms
    # remove existing gpfs rpms if certain is not found
    # - then install gpfs abse rpms from optional location
    # -- location should be kept secret
    # how to retrigger spma afterwards?
    my $baseinstalled = GPFSCONFIGDIR . "/.quattorbaseinstalled";
    my $basiccfg = GPFSCONFIGDIR . "/.quattorbasiccfg";
    if (! -f $baseinstalled) {
        my ($ok, $pkgs) = $self->remove_existing_rpms($config);
        return 1 if !$ok;
        $self->install_base_rpms($config) || return 1;

        # write the $baseinstalled file
        # - set the date
        $tmpfh = CAF::FileWriter->open($baseinstalled,
                                       backup => ".old",
                                       log => $self,
                                      );
        print $tmpfh $date;
        $tmpfh->close();
        # reinstall the updated packages, since spma will not always be triggered to run.
        $self->reinstall_update_rpms($config, $pkgs);
    }

    # get gpfs config file if not found
    if (! -f $basiccfg) {
        $self->get_cfg($config) || return 1;

        ## write the $basiccfg file
        ## - set the date

        $tmpfh = CAF::FileWriter->open($basiccfg,
                                       backup => ".old",
                                       log => $self,
                                      );
        print $tmpfh $date;
        $tmpfh->close();
    }

    return 1 if $self->cleanup_tmpdir($startcwd);
}

sub create_tmpdir
{
    my $self = shift;

    # create download dir
    if (-e TMP_DOWNLOAD) {
        if (! rmtree([TMP_DOWNLOAD])) {
            $self->error("Failed to remove existing tmp download dir ",
                         TMP_DOWNLOAD.": $!");
            return 1;
        }
    }
    if (!mkdir(TMP_DOWNLOAD)) {
        $self->error("Failed to create tmp download dir ",
                     TMP_DOWNLOAD.": $!");
        return 1;
    }
    if (!chmod(0700, TMP_DOWNLOAD)) {
        $self->error("Failed to chmod 0700 tmp download dir ",
                     TMP_DOWNLOAD.": $!");
        return 1;
    }

    my $startcwd = getcwd;
    chomp($startcwd);
    # Untaint it
    if ($startcwd =~ qr|^([-+@\w./]+)$|) {
        $startcwd = $1;
    } else {
        $self->error("Couldn't untaint \$startcwd: [$startcwd]");
        return 1;
    }
    if (!chdir(TMP_DOWNLOAD)) {
        $self->error("Failed to change to directory ".TMP_DOWNLOAD);
        return 1;
    }
    return $startcwd;
}

sub cleanup_tmpdir
{
    my ($self, $startcwd) = @_;
    # cleanup
    if (!chdir($startcwd)) {
        $self->error("Failed to change back to directory $startcwd.");
        return 1;
    }
    if (!rmtree([TMP_DOWNLOAD])) {
        $self->error("Failed to remove tmp download dir ".TMP_DOWNLOAD.": $!");
        return 1;
    };
    return 0;
}

sub runrpm
{
    my ($self, $config, @opts) = @_;

    my $tr = $config->getTree($self->prefix."/base");
    if ($tr->{useproxy}) {
        # check if spma proxy is set and then use it
        my $spmapath = "/software/components/spma";
        my $spmatr = $config->getElement($spmapath)->getTree;
        if ($spmatr->{proxy}) {
            unshift(@opts, '--httpproxy', $spmatr->{proxyhost})
                if ($spmatr->{proxyhost});
            unshift(@opts, '--httpport', $spmatr->{proxyport})
                if ($spmatr->{proxyport});
        } else {
            $self->error("No SPMA proxy set in $spmapath/proxy: $spmatr->{proxy}");
        };
    }

    my $proc = CAF::Process->new(["/bin/rpm", "-v", @opts],
                                 log => $self);
    my $output = $proc->output();

    if ($?) {
        $self->error("Error running $proc output: $output");
        return;
    }

    return $output || 1;
};

sub runyum
{
    my ($self, $config, @opts) = @_;

    my $proc = CAF::Process->new(["/usr/bin/yum", "-y", @opts], log => $self);
    my $output = $proc->output();

    if ($?) {
        $self->error("Error running $proc output: $output");
        return;
    }
    return $output  || 1;
};

sub runcurl
{
    my ($self, $config, $tmppath, @opts) = @_;

    my $tr = $config->getTree($self->prefix."/cfg");

    local $ENV{KRB5CCNAME};
    if ($tr->{usegss}) {
        # from ncm-download
        # TODO: use CAF or inherit from ncm-download
        if (!$_cached_gss) {
            my $ccache = "FILE:".TMP_DOWNLOAD."/host.tkt";
            $ENV{KRB5CCNAME} = $ccache;

            # Assume "kinit" is in the PATH.
            my $proc = CAF::Process->new([qw(kinit -k)], log => $self);
            my $output = $proc->output();
            if ($?) {
                $self->error("could not get GSSAPI credentials: $output");
                return;
            }
            $_cached_gss = $ccache;
        }
        $ENV{KRB5CCNAME} = $_cached_gss;
        unshift(@opts, qw(--negotiate -u x:x));
    } elsif ($tr->{usesindesgetcertcertwithcurl}) {
        # use sindesgetcert certificates with curl?
        my $sgpath = "/software/components/sindes_getcert";
        my $sgtr = $config->getTree($sgpath);
        if ($sgtr->{client_cert_key}) {
           unshift(@opts, '--cert', "$sgtr->{cert_dir}/$sgtr->{client_cert_key}")
                if $sgtr->{client_cert_key};
           unshift(@opts, '--cacert', "$sgtr->{cert_dir}/$sgtr->{ca_cert}")
                if $sgtr->{ca_cert};
        } else {
           $self->error("No sindes_getcert cert file set in ",
                        "$sgpath/client_cert_key: $sgtr->{client_cert_key}");
        };
    } elsif ($tr->{useccmcertwithcurl}) {
        # use ccm certificates with curl?
        # - does not work yet. curl cert is key_cert in one file
        # -- like sindes_getcert client_cert_key
        my $ccmpath = "/software/components/ccm";
        my $ccmtr = $config->getTree($ccmpath);
        if ($ccmtr->{cert_file}) {
            unshift(@opts, '--cert', $ccmtr->{key_file})
                 if $ccmtr->{key_file};
            unshift(@opts, '--cacert', $ccmtr->{ca_file})
                 if $ccmtr->{ca_file};
        } else {
            $self->error("No CCM cert file set in ",
                         "$ccmpath/cert_file: $ccmtr->{cert_file}");
        };
    }

    my $proc = CAF::Process->new(["/usr/bin/curl", "-s", "-f", @opts],
                                 log => $self);
    my $output = $proc->output();

    if ($?) {
        $self->error("Error running $proc output: $output");
        return;
    }

    return $output || 1;
};

sub reinstall_update_rpms
{
    my ($self, $config, $rpms) = @_;

    my $ok = 1;
    my $useyum = $config->getValue($self->prefix."/base/useyum");

    if (@$rpms) {
        if ($useyum) {
            # for dependencies
            $ok = $self->runyum($config, "install", @$rpms);
        } else {
            $ok = $self->runrpm($config, "-i", @$rpms);
        };
        if ($ok) {
            $self->info("Rpms reinstalled");
        } else {
            $self->error("Reinstalling rpms failed");
        }
    } else {
        $self->info("No rpms to be reinstalled.")
    }

    return $ok;
};


sub remove_existing_rpms
{
    my ($self, $config) = @_;

    my $ok = 1;
    my $allrpms = $self->runrpm($config, "-q", "-a", "gpfs.*",
                                "--qf", "%{NAME} %{NAME}-%{VERSION}-%{RELEASE}\\n");
    return if (!$allrpms);
    my $useyum = $config->getValue($self->prefix."/base/useyum");
    my @removerpms;
    foreach my $found (split('\n', $allrpms)) {
        my @res = split(' ', $found);
        my $foundname = $res[0];
        my $foundfullname = $res[1];

        if (grep { $foundname =~ m/$_/ } GPFSRPMS) {
            push(@removerpms, $foundfullname);
        } else {
            $self->error("Not removing unknown found rpm that matched gpfs.*:",
                         " $found (full: $foundfullname). \n");
            $ok = 0;
        };
        # No need to remove other packages since we will stop after anyway
        return 0 if !$ok;
    };

    $self->stopgpfs(1);
    if (@removerpms) {
        if ($useyum) {
            # for dependencies
            $ok = $self->runyum($config, "remove", @removerpms);
        } else {
            $ok = $self->runrpm($config, "-e", @removerpms);
        };
        if($ok) {
            $self->info("Rpms removed");
        } else {
            $self->error("Removing rpms failed");
        }
    } else {
        $self->info("No rpms to be removed.")
    }

    return ($ok, \@removerpms);
};


# return 0 on failure
sub install_base_rpms
{
    my ($self, $config) = @_;

    my $ret = 1;
    my $tr = $config->getTree($self->prefix."/base");

    my @rpms;
    my @downloadrpms;
    foreach my $rpm (@{$tr->{rpms}}) {
        my $fullrpm = "$tr->{baseurl}/$rpm";
        $fullrpm =~ s/\/\/$rpm/\/$rpm/;

        if ($tr->{usecurl}) {
            push(@downloadrpms, "-O", $fullrpm);
            push(@rpms, $rpm);
        } else {
            push(@rpms, $rpm);
        };
        $self->debug(2, "Added base rpm $rpm.")
    }

    my $tmp = TMP_DOWNLOAD;
    if (scalar @downloadrpms) {
        $self->runcurl($config, $tmp, @downloadrpms) || return ;
    };

    # gpfs complains about libstdc++.so.5, but it's not needed
    $self->runrpm($config, "-U", "--nodeps", @rpms) || return;

    # cleanup downloaded rpms
    for my $rpm (@rpms) {
        $rpm = basename($rpm);
        if (-f "$tmp/$rpm") {
            if (unlink("$tmp/$rpm")) {
                $self->debug(3, "File $tmp/$rpm deleted successfully.");
            } else {
                $self->error("File $tmp/$rpm was not deleted.");
                $ret = 0;
            }
        }
    }

    return $ret;
};

sub rungpfs
{
    my ($self, $noerroronmissing, $bin, @cmds) = @_;

    my $cmdexe = GPFSBIN."/$bin";
    if (! -f $cmdexe) {
        if ($noerroronmissing) {
            $self->info("GPFS cmd $cmdexe not found.");
        } else {
            $self->error("GPFS cmd $cmdexe not found.");
        };
        return;
    };

    unshift(@cmds, $cmdexe);

    my $proc = CAF::Process->new(\@cmds, log => $self);
    my $output = $proc->output();

    if ($?) {
        $self->error("Error running $proc output: $output");
        return;
    }
    return $output || 1;
};

sub stopgpfs {
    my $self = shift;
    my $neom = shift || 0;
    # local shutdown
    return $self->rungpfs($neom, "mmshutdown");
};

sub startgpfs {
    my $self = shift;
    my $neom = shift || 0;
    ## local startup
    return $self->rungpfs($neom, "mmstartup");
};

# return 0 on failure
sub get_cfg
{
    my ($self, $config) = @_;

    my $ret = 1;
    my $tr = $config->getTree($self->prefix."/cfg");
    my $url = $tr->{url};
    my $tmp = TMP_DOWNLOAD;
    my $output = $self->runcurl($config, $tmp, $url);
    return 0 if !$output;

    # sanity check
    my $tmpcfg = "$tmp/".basename($url);

    my $subn = $tr->{subnet};
    my $hostname =  $config->getValue("/system/network/hostname");
    $subn =~ s/\./\\./g;
    my $regexp = "MEMBER_NODE.*$hostname\.$subn";

    my $committed_key;
    my $gpfsconfigfh = CAF::FileWriter->open(GPFSCONFIG,
                                             backup => ".old",
                                             log => $self);
    my $gpfsnodeconfigfh = CAF::FileWriter->open(GPFSNODECONFIG,
                                                 backup => ".old",
                                                 log => $self);
    foreach my $line (split /^/, $output) {
        print $gpfsconfigfh $line;

        if ($line =~ m/^%%.*VERSION_LINE/) {
            my @entries = split(/:/, $line);
            # committed key is the 21th field of first line of mmsdrfs (src of mmsdrserv)
            $committed_key = $entries[20];
        }
        # there should be only one...
        elsif ($line =~ m/$regexp/) {
            if ("$gpfsnodeconfigfh") {
                $self->error("Ignoring another node match for ",
                             "regexp $regexp found: $line.");
            } else {
                print $gpfsnodeconfigfh $line;
            };
        };
    }

    # check fulltxt content (curl -f should not generate any
    #   404-html pages or such, but you never know)
    if ("$gpfsconfigfh" !~ m/^%%.*VERSION_LINE/) {
        $self->error('Invalid config file found');
        $gpfsconfigfh->cancel();
        $gpfsnodeconfigfh->cancel();
        return 0;
    }

    if (! "$gpfsnodeconfigfh") {
        $self->error("Empty node config file found with regex $regexp and gpfsconfig $gpfsconfigfh");
        $gpfsconfigfh->cancel();
        $gpfsnodeconfigfh->cancel();
        return 0;
    }

    $gpfsconfigfh->close();
    $gpfsnodeconfigfh->close();

    if ($tr->{keyData}) {
        my $keydata = $tr->{keyData};
        my $keyoutput = $self->runcurl($config, $tmp, $keydata);
        return 0 if (! $keyoutput);
        if (!$committed_key) {
            $self->error('No key is yet committed. Run mmauth key commit or remove keyData');
            return 0;
        }
        my $keydataTarget = GPFSKEYDATA . $committed_key;
        my $gpfskeyfh = CAF::FileWriter->open($keydataTarget,
                                              backup => ".old",
                                              mode => oct(600),
                                              log => $self,
                                              sensitive => 1);
        print $gpfskeyfh $keyoutput;

        if ( ("$gpfskeyfh" !~ m/^clusterName/) ||
             ("$gpfskeyfh" !~ m/keyGenNumber=$committed_key/) ) {
            $self->error('Invalid genKeyData file found');
            $gpfskeyfh->cancel();
            return 0;
        }

        $gpfskeyfh->close();
    }

    $self->rungpfs(1, GPFSRESTORE) if $tr->{sdrrestore};

    return 1;
};

# Required for end of module
1;
