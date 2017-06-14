#${PMcomponent}

=head1 NAME

C<ncm-cron> -- NCM component to control cron entries for Linux and Solaris.

=head1 DESCRIPTION

The I<cron> component manages files in the C</etc/cron.d> directory on Linux
and the C</var/spool/cron/crontabs> directory on Solaris.

=head2 Linux

Files managed by C<ncm-cron> will have the C<.ncm-cron.cron> suffix.  Other files in
the directory are not affected by this component. The name of each file will be
taken from the C<name> attribute.

=head2 Solaris

Solaris uses an older version of cron that does not make use of a cron.d
directory for crontabs. C<ncm-cron> B<shares> the crontab with each user. To make
this work C<ncm-cron> uses the concept of separate file B<sections> within the
crontab.  Each B<section> is identified by the use of the tags C<< NCM-CRON BEGIN: >>
and C<< NCM-CRON END: >>. Entries either side of these section identifiers are not
modified.

Solaris B<does> have a C</etc/cron.d> directory, however it uses this directory
for control files such as C<cron.allow> and C<cron.deny>.

=head1 EXAMPLE

  "/software/components/cron/entries" = list(
    dict(
      "name", "ls",
      "user", "root",
      "group", "root",
      "frequency", "*/2 * * * *",
      "command", "/bin/ls"),
    dict(
      "name", "hostname",
      "comment", "some interesting text",
      "frequency", "*/2 * * * *",
      "command", "/bin/hostname"),
      "env", dict("MAILTO", "admin@example.org"),
    dict(
      "name", "date",
      "comment", "runs the date sometime within a 3 hour period",
      "timing", dict(
          "minute", "0",
          "hour", "1",
          "smear", 180),
      "command", "/bin/date")
    );

On Linux this will create three files in /etc/cron.d:

  ls.ncm-cron.cron
  hostname.ncm-cron.cron
  date.ncm-cron.cron

On Solaris three extra entries will be added to the root crontab.

=head1 Solaris

Editing the C<< NCM-CRON BEGIN: >> and/or the C<< NCM-CRON END: >> tag within a crontab will
cause unpredictable behaviour. Possible behavours are duplicate entries or
entries being removed altogether.

Editing BETWEEN the tags will cause the edits to be overwritten the next time
ncm-cron runs.

=cut

use CAF::Path 17.3.1;
use parent qw(NCM::Component CAF::Path);

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use CAF::Object;

use Encode qw(encode_utf8);
use English;

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

use Readonly;

Readonly my $CRON_LOGFILE_SUBDIR => "/var/log/";

Readonly my $CRONDIR_LINUX => "/etc/cron.d";
Readonly my $CRONDIR_SOLARIS => "/var/spool/cron/crontabs";
Readonly my $DATE_SOLARIS => "gdate --iso-8601=seconds --utc";
Readonly my $DATE_LINUX => "date --iso-8601=seconds --utc";

Readonly my $NCM_START => "###### NCM-CRON BEGIN:";
Readonly my $NCM_STOP => "###### NCM-CRON END:";
Readonly my $NCM_MSG => "Do not edit lines from NCM-CRON BEGIN to NCM-CRON END";
Readonly my $NCM_MSG_END => "This comment intentionally left blank";

# 'our' is required for testing to override the os
our $osname = $OSNAME;

Readonly my $CRON_ENTRY_EXTENSION_PREFIX => ".ncm-cron";
Readonly my $CRON_ENTRY_EXTENSION => $CRON_ENTRY_EXTENSION_PREFIX . ".cron";
Readonly my $CRON_LOG_EXTENSION => $CRON_ENTRY_EXTENSION_PREFIX . ".log";


sub Configure
{
    my ($self, $config) = @_;

    # Load ncm-cron configuration into a hash
    my $cron_config = $config->getTree($self->prefix());
    my $cron_entries = $cron_config->{entries};
    my $securitypath = $cron_config->{securitypath};

    if (!defined $securitypath) {
        $self->error("Variable \$securitypath is not defined. Aborting.");
        return;
    }

    # Define cron.allow / cron.deny files
    $self->security_file('allow', $cron_config->{allow}, $securitypath)
        if (exists($cron_config->{allow}));
    $self->security_file('deny', $cron_config->{deny}, $securitypath)
        if (exists($cron_config->{deny}));

    # Clean up crontabs/cron files and return an empty hash for Linux or a hash
    # of cron filehandles for solaris.
    my %solCronFiles = $self->cleanCrontabs("Configure", $cron_entries);

    # Only continue if the entries line is defined.
    unless ($cron_entries) {
        return 1;
    }

    # Loop through all of the entries creating one cron entry for each.
    # For Linux this will be a seperate file. For solaris this will be an entry
    # in the users crontab file.
    foreach my $entry (@{$cron_entries}) {
        my $name = $entry->{name};
        unless ($name) {
            $self->error("Undefined name for cron entry; skipping");
            next;
        }

        my $fname = $name;
        $fname =~ s{[/\s]}{_}g;
        my $linux_file = "$CRONDIR_LINUX/$fname$CRON_ENTRY_EXTENSION";
        $self->info("Checking cron entry $name...");

        # User: use root if not specified.
        my $user = 'root';
        if ( $entry->{user}) {
            $user = $entry->{user};
        }
        my $uid = getpwnam($user);
        unless (defined($uid) ) {
            $self->error("Undefined user ($user) for entry $name; skipping");
            next;
        }

        # Group : use the primary group of the user if not specified.
        my $group = undef;
        my $gid = undef;
        if ( $entry->{group}) {
            $group = $entry->{group};
        } else {
            $gid = (getpwnam($user))[3];
            if ( defined($gid) ) {
                $group = getgrgid($gid);
            } else {
                $self->error("Unable to determine default group for entry $name; skipping");
                next;
            }
        }
        unless ( defined($gid) ) {
            $gid = getgrnam($group);
        }
        unless ( defined($gid) ) {
            $self->error("Undefined group ($group) for entry $name; skipping");
            next;
        }


        # Log file name, owner and mode.
        # If a syslog method is defined, use that method to log to syslog (unless
        # syslog is explicitly disabled).
        # Default is to create a logfile in /var/log using the cron entry name.
        # If specified log file name is not an absolute path, create it in /var/log.
        # If log file property 'disabled' is true, do not create/configure any logging
        # (log file or syslog).
        my $log_name;
        my $log_owner;
        my $log_group;
        my $log_mode;
        my $log_params = $entry->{log};
        my $log_disabled = 0;
        my $log_to_file = 0;
        my $log_to_syslog = 0;
        my $syslog_params = $entry->{syslog};
        my $syslog_logger_fn; # used for syslog logger method
        if ( $log_params->{'disabled'} ) {
            $log_disabled = 1;
            $self->debug(1,'Logging disabled.');
        } elsif ($syslog_params && (! $syslog_params->{'disabled'})) {
            # where is the logger (/bin/logger on el5, /usr/bin/logger in el6)
            if (-f "/bin/logger") {
                $syslog_logger_fn = "/bin/logger";
                $log_to_syslog = 1;
            } elsif (-f "/usr/bin/logger") {
                $syslog_logger_fn = "/usr/bin/logger";
                $log_to_syslog = 1;
            } else {
                $self->error("Unable to find logger binary for syslog method logger.");
            }
        }
        if (!($log_disabled || $log_to_syslog)) {
            $log_to_file = 1;
            $log_name = "/var/log/$fname$CRON_LOG_EXTENSION";
            $log_owner = undef;
            $log_group = undef;
            $log_mode = oct(640);

            if ( $log_params->{name} ) {
                $log_name = $log_params->{name};
                unless ( $log_name =~ /^\s*\// ) {
                    $log_name = $CRON_LOGFILE_SUBDIR . $log_name;
                }
            }
            if ( $log_params->{owner} ) {
                my $owner_group = $log_params->{owner};
                ($log_owner, $log_group) = split /:/, $owner_group;
            }
            unless ( $log_owner ) {
                $log_owner = $user;
            }
            unless ( $log_group ) {
                $log_group = $group;
            }
            if ( $log_params->{mode} ) {
                $log_mode = oct($log_params->{mode});
            }
        }

        # Frequency of the cron entry.  May contain AUTO for the
        # minutes field : in this case, substitute AUTO with a random
        # value. This only works in the minutes field of the
        # frequence.  We support two formats here: the traditional
        # "frequency" field and also a more complex "timing" structure
        # (which allows more smear)
        my $frequency = "";
        if (exists($entry->{timing})) {
            my $timing = {};
            foreach my $field (qw(minute hour day month weekday smear)) {
                if (exists($entry->{timing}->{$field})) {
                    $timing->{$field} = $entry->{timing}->{$field};
                } else {
                    $timing->{$field} = '*';
                }
            }
            if (exists($entry->{timing}->{smear}) && $entry->{timing}->{smear}) {
                my $smear = $entry->{timing}->{smear};
                if ($smear > 60*24) {
                    $self->error("timing for $name is smeared by more than a day; skipping");
                }
                if ($timing->{minute} !~ /^\d+$/) {
                    $self->error("timing for $name is smeared and so the minutes field must be specified exactly ",
                                 "(not '$timing->{minute}') in order to determine the possible start time of the smear; skipping");
                    next;
                }
                if ($timing->{hour} !~ /^\d+$/ && $smear > 60) {
                    $self->error("timing for $name is smeared by more than an hour, and so the hours specification must be ",
                                 "specified exactly (not '$timing->{hour}'); skipping");
                    next;
                }
                $smear = int(rand($smear));
                my ($overflow,$dayoverflow);
                ($timing->{minute}, $overflow) =
                    addtime($timing->{minute}, $smear, 0, 59);
                ($timing->{hour}, $overflow) =
                    addtime($timing->{hour}, $overflow, 0, 23);
                ($timing->{weekday}, $dayoverflow) =
                    addtime($timing->{weekday}, $overflow, 0, 6);
                ($timing->{day}, $dayoverflow) =
                    addtime($timing->{day}, $overflow, 1, 31);
                ($timing->{month}, $overflow) =
                    addtime($timing->{month}, $dayoverflow, 1, 12);
                $self->info("smeared $name by $smear");
            }
            $frequency = "$timing->{minute} $timing->{hour} $timing->{day} $timing->{month} $timing->{weekday}";
        } else {
            if (!exists($entry->{frequency}) ||
                !$entry->{frequency} ||
                ref $entry->{frequency}) {
                $self->error("undefined/invalid frequency for $name " .
                             "cron entry; skipping");
                next;
            }
            $frequency = $entry->{frequency};

            # Substitute AUTO with a random value. This only works in
            # the minutes field of the frequence.
            $frequency =~ s/AUTO/int(rand(60))/eg;
        }

        # Extract the mandatory command.  If it isn't provided,
        # then skip to next entry.
        my $command = undef;
        if ($entry->{command}) {
            $command = $entry->{command};
        } else {
            $self->error("Undefined command for entry $name; skipping");
            next;
        }

        # Generate the contents of the cron entry and write the output
        # file.  Ensure permissions are appropriate for execution by
        # cron (permission x must not be set).  If there is no log
        # file associated with the cron, disable execution of 'date'
        # command to avoid sending an email to root at each execution
        # (because of date output).

        # open fh to cron file
        # no backup, would trigger it multiple times otherwise
        my $cronfh;
        if ($osname eq "solaris") {
            my $fPath = "$CRONDIR_SOLARIS/$user";
            # Check if we need a new cron user file
            if (!exists $solCronFiles{$fPath}) {
                $self->debug(1, "Creating new cronfile $fPath");
                $solCronFiles{$fPath} = CAF::FileWriter->new($fPath,
                                                    mode => oct(600),
                                                    owner => "root",
                                                    group => "sys",
                                                    log => $self);
                $cronfh = $solCronFiles{$fPath};
                print $cronfh "$NCM_START $NCM_MSG\n";
            } else {
                $cronfh = $solCronFiles{$fPath};
            }
        } else {  # Linux
            $cronfh = CAF::FileWriter->new($linux_file,
                                           mode => oct(644),
                                           log => $self);
            # add header
            print $cronfh "#\n# File generated by ncm-cron. DO NOT EDIT.\n#\n";
        }

        # Pull out the optional comment.  Will be added just after
        # the generic autogenerated file warning.
        # Split the comment by line.  Prefix each line with a hash.
        if ( $entry->{comment}) {
            my $comment = $entry->{comment};
            my @lines = split /\n/m, $comment;
            foreach my $line (@lines) {
                print $cronfh "# $line\n";
            }
        }

        # Determine if there is an environment to set.  If so,
        # extract the key value pairs.
        my $solEnv = "";
        my $env_entries = $entry->{env};
        if ($env_entries) {
            foreach my $k (sort keys %{$env_entries}) {
                if ($osname eq "solaris") {
                    $solEnv .= "$k=$env_entries->{$k}; export $k; ";
                } else {
                    print $cronfh "$k=$env_entries->{$k}\n";
                }
            }
        }

        # This is a hack to avoid seperate print statements for each os.
        # Solaris requires environment variables to be put inside the
        # sub shell, while Linux requires the user to be put outside the command.
        # This will look odd in the below print statements as only ")" will be
        # obvious in the print string.
        my $shell_prefix = "";
        if ($osname eq "solaris") {
            $shell_prefix = "($solEnv";
        } else {
            $shell_prefix = "$user (";
        }

        if ( $log_disabled ) {
            # Opening "(" is in $shell_prefix
            print $cronfh "$frequency $shell_prefix $command)\n";
        } elsif ($log_to_syslog) {
            my $tag;
            if (exists($syslog_params->{tag})) {
                $tag = $syslog_params->{tag};
            } else {
                $tag = $name;
            }
            if (exists($syslog_params->{tagprefix})) {
                $tag = $syslog_params->{tagprefix}.$tag;
            }
            # Opening "(" is in $shell_prefix
            print $cronfh "$frequency $shell_prefix $command) 2>&1 |";
            print $cronfh "$syslog_logger_fn -t $tag -p " .
                "$syslog_params->{facility}.$syslog_params->{level}\n";
        } else {
            if (! $log_to_file) {
                # how did we get here? will this even work?
                $self->warn("No log handling specified nor disabled, going to log to file.");
                $log_to_file = 1;
            }
            # Opening "(" is in $shell_prefix
            my $date = $osname eq "solaris" ? $DATE_SOLARIS : $DATE_LINUX;
            print $cronfh "$frequency $shell_prefix $date; $command) >> $log_name 2>&1\n";
        }

        $cronfh->close() unless $osname eq "solaris";

        # Create the log file and change the owner if necessary.
        if ( $log_to_file ) {
            my $changes;
            if ( -f $log_name ) {
                # looks like overkill but can't be easily replaced with
                # CAF::FileWriter (will override) or
                # CAF::FileEditor (will read in all data)
                $changes = $self->status(
                    $log_name,
                    owner => $log_owner,
                    group => $log_group,
                    mode => $log_mode,
                );
                if (!defined($changes)) {
                    $self->error("Error setting owner/permissions on log file $log_name: $self->{fail}");
                }
            } else {
                # initialise the logfile, use CAF::FileWriter to allow testing
                my $logfilefh = CAF::FileWriter->new(
                    $log_name,
                    owner => $log_owner,
                    group => $log_group,
                    mode => $log_mode,
                    log => $self,
                );
                $logfilefh->close();
            }
        }
    }
    # For Solaris: for each file add the NCM-CRON END: tag and write the file.
    #              Reload the cron daemon
    if ($osname eq "solaris") {
        foreach my $fil (sort keys %solCronFiles) {
            my $fh = $solCronFiles{$fil};
            print $fh "$NCM_STOP $NCM_MSG_END\n";
            $fh->close();
        }
        my $p = CAF::Process->new(['/sbin/svcadm', 'refresh', 'cron'], log => $self);
        $p->run();
        $self->error("Could not refresh cron by running \"svcadm refresh cron\"")
            if $?;
    } else {
        # For Linux: as a workarond for a RedHat 5 cron race condition bug: touch /etc/cron.d
        #            when we are done generating the files. cron(8) will reload as a result
        if ($CAF::Object::NoAction) {
            $self->info("Would have touched $CRONDIR_LINUX to workaround a cron bug");
        } else {
            $self->debug(1, "Touching $CRONDIR_LINUX to workaround a cron bug");
            sleep 1;
            utime(undef, undef, $CRONDIR_LINUX);
        }
    }

    return 1;
}  # of Configure()

sub Unconfigure
{
    my ($self, $config) = @_;

    my %solCronFiles = $self->cleanCrontabs("Unconfigure");
    # Close the solaris crontabs and refresh cron
    if ($osname eq "solaris") {
        foreach my $fh (values(%solCronFiles)) {
            $fh->close();
        }
        my $p = CAF::Process->new(['/sbin/svcadm', 'refresh', 'cron']);
        $p->run();
        $self->error("Could not refresh cron by running \"svcadm refresh cron\"")
            if $?;
    }
    return;
}  # of Unconfigure()

sub cleanCrontabs
{
    my ($self, $configType, $cronEntries) = @_;

    # %cronEntryNames is a hash that will be filled with all $cronEntries names.
    # Only existing cron entries not present in this hash will be removed.
    # Currently implement only for Linux.
    my %cronEntryNames = ();
    foreach my $entry (@{$cronEntries}) {
        my $name = $entry->{name};
        # This cannot happen as this will have already been detected/reported by main code
        # which ignores the buggy entry. Anyway, harmess to double check...
        unless ($name) {
            $self->error("cleanCrontabs(): undefined name for cron entry, skipping it (internal error)");
            next;
        }
        if ($osname eq "solaris") {
            # Not yet implemented
            next;
        } else { # Linux
            my $fname = "$name$CRON_ENTRY_EXTENSION";;
            $fname =~ s{[/\s]}{_}g;
            $cronEntryNames{$fname} = ''; # Value is meaningless
        }
    }

    my $crondir = $osname eq "solaris" ? $CRONDIR_SOLARIS : $CRONDIR_LINUX;

    # Files only. Do not modify listdir() call to return of directories unless
    # CAF::Path::cleanup has also been modified to support only files
    # (similar to original LC::Check::absence(..., files => True)).
    my $all_files = $self->listdir($crondir, file_exists => 1);

    # Return a hash of opened FileEditor file handles
    #  (for solaris only)
    my %solCronFiles = ();

    foreach my $filename (@$all_files) {
        my $path = "$crondir/$filename";
        if ($osname eq "solaris") {
            # Solaris: Collect the crontabs in /var/spool/cron/crontabs then delete
            # any ncm-cron entries. These are identified as lines between:
            #     NCM-CRON START:
            #     NCM-CRON END:
            $self->debug(2, "Checking $path");
            my $fh = $solCronFiles{$path} =
                CAF::FileEditor->open(
                    $path,
                    log => $self,
                    mode => oct(600),
                    owner => "root",
                    group => "sys");
            my $outlines = "";
            my $foundNCM = 0;
            foreach my $line (split("\n", "$fh")) {
                $line =~ /$NCM_START/ && do {$foundNCM = 1};
                $outlines .= "$line\n" if !$foundNCM;  # Don't save ncm lines
                $line =~ /$NCM_STOP/ && do {$foundNCM = 0};
                # If an old style ncm managed cron file, simply delete all content.
                if ($self->isOldSolarisFile($path, $line)) {
                    $outlines = "";
                    last;
                }
            }
            $self->debug(2, "Keeping lines:\n$outlines\n") if $outlines;
            $fh->set_contents($outlines);  # Save non NCM-CRON lines
            $fh->seek(0, 2);  # eof
            print $fh "$NCM_START $NCM_MSG\n"  # Set NCM-CRON START:
                if $configType eq "Configure";
            $self->warn("NCM-CRON END: missing from $path. Deleting to EOF")
                if $foundNCM eq 1;
        } else {
            # Linux: collect the current entries managed by ncm-cron in the cron.d
            # directory and delete those no longer part of the configuration.
            # Returns an empty hash (return value unused in Linux context).
            my $cron_entry_regexp = $CRON_ENTRY_EXTENSION;
            $cron_entry_regexp =~ s/\./\\./g;

            next if $filename !~ /$cron_entry_regexp$/;
            next if defined($cronEntryNames{$filename});

            # untainted to_unlink to work with tainted perl mode (-t option)
            if ($path =~ m{^($CRONDIR_LINUX/.*$cron_entry_regexp)$}) {
                my $to_unlink = $1;  # $to_unlink is now untainted
                $self->info("Deleting $to_unlink");
                $self->cleanup($to_unlink);
            } else {
                $self->error("cannot untaint cron file $path");
            }
        }
    }

    return %solCronFiles;
}  # of cleanCrontabs()

# doesn't work with "named" elements (e.g. 'mon' instead of 1).
sub addtime
{
    my ($in, $add, $min, $max) = @_;
    $add ||= 0;
    my $ret = 0;

    if ($in eq '*') {
        return ($in, 0);
    }

    my $overflow = 0;

    # convert any ranges into explicit lists....
    my @list = ();
    foreach my $range (split(/,/, $in)) {
        # convert range into a list
        if ($range =~ m{^(\d+)-(\d+)(?:/(\d+))?}) {
            my ($from, $to, $step) = split(/-/, $range, 2);
            $step ||= 1;
            while ($from <= $to) {
                push(@list, $from);
                $from += $step;
            }
        } else {
            push(@list, $range);
        }
    }
    # unique the list....
    my $seen = {};
    @list = grep { !exists($seen->{$_}) } @list;

    foreach my $item (sort { $a <=> $b } @list) {
        $item += $add;
        if ($item > $max) {
            $overflow = int($item / ($max+1));
            $item = $item % ($max+1) + $min;
        }
    }

    return (join(",", @list), $overflow);
}  # of addtime()

sub security_file
{
    my ($self, $file_type, $user_list, $securitypath) = @_;

    my $secfh = CAF::FileWriter->new("$securitypath/cron.$file_type",
                                     owner => "root",
                                     group => "sys",
                                     backup => ".old",
                                     mode => oct(644),
                                     log => $self);

    print $secfh "#\n# File generated by ncm-cron. DO NOT EDIT.\n#\n";
    foreach my $user (@{$user_list}) {
        print $secfh $user . "\n";
    }

    $secfh->close();
}  # of security_file

# Function to detect existing old style solaris crontabs that are being
# managed by ncm.
sub isOldSolarisFile
{
    my ($self, $fPath, $line) = @_;
    my $ncmOldFile = "# File generated by ncm-cron. DO NOT EDIT.";
    $line =~ /$ncmOldFile/ && do {
        $self->info("Converting old style cron file: $fPath");
        return 1;
    };
    return 0;
}  # of isOldSolarisFile

1;      # Required for PERL modules
