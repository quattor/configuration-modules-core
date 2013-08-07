# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::dirperm;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use EDG::WP4::CCM::Element;

use File::Path;
use File::Copy;
use File::Basename;
use Fcntl ':mode';

local(*DTA);

my @configured_mounts;
my %available_mounts;

##########################################################################
sub Configure($$@) {
##########################################################################

    my ($self, $config) = @_;

    # Define paths for convenience.
    my $base = "/software/components/dirperm";

    # Define paths for filesytems.
    my $filesystems = "/system/filesystems";

    # Get filesystem config into a hash.
    my $filesystems_config = $config->getElement($filesystems)->getTree();

    # Get the list of configured mountpoints
    my @unsorted;
    foreach my $entry (@{$filesystems_config}) {
        push @unsorted, $entry->{mountpoint} . "/";
    }

    # Sort the list of configured mountpoints
    @configured_mounts = sort @unsorted;

    $self->debug(5,"Configured mounts on the server:");
    foreach my $cfg_mnt (@configured_mounts) {
        $self->debug(5,"\t$cfg_mnt");
    }

    # Get actual mountpoints available on the server into a hash.
    open (MTAB, "/etc/mtab");
    for my $line (<MTAB>) {
        my ($device, $mnt_point, $fstype, $options) = split /\s+/, $line;
        $mnt_point .= "/";
        $available_mounts{$mnt_point}++;
    }

    $self->debug(5,"Filesystem mounts available on the server:");
    foreach my $act_mnt (sort keys %available_mounts) {
        $self->debug(5,"\t$act_mnt");
    }

    # Get ncm-dirperm config into a hash
    my $dirperm_config = $config->getElement($base)->getTree();

    # If the list of paths exists, actually do something!

    if ( $dirperm_config->{paths} ) {
        foreach my $entry (@{$dirperm_config->{paths}}) {
            my $rc = $self->process_path($entry);
        }
    }

    return 1;
}

sub process_path {

    my ($self, $pathentry) = @_;

    # Pull out the values and check that they really are defined.
    my $path = $pathentry->{path};
    if (!defined($path)) {
        $self->error("entry with undefined path");
        return 0;
    }

    # Get the owner.
    my $owner = $pathentry->{owner};
    if (!defined($owner)) {
        $self->error("entry with undefined owner");
        return 0;
    }

    # Verify the format of owner (owner:group) and get the uid and gid.
    $self->debug(2,"Splitting owner/group for $path ($owner)");
    my $uid = undef;
    my $gid = undef;
    my $user = undef;
    my $group = undef;
    if ($owner =~ m/^([\w\-_\.]+)(?::(\S+))?$/) {

        # Collect the uid and gid to use.
        $user = $1;
        $group = $2 if ($2);

        # gid defaults to the one in the passwd file
        ($uid, $gid) = (getpwnam($user))[2,3];

        # If the group was specified, use that instead.
        $gid = (getgrnam($group))[2] if ($group);

        if (!defined($uid) or !defined($gid)) {
            $self->error("bad owner or group ($owner)");
            return 0;
        }
    } else {
        $self->error("owner field with bad format ($owner)");
        return 0;
    }

    # Permissions.
    my $perm = oct($pathentry->{perm});
    if (!defined($perm)) {
        $self->error("entry with undefined permissions");
        return 0;
    }

    # Type: f=file, d=directory.
    my $type = $pathentry->{type};
    if (!defined($type)) {
        $self->error("entry with undefined type");
        return 0;
    }

    $self->debug(1,"Configuring $path : Type=$type, Owner=$user, Group=" . ($group ? $group : "undefined") . ", Permissions=oct($perm)");

    if ((-l $path) && (! -e $path)) {
	$self->error("$path is a broken symlink");
	return 0;
    }

    # Check for errors in the type of an already existing file.
    if (($type eq "f") && (-d $path)) {
        $self->error("$path exists but isn't a file");
        return 0;
    }
    if (($type eq "d") && (-e $path) && (!-d $path) ) {
        $self->error("$path exists but isn't a directory");
        return 0;
    }
    if (not (($type eq "f") or ($type eq "d"))) {
        # Bad entry.
        $self->error("bad file type ($type) given");
        return 0;
    }

    # Untainted all variable (UID/GID/PATH/PERM) see bug #42704
    if ($uid =~ /^(.*)$/) {
                $uid = $1;                     # $to_unlink is now untainted
        } else {
                $self->error("Bad data in $uid");
        }

    if ($gid =~ /^(.*)$/) {
                $gid = $1;                     # $to_unlink is now untainted
        } else {
                $self->error("Bad data in $gid");
        }

    if ($path =~ /^(.*)$/) {
                $path = $1;                     # $to_unlink is now untainted
        } else {
                $self->error("Bad data in $path");
        }

    if ($perm =~ /^(.*)$/) {
                $perm = $1;                     # $to_unlink is now untainted
        } else {
                $self->error("Bad data in $perm");
        }

    my $exists = 0;
    my $correct_ownership = 0;
    my $correct_permissions = 0;
    # Check if file exists and if permissions are correct
	if ( -e $path ) {
		$self->debug(1,"$path exists");
		$exists = 1;
		my ($_dev,$_ino,$_mode,$_nlink,$_uid,$_gid,$_rdev,$_size,
				$_atime,$_mtime,$_ctime,$_blksize,$_blocks) = stat($path);
		# Show permissions in conventional octal format
		my $_operm = sprintf "%04o", S_IMODE($_mode);
		my $operm = sprintf "%04o", $perm;

		if(($uid == $_uid) and ($gid == $_gid)){
			$self->debug(1,"$path has correct ownership $_uid:$_gid");
			$correct_ownership = 1;
		} else {
			$self->debug(1,"$path has ownership $_uid:$_gid, not $uid:$gid");
		};

		if($operm == $_operm){
			$self->debug(1,"$path has correct permissions $_operm" );
			$correct_permissions = 1;
		} else {
			$self->debug(1,"$path has permissions $_operm, not $operm");
		}
	}
    # Make the file or directory.
	if(not $exists) {
		if ($type eq "f") {
			# Make the file.
			open TMP, ">>$path";
			close TMP;
			if (! -f $path) {
				$self->error("error creating file $path");
				return 0;
			}
		} elsif ($type eq "d") {

            # Should we check if the needed mount is actually mounted?
            # (i.e. don't build path on / (root) if the mount point is not available)
            if ($pathentry->{checkmount}) {
                # Which mountpoint is path built on?
                my $path_mountpoint;
                $self->debug(5,"checkmount for path: $path");
                foreach my $mntpt (@configured_mounts) {
                    $self->debug(5,"\t\tmntpt: $mntpt");
                    if ($path =~ /^$mntpt/) {
                        $path_mountpoint = $mntpt;
                        $self->debug(5,"\t\t\tMATCHED!!!");
                    }
                }

                # is that mountpoint available?
                if (not exists($available_mounts{$path_mountpoint})) {
                    $self->error("filesytem mount $path_mountpoint not available for $path. skipping.");
                    return 0;
                }
            }

			# Make the directory and any parent directories.
			eval { mkpath($path,0,$perm) };
			if ($@) {
				$self->error("error making directory: $@");
				next;
			}
		}
	}

	if(not $correct_ownership) {
		my $cnt = chown $uid, $gid, $path;
		if ($cnt != 1) {
			$self->error("can't change owner on $path");
			return 0;
		}
	}

	if(not $correct_permissions) {
		my $cnt = chmod $perm, $path;
		if ($cnt != 1) {
			$self->error("can't change permissions on $path");
			return 0;
		}
	}


    # Copy files into newly created directory if necessary.
    my $initdir = $pathentry->{initdir};
    if (defined($initdir)) {
        if ($type eq "d") {
            foreach my $element (@{$initdir}) {
                my $srcdir = $element;

                # Ensure that this is a directory and exists.
                if (! -d $srcdir) {
                    $self->error("initdir path ($srcdir) doesn't exist");
                    return 0;
                }

                # Collect the ordinary files to copy.
                opendir DIR, "$srcdir";
                my @files = grep -T, map "$srcdir/$_", readdir DIR;
                closedir DIR;

                # Copy the files. This uses the default permissions
                # on the copy as the original dirperm object did.
                # Don't clobber files which exist already.
                foreach (@files) {
                    my $dstfile = "$path/" . basename($_);
                    if (! -f $dstfile) {
                        copy($_,$dstfile);
                        $self->error("error copying file $_") if ($?);

                        my $cnt = chown $uid, $gid, $dstfile;
                        if ($cnt != 1) {
                            $self->error("can't change owner on $dstfile");
                            return 0;
                        }
                    }
                }
            }
        } else {

            # initdir has been specified on a file entry
            $self->error("initdir specified for non-directory entry");
            return 0;
        }
    }

    return 1;
}


1;      # Required for PERL modules
