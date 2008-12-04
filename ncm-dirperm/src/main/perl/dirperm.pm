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

local(*DTA);


##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;

    # Define paths for convenience. 
    my $base = "/software/components/dirperm";

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

    # Check for errors in the type of an already existing file.
    if (($type eq "f") && (-d $path)) {
        $self->error("$path exists but isn't a file");
        return 0;
    } 
    if (($type eq "d") && (-e $path) && (!-d $path) ) {
        $self->error("$path exists but isn't a directory");
        return 0;
    } 

    # Make the file or directory.
    if ($type eq "f") {

        # Make the file.  
        open TMP, ">>$path";
        close TMP;
        if (! -f $path) {
            $self->error("error creating file $path");
            return 0;
        }

        my $cnt = chown $uid, $gid, $path;
        if ($cnt != 1) {
            $self->error("can't change owner on $path");
            return 0;
        }

        $cnt = chmod $perm, $path;
        if ($cnt != 1) {
            $self->error("can't change permissions on $path");
            return 0;
        }

    } elsif ($type eq "d") {

        # Make the directory and any parent directories. 
        eval { mkpath($path,0,$perm) };
        if ($@) {
            $self->error("error making directory: $@");
            return 0;
        }

        my $cnt = chown $uid, $gid, $path;
        if ($cnt != 1) {
            $self->error("can't change owner on $path");
            return 0;
        }

        $cnt = chmod $perm, $path;
        if ($cnt != 1) {
            $self->error("can't change permissions on $path");
            return 0;
        }

    } else {

        # Bad entry. 
        $self->error("bad file type ($type) given");
        return 0;
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
                    next;
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
