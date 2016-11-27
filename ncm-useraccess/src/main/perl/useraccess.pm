#${PMpre} NCM::Component::useraccess${PMpost}

# Might handle the requests in parallel, but this is simpler.
use LWP::UserAgent;
use CAF::FileWriter;
use CAF::FileEditor;
use File::stat;
use CAF::Object;
use DirHandle;


use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

use constant MASK   => 077;

use constant KRB4	=> "kerberos4";
use constant KRB5	=> "kerberos5";
use constant ACLS	=> "acls";
use constant SSH_KEYS	=> "ssh_keys";
use constant SSH_KEYS_URLS	=> "ssh_keys_urls";
use constant ROLES	=> "roles";
use constant USERS	=> "users";
use constant ACLSERVICES => "acl_services";

# Files to edit in the users' home directory.
use constant K4LOGIN	=> '.klogin';
use constant K5LOGIN	=> '.k5login';
use constant SSH_DIR	=> '.ssh';

use constant SSH_AUTH	=> SSH_DIR . '/authorized_keys';


# Kerberos' fields
use constant REALM	=> "realm";
use constant PRINCIPAL=> "principal";
use constant INSTANCE	=> "instance";
use constant HOST	=> "host";

# Field containing the credentials the component should manage:
use constant MANAGED_CREDENTIALS => "managed_credentials";

# getpwnams values.
use constant NAME	=> 0;
use constant PASSWD	=> 1;
use constant UID	=> 2;
use constant GID	=> 3;
use constant QUOTA	=> 4;
use constant COMMENT	=> 5;
use constant GCOS	=> 6;
use constant HOMEDIR	=> 7;
use constant SHELL	=> 8;
use constant EXPIRE	=> 9;


# Format differences between .klogin and .k5login
use constant KLOGIN_SEPARATOR	=> '.';
use constant K5LOGIN_SEPARATOR=> '/';

use constant KRB_SETTINGS => ([KRB4, KLOGIN_SEPARATOR],
                  [KRB5, K5LOGIN_SEPARATOR]);

# Directories where the ACLs will be stored and for PAM configuration.
use constant ACL_DIR	=> "/etc/acls";
use constant PAM_DIR	=> "/etc/pam.d";

use constant ROLEPATH => '/software/components/useraccess/roles/';

# Returns the interesting information from a user. Wrapper for Perl's
# getpwnam.
#
# Arguments: $_[1]: the user name.
sub getpwnam
{
    my ($self, $user) = @_;

    my @val = getpwnam($user);
    if (@val) {
        return @val[UID, GID, HOMEDIR];
    } else {
        $self->error("Couldn't get system data for $user");
        return undef;
    }
}

#
# C<directory_verify_owner> verifies the owner of directory C<dir> has expected C<uid>.
# If not, make the directory owner and also set C<gid>
# and permission C<perm>.
# It does not check the gid nor the permissions of an existing directory, those can
# be user controlled.
# If the directory does not exist, create it with these settings.
#
sub directory_verify_owner
{
    my ($self, $dir, $uid, $gid, $perm) = @_;

    if (! -d $dir) {
        $self->verbose("No such directory $dir, creating it with $uid/$gid/$perm");
        if ($CAF::Object::NoAction) {
            $self->debug(1, "NoAction: mkdir($dir, $perm) and chown($uid, $gid, $dir) not called");
        } else {
            mkdir($dir, $perm) || $self->warn("Failed to mkdir $dir with perm $perm: $!");
            chown($uid, $gid, $dir) || $self->warn("Failed to chown dir $dir with uid/gid $uid/$gid: $!");
        }
    } else {
        my $stat = stat($dir);
        if ($stat->uid != $uid) {
            $self->verbose("Found directory $dir owned by $stat->uid, setting it to expected $uid/$gid/$perm");
            if ($CAF::Object::NoAction) {
                $self->debug(1, "NoAction: chown($uid, $gid, $dir) and chmod ($perm, $dir) not called");
            } else {
                chown($uid, $gid, $dir) || $self->warn("Failed to chown dir $dir with uid/gid $uid/$gid: $!");
                chmod($perm, $dir) || $self->warn("Failed to chmod dir $dir with perm $perm: $!");
            }
        }
    }
}

# Removes the user's existing configuration.
sub initialize_user
{
    my ($self, $user) = @_;

    my ($uid, $gid, $home) = $self->getpwnam ($user);
    defined $uid or return;

    # verify HOME dir owner
    $self->directory_verify_owner($home, $uid, $gid, 0700);

    # verify/create SSH dir owner
    my $ssh_dir = "$home/" . SSH_DIR;
    $self->directory_verify_owner($ssh_dir, $uid, $gid, 0700);

    return ($uid, $gid, $home);
}

# Removes the .kXlogin settings. It recreates them for the specified
# kerberos 4 or kerberos 5 credentials.
#
# Arguments:
#
# $_[1] the name of the user being modified.
# $_[2] the complete configuration associated to the user.
sub set_kerberos
{
    my ($self, $user, $cfg, $fhs) = @_;

    foreach my $i (KRB_SETTINGS) {
        my ($key, $sep) = @$i;
        $self->debug(1, "Kerberos settings for user: $user");
        my $ct = $cfg->{$key};
        next unless defined $ct;
        if (!defined $fhs->{$key}) {
            $self->error("Impossible to configure Kerberos for user $user");
            return -1;
        }
        my $fh = $fhs->{$key};
        foreach (@$ct) {
            print $fh $_->{PRINCIPAL()};
            print $fh $sep, $_->{INSTANCE()} if (defined $_->{INSTANCE()});
            print $fh "@", $_->{REALM()}, "\n";
        }
    }
    return 0;
}

# Downloads the public keys files from the given URLs and writes them
# into .ssh/authorized_keys
#
# Arguments: $_[1]: The name of the user being modified.
# $_[2]: Complete configuration hash for the user.
sub set_ssh_fromurls
{
    my ($self, $user, $cfg, $fh) = @_;

    my $err = 0;
    my $cnt = $cfg->{SSH_KEYS_URLS()};
    return 0 unless defined $cnt;
    if (!defined $fh) {
        $self->error("Impossible to write authorized public keys for ",
                 "user $user");
        return -1;
    }
    my $ua = LWP::UserAgent->new;
    foreach my $url (@$cnt) {
        my $rp = $ua->get ($url);
        if ($rp->is_success) {
            print $fh $rp->content;
        } else {
            $self->error("Key not found: $url");
            $err = -1;
        }
    }
    return $err;
}

# Fills the .ssh/authorized_keys file with the keys written in the
# profile. This is to make happy those guys who crow their profiles
# with garbage. ;)
sub set_ssh_fromkeys
{
    my ($self, $user, $cfg, $fh) = @_;

    my $cnt = $cfg->{SSH_KEYS()};
    return 0 unless defined $cnt;
    if (!defined $fh) {
        $self->error("Impossible to write authorized SSH keys from ",
                 "profile for user $user");
        return -1;
    }
    foreach my $key (@$cnt) {
        print $fh "$key\n";
    }
    return 0;
}

# Inscribes the currently processed user into the ACLs for each
# service he is allowed to
#
# Arguments:
# $_[1]: the user being processed.
# $_[2]: the full configuration for the user being processed.
sub set_acls
{
    my ($self, $user, $cfg) = @_;
    my $cnt = $cfg->{ACLS()};
    my ($fh, $srv);

    return unless defined $cnt;
    foreach $srv (@$cnt) {
        $fh = CAF::FileEditor->open(ACL_DIR . "/$srv",
                        log => $self);
                        #backup => '.print');
        print $fh "$user\n";
        $fh->close();
    }
}

# Adds pam_listfile support for each service for which we created
# ACLs.
sub pam_listfile
{

    my ($self, $services) = @_;
    my $dir = DirHandle->new(ACL_DIR);
    my ($cnt, $fh, $acl);

    foreach my $srv (@$services) {
        if ($srv =~ m{^([-_\w]+)$}) {
            $srv = $1;
        } else {
            $self->error("Invalid PAM service for setting ACL: $srv");
        }
        $acl = ACL_DIR . "/$srv";
        $fh = CAF::FileEditor->open(PAM_DIR . "/$srv", log => $self,
                        # Better a random backup?
                        backup => '.old');
        foreach my $i (qw(auth session)) {
            $fh->head_print (join("\t", $i, qw(required pam_listfile.so
                              onerr=fail item=user sense=allow),
                      "file=$acl\n"));
        }
        $fh->close();
        if (! -f ACL_DIR . "/$srv") {
            $self->warn("Service $srv needs ACL but no ACL was created for it");
        }
    }
}



# Adds to the processed user the complete configuration from the roles
# he belongs to.
#
# Arguments:
# $_[1]: the user being processed.
# $_[2]: the list of roles the user belongs to.
# $_[3]: the complete definitions for all the roles in the profile.
sub set_roles
{

    my ($self, $user, $rllist, $rolecfgs, $fhash) = @_;

    foreach (@$rllist) {
        my $cfg = $rolecfgs->{$_};
        $self->info ("Processing role $_ for user $user");
        if ($self->set_kerberos($user, $cfg, $fhash) ||
            $self->set_ssh_fromurls($user, $cfg,
                        $fhash->{SSH_KEYS()}) ||
            $self->set_ssh_fromkeys($user, $cfg,
                        $fhash->{SSH_KEYS()}) ||
            $self->set_acls($user, $cfg) ||
            $self->set_roles($user, $cfg->{ROLES()},
                     $rolecfgs, $fhash)) {
            return -1;
        }
    }
    return 0;
}


# Opens all the files needed for a given user, in a secure way.
sub files
{
    my ($self, $uconfig, $uid, $gid, $home) = @_;
    my %h;
    my $path;
    $path = "$home/" . K4LOGIN;
    $h{KRB4()} = CAF::FileWriter->new($path, log => $self,
                      owner => $uid,
                      group => $gid,
                      mode => 0400);

    $path = "$home/" . K5LOGIN;
    $h{KRB5()} = CAF::FileWriter->new($path, log => $self,
                      owner => $uid,
                      group => $gid,
                      mode => 0400);
    $path = "$home/" . SSH_AUTH;
    $h{SSH_KEYS()} = CAF::FileWriter->new($path, log => $self,
                      owner => $uid,
                      group => $gid,
                      mode => 0400);

    foreach my $cred (@{$uconfig->{MANAGED_CREDENTIALS()}}) {
        $h{MANAGED_CREDENTIALS()}->{$cred} = 1;
    }

    return \%h;
}

# Closes the opened files. If they are expected to be handled by the
# component this includes saving the contents or removing empty
# files. Otherwise, the contents are just cancelled.
sub close_files
{
    my ($self, $f) = @_;

    my $mg = $f->{MANAGED_CREDENTIALS()};
    delete($f->{MANAGED_CREDENTIALS()});

    while (my ($k, $fh) = each(%$f)) {
        if ($mg->{$k}) {
            if (! "$fh") {
                unlink(*$fh->{filename});
                $fh->cancel();
            }
        } else {
            $fh->cancel();
        }
        $fh->close();
    }
}

sub Configure
{

    my ($self, $config) = @_;

    my $t = $config->getElement($self->prefix())->getTree();

    my $uhash = $t->{USERS()};
    my $rlhash = $t->{ROLES()};
    my $acls = $t->{ACLSERVICES()};
    my $mask = umask;
    my $ok = 1;
    umask(MASK);

    while (my ($user, $uconfig) = each (%$uhash)) {
        $self->info("Setting up user $user");
        my ($uid, $gid, $home) = $self->initialize_user($user);
        unless (defined $uid) {
            $self->error("Couldn't initialize user $user, skipping");
            next;
        }
        my $fhash = $self->files($uconfig, $uid, $gid, $home);
        if ($self->set_kerberos($user, $uconfig, $fhash) ||
            $self->set_ssh_fromurls($user, $uconfig,
                        $fhash->{SSH_KEYS()}) ||
            $self->set_ssh_fromkeys($user, $uconfig,
                        $fhash->{SSH_KEYS()}) ||
            $self->set_acls($user, $uconfig) ||
            $self->set_roles($user, $uconfig->{ROLES()},
                     $rlhash, $fhash)) {
            $ok = 0;
            $self->error("Errors while configuring user $user");
        }
        $self->close_files($fhash);
    }
    $self->pam_listfile($acls);
    umask ($mask);
    return $ok;
}

1;
