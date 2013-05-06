# ${license-info}
# ${developer-info}
# ${author-info}

#
# authconfig - authconfig NCM component
#
################################################################################

package NCM::Component::authconfig;

use strict;
use NCM::Component;
use CAF::Process;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use CAF::FileEditor;
use File::Path;

use EDG::WP4::CCM::Element;

use constant SSSD_FILE => '/etc/sssd/sssd.conf';
use constant TT_FILE => 'authconfig/sssd.tt';

# prevent authconfig from trying to launch in X11 mode
delete($ENV{"DISPLAY"});

sub update_pam_file
{
    my ($self, $tree) = @_;

    my $fh = CAF::FileEditor->new($tree->{conffile},
				  log => $self, backup => ".old");

    foreach my $i (@{$tree->{lines}}) {
	my $whence = $i->{order} eq 'first' ?
	    BEGINNING_OF_FILE : ENDING_OF_FILE;

	$i->{entry} =~ m{(\S+\.so)};
	my $module = $1;
	$fh->add_or_replace_lines(qr{^#?\s*$tree->{section}\s+\S+\s+$module},
				  qr{^$tree->{section}\s+$i->{entry}$},
				  "$tree->{section} $i->{entry}\n", $whence);
    }

    $fh->close();
}

sub build_pam_systemauth
{
    my ($self, $tree) = @_;

    foreach my $i (sort(keys(%$tree))) {
	$self->update_pam_file($tree->{$i})
    }
}

# Disable an authentication method
sub disable_method
{
    my ($self, $method, $cmd) = @_;

    if ($method eq 'files') {
	$self->warn("Cannot disable files method");
	return;
    }

    $self->verbose("Disabling authentication method $method");
    $cmd->pushargs("--disable$method");
}

# Enable the "files" authentication method in nsswitch. Actually, it
# does nothing.
sub enable_files
{
    my $self = shift;

    $self->verbose("Files method is always enabled");
}

# Adds the authconfig command-line options to enable Kerberos5
# authentication to $cmd.
sub enable_krb5
{
    my ($self, $cfg, $cmd) = @_;

    $self->verbose("Enabling KRB5 authentication");

    $cmd->pushargs(qw(--enablekrb5 --krb5realm));
    $cmd->pushargs($cfg->{realm});
    $cmd->pushargs("--krb5kdc", join(",", @{$cfg->{kdcs}}))
        if exists $cfg->{kdcs};
    $cmd->pushargs("--krb5adminserver", join(",", @{$cfg->{adminservers}}))
        if exists $cfg->{adminservers};
}

# Adds the authconfig command-line options to enable SMB
# authentication to $cmd.
sub enable_smb
{
    my ($self, $cfg, $cmd) = @_;

    $self->verbose("Enabling SMB authentication");

    $cmd->pushargs(qw(--enablesmbauth --smbworkgroup));
    $cmd->pushargs($cfg->{workgroup});
    $cmd->pushargs("--smbservers", join(",", @{$cfg->{servers}}));
}

# Adds the authconfig command-line options to enable NIS
# authentication to $cmd.
sub enable_nis
{
    my ($self, $cfg, $cmd) = @_;

    $self->verbose("Enabling NIS authentication");
    $cmd->pushargs(qw(--enablenis --nisdomain));
    $cmd->pushargs($cfg->{domain});
    $cmd->pushargs("--nisserver", join(",", @{$cfg->{servers}}));
}

# Adds the authconfig command-line options to enable HESIOD
# authentication to $cmd.
sub enable_hesiod
{
    my ($self, $cfg, $cmd) = @_;

    $self->verbose("Enabling Hesiod authentication");
    $cmd->pushargs(qw(--enablehesiod --hesiodlhs));
    $cmd->pushargs($cfg->{lhs});
    $cmd->pushargs("--hesiodrhs", $cfg->{rhs});
}

# Adds the authconfig command-line options to enable LDAP
# authentication to $cmd.
sub enable_ldap
{
    my ($self, $cfg, $cmd) = @_;

    if ($cfg->{nssonly}) {
	$cmd->pushargs("--disableldapauth");
    } else {
	$cmd->pushargs("--enableldapauth");
    }

    $cmd->pushargs("--enableldap");
    $cmd->pushargs("--ldapserver", join(",", @{$cfg->{servers}}))
        if exists $cfg->{servers};
    $cmd->pushargs("--ldapbasedn=$cfg->{basedn}");
    $cmd->pushargs("--enableldaptls") if $cfg->{enableldaptls};
}

# Adds the authconfig command-line options to enable NSLCD (LDAP as of
# SL6) authentication to $cmd.
sub enable_nslcd
{
    my ($self, $cfg, $cmd) = @_;

    $cmd->pushargs(qw(--enableldapauth --enableldap));
    $cmd->pushargs("--ldapserver", join(",", @{$cfg->{uri}}));
    $cmd->pushargs("--ldapbasedn=$cfg->{basedn}");

    # Only enable TLS if requested; just setting ssl on should not enable TLS.
    $cmd->pushargs("--enableldaptls") if $cfg->{ssl} && $cfg->{ssl} eq "start_tls";
}

# Adds the authconfig command-line to enable SSSD.
sub enable_sssd
{
    my ($self, $cfg, $cmd) = @_;

    if ($cfg->{nssonly}) {
	$cmd->pushargs(qw(--disablesssdauth));
    } else {
	$cmd->pushargs(qw(--enablesssdauth));
    }
    $cmd->pushargs("--enablesssd");
}

sub authconfig
{
    my ($self, $t) = @_;

    my ($stdout, $stderr);
    my $cmd = CAF::Process->new([qw(authconfig --kickstart)],
				log => $self,
				stdout => \$stdout,
				stderr => \$stderr,
				timeout => 60);


    foreach my $i (qw(shadow cache)) {
	    $cmd->pushargs($t->{"use$i"} ? "--enable$i" : "--disable$i");
    }

    $cmd->pushargs("--passalgo=$t->{passalgorithm}");

    $cmd->pushargs("--enableforcelegacy") if $t->{enableforcelegacy};

    while (my ($method, $v) = each(%{$t->{method}})) {
	if ($v->{enable}) {
	    $method = "enable_$method";
	    $self->$method($v, $cmd);
	} else {
            $self->disable_method($method, $cmd)
	}
    }
    $cmd->setopts(timeout => 60,
		  stdout => \$stdout,
		  stderr => \$stderr);
    $cmd->execute();
    if ($stdout) {
	$self->info("authconfig command output produced:");
	$self->report($stdout);
    }
    if ($stderr) {
	$self->info("authconfig command ERROR produced:");
	$self->report($stderr);
    }
}

# Configures /etc/ldap.conf which is the file configuring LDAP
# authentication on SL5.
sub configure_ldap
{
    my ($self, $tree) = @_;

    delete($tree->{enable});
    my $fh = CAF::FileWriter->new($tree->{conffile},
				  group => 28,
				  log => $self,
				  mode => 0644,
				  backup => ".old");
    delete($tree->{conffile});
    # These fields have different
    print $fh "idle_timelimit $tree->{timeouts}->{idle}\n";
    print $fh "bind_timelimit $tree->{timeouts}->{bind}\n";
    print $fh "timelimit $tree->{timeouts}->{search}\n";
    print $fh "tls_checkpeer ",
	$tree->{tls}->{peercheck} ? "true" : "false", "\n";
    print $fh "tls_cacertfile $tree->{tls}->{cacertfile}\n"
	if $tree->{tls}->{cacertfile};
    print $fh "tls_cacertdir  $tree->{tls}->{cacertdir}\n"
	if $tree->{tls}->{cacertdir};
    print $fh "tls_ciphers $tree->{tls}->{ciphers}\n"
	if $tree->{tls}->{ciphers};
    print $fh "TLS_REQCERT $tree->{tls}->{reqcert}\n";
    for my $i (0 .. $#{$tree->{servers}}) {
        if (!($tree->{servers}[$i] =~ /:/)) {
            $tree->{servers}[$i] = 'ldap://'.$tree->{servers}[$i].'/';
        }
    }
    print $fh "uri ", join(" ", @{$tree->{servers}}), "\n";
    print $fh "base $tree->{basedn}\n";

    delete ($tree->{basedn});
    delete ($tree->{tls});
    delete ($tree->{timeouts});
    delete ($tree->{servers});
    foreach my $i (qw(nss_map_objectclass nss_map_attribute
		      nss_override_attribute_value)) {
	while (my ($k, $v) = each(%{$tree->{$i}})) {
	    print $fh "$i $k $v\n";
	}
	delete($tree->{$i});
    }

    while (my ($k, $v) = each(%$tree)) {
	print $fh "$k $v\n";
    }

    return $fh->close();
}

# Configures nslcd, if needed.
sub configure_nslcd
{
    my ($self, $tree) = @_;

    my $fh = CAF::FileWriter->new("/etc/nslcd.conf",
				  mode => 0600,
				  log => $self);
    my ($changed, $proc);

    delete($tree->{enable});

    print $fh "# File generated by ", __PACKAGE__, ". Do not edit edit\n";

    print $fh "base $tree->{basedn}\n";
    delete($tree->{basedn});
    while (my ($group, $values) = each(%{$tree->{map}})) {
	while (my ($k, $v) = each(%$values)) {
	    print $fh "map $group $k $v\n";
	}
    }
    delete($tree->{map});

    # uri needs whitespace-separated list of values
    if ( exists $tree->{uri} ) {
        print $fh "uri ", join(" ", @{$tree->{uri}});
        delete($tree->{uri});
    }

    while (my ($k, $v) = each(%$tree)) {
	if (!ref($v)) {
	    print $fh "$k $v";
	} elsif (ref($v) eq 'ARRAY') {
	    print $fh  "$k ", join(",", @$v);
	} elsif (ref($v) eq 'HASH') {
	    while (my ($kh, $vh) = each(%$v)) {
		print $fh "$k $kh $vh\n";
	    }
	}
	print $fh "\n";
    }

    if ($changed = $fh->close()) {
	CAF::Process->new([qw(/sbin/service nslcd restart)],
			  log => $self)->run();
	if ($?) {
	    $self->error("Failed to restart nslcd");
	}
    }
    return $changed;
}

sub configure_sssd
{
    my ($self, $config) = @_;

    my $fh = CAF::FileWriter->new(SSSD_FILE, log => $self, mode => 0600);
    if (!$self->template()->process(TT_FILE, $config, $fh)) {
        $self->error("Unable to render template ", TT_FILE, ": ",
                     $self->template()->error());
        return 0;
    }
    my $changed = $fh->close();

    if ($changed) {
        CAF::Process->new([qw(/sbin/service sssd restart)],
                          log => $self)->run();
        if ($?) {
            $self->error("Failed to restart SSSD");
        }
    }
    return $changed;
}


# Restarts NSCD if that is needed. It's ugly because on some versions
# of SL stopping or starting may fail.
sub restart_nscd
{
    my $self = shift;

    $self->verbose("Attempting to restart nscd");
    my $cmd = CAF::Process->new([qw(service nscd stop)], log => $self,
				timeout => 30)->execute();
    sleep(1);
    $cmd = CAF::Process->new([qw(killall nscd)], log => $self,
			     timeout => 30)->execute();
    sleep(2);

    $cmd = CAF::Process->new([qw(service nscd start)],
			     log => $self,
			     timeout => 30)->execute();

    sleep(1);
    $? = 0;
    $cmd = CAF::Process->new([qw(nscd -i passwd)],
			     log => $self)->run();

    if ($?) {
	$self->error("Failed to restart NSCD");
    }
}


sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement("/software/components/authconfig")->getTree();
    my $cache = $t->{usecache};
    my $restart;

    # authconfig basic configuration
    $self->authconfig($t);

    # On SL5 this configures LDAP authentication. On other versions
    # this probably doesn't hurt anyways.
    if ($t->{method}->{ldap}->{enable}) {
	$restart = $self->configure_ldap($t->{method}->{ldap});
    }

    # This configures LDAP authentication on SL6.
    if ($t->{method}->{nslcd}->{enable}) {
	$restart ||= $self->configure_nslcd($t->{method}->{nslcd});
    }

    if ($t->{method}->{sssd}->{enable}) {
        $restart ||= $self->configure_sssd($t->{method}->{sssd});
    }

    $self->build_pam_systemauth($t->{pamadditions});

    $self->restart_nscd() if $cache && $restart;

    return 1;
}

1;
