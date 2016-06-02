#${PMpre} NCM::Component::shorewall${PMpost}

use parent qw(NCM::Component CAF::Path);

use LC::Exception qw(SUCCESS);
our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

use CAF::Process;
use EDG::WP4::CCM::TextRender;

use Readonly;

# shorewall is shorewall.conf
Readonly::Array my @SUPPORTED => qw(shorewall rules zones interfaces policy tcinterfaces tcpri);

Readonly my $CONFIG_DIR => "/etc/shorewall";
Readonly my $BACKUP_SUFFIX => '.quattor';
Readonly my $FAILED_SUFFIX => '.failed.';
Readonly my $SHOREWALL_TRY => ['/sbin/shorewall', 'try', $CONFIG_DIR];
Readonly my $CCM_FETCH => [qw(/usr/sbin/ccm-fetch)];

# Generate new config files, keep backups
# Return undef on failure, the filename if file was modified, or 0 otherwise.
sub make_config
{
    my ($self, $feat, $config) = @_;

    my $filename = "$CONFIG_DIR/$feat";
    $filename .= '.conf' if $feat eq 'shorewall';

    my $trd = EDG::WP4::CCM::TextRender->new(
        $feat,
        $config->getElement($self->prefix()."/$feat"),
        relpath => 'shorewall',
        log => $self,
        );

    my $fh = $trd->filewriter($filename, log => $self, backup => $BACKUP_SUFFIX);
    if(! defined($fh)) {
        $self->error("Failed to render $feat shorewall config: $trd->{fail}");
        return;
    }

    return $fh->close() ? $filename : 0;
}

# Restore nackup of all changed files, do a shorewall try
sub rollback
{
    my ($self, @changed) = @_;

    my $suff = $FAILED_SUFFIX.time();

    my $fail;
    # We will try to roll back as much as possible, and only fail afterwards
    foreach my $filename (@changed) {
        # Move/copy to .failed.timestamp
        # warn only, nothing really bad
        if (! $self->move($filename, $filename.$suff)) {
            $self->warn("Failed to move failed config $filename to $filename$suff: $self->{fail}");
        }

        if ($self->file_exists($filename.$BACKUP_SUFFIX)) {
            my $msg = "backup config $filename$BACKUP_SUFFIX to $filename";
            # Restore the $BACKUP_SUFFIX file
            if ($self->move($filename.$BACKUP_SUFFIX, $filename)) {
                $self->verbose("Restored $msg")
            } else {
                $self->error("Failed to restore $msg: $self->{fail}");
                $fail = 1;
            }
        } else {
            # No backup, must have been new file
            my $msg = "$filename (nothing to restore)";
            if ($self->cleanup($filename)) {
                $self->verbose("Removed $msg")
            } else {
                $self->error("Failed to cleanup $msg: $self->{fail}");
                $fail = 1;
            }
        }
    }

    return if $fail;

    my $output = CAF::Process->new($SHOREWALL_TRY, log => $self)->output();
    if ($?) {
        $self->error("shorewall try failed after rollback (ec $?): $output");
        return;
    } else {
        $self->info("Successful rollback.");
    }
    return SUCCESS;
}

# use shorewall try (check exit code)
#   on fail, rollback backups, and re-try (or restart)?
#   on success, check ccm-fetch
#      on fail, rollback backups, and re-try (or restart)?
# even if changed list is empty, try and ccm-fetch are called
#   This is useful for rollback method to make the rolled-back files active.
#   But do not call this in Configure if you know nothing was modified.
sub try_rollback
{
    my ($self, @changed) = @_;

    if (@changed) {
        $self->verbose("Changed config files: ", join(', ', @changed));
    } else {
        $self->verbose("No changed config files passed, going to try the current existing files");
    }

    my $output = CAF::Process->new($SHOREWALL_TRY, log => $self)->output();
    if ($?) {
        $self->error("shorewall try failed (ec $?): $output");
        $self->rollback(@changed) if @changed;
        return;
    } else {
        # Let network recover
        sleep 15;
        $output = CAF::Process->new($CCM_FETCH, log => $self)->output();
        if ($?) {
            $self->error("ccm-fetch failed (ec $?): $output");
            $self->rollback(@changed) if @changed;
            return;
        }
    }
    return SUCCESS;
}

sub Configure
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix());

    # List of filenames that were changed.
    # These are the files that have to be rolled-back in case of failure
    my @changed;
    foreach my $feat (@SUPPORTED) {
        if ($tree->{$feat}) {
            my $res = $self->make_config($feat, $config);
            push(@changed, $res) if $res;
        }
    }

    if (@changed) {
        $self->try_rollback(@changed);
    } else {
        $self->verbose("No files were changed");
    }

    return 1;
}

# Required for end of module
1;
