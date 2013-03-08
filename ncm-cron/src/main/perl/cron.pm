# ${license-info}
# ${developer-info}
# ${author-info}


#######################################################################
#                 /etc/cron.conf
#######################################################################

package NCM::Component::cron;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use File::Copy;

use EDG::WP4::CCM::Element;

use LC::Check;

use Encode qw(encode_utf8);

local(*DTA);

my $crond = "/etc/cron.d";

##########################################################################
sub Configure($$@) {
##########################################################################

    my ($self, $config) = @_;

    # Define paths for convenience.
    my $base = "/software/components/cron";

    # Define some defaults
    my $date = "date --iso-8601=seconds --utc";
    my $cron_entry_extension_prefix = ".ncm-cron";
    my $cron_entry_extension = $cron_entry_extension_prefix . ".cron";
    my $cron_log_extension = $cron_entry_extension_prefix . ".log";
    my $cron_entry_regexp = $cron_entry_extension;
    $cron_entry_regexp =~ s/\./\\./g;

    # Load ncm-cron configuration into a hash
    my $cron_config = $config->getElement($base)->getTree();
    my $cron_entries = $cron_config->{entries};

    # Define cron.allow / cron.deny files
    if (exists $cron_config->{allow} ) {
	if ( security_file('allow',$cron_config->{allow}) < 0 ) {
	    $self->error('Unable to write cron.allow');
	};
    }
    if (exists $cron_config->{deny} ) {
	if ( security_file('deny',$cron_config->{deny}) < 0 ) {
	    $self->error('Unable to write cron.deny');
	};
    }

    # Collect the current entries managed by ncm-cron in the cron.d directory.
    opendir DIR, $crond;
    my @files = grep /$cron_entry_regexp$/, map "$crond/$_", readdir DIR;
    closedir DIR;

    # Actually delete them.  This should always be done as no entries
    # in the profile indicates that there should be no entries in the
    # cron.d directory either.
    foreach my $to_unlink (@files) {
	# Untainted to_unlink to work with tainted perl mode (-T option)
	if ($to_unlink =~ /^(.*)$/) {
	    $to_unlink = $1;                     # $to_unlink is now untainted
	} else {
	    $self->error("Bad data in $to_unlink");
	}

	unlink $to_unlink;
	$self->log("error ($?) deleting file $to_unlink") if $?;
    }

    # Only continue if the entries line is defined.
    unless ($cron_entries) {
	return 1;
    }

    # Loop through all of the entries creating one cron file for each
    for my $entry (@{$cron_entries}) {
        my $name = $entry->{name};
        unless ($name) {
            $self->error("Undefined name for cron entry; skipping");
            next;
        }
        $self->info("Checking cron entry $name...");
        my $file = "$crond/$name.ncm-cron.cron";

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


        # Log file name, owner and mode.  Default is to create one in
        # /var/log using the cron entry name.  If specified log file
        # name is not an absolute path, create it in /var/log. if log
        # file property 'disabled' is true, do not create/configure a
        # log file.
        my $log_name;
        my $log_owner;
        my $log_group;
        my $log_mode;
        my $log_params = $entry->{log};
        my $log_disabled = 0;
        if ( $log_params->{'disabled'} ) {
	    $log_disabled = 1;
	    $self->debug(1,'Log file disabled.');
        } else {
	    $log_name = "/var/log/$name$cron_log_extension";
	    $log_owner = undef;
	    $log_group = undef;
	    $log_mode = 0640;

	    if ( $log_params->{name} ) {
		$log_name = $log_params->{name};
		unless ( $log_name =~ /^\s*\// ) {
		    $log_name = '/var/log/' . $log_name;
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
        if (exists $entry->{timing}) {
            my $timing = {};
            foreach my $field (qw(minute hour day month weekday smear)) {
                if (exists $entry->{timing}->{$field}) {
                    $timing->{$field} = $entry->{timing}->{$field};
                } else {
                    $timing->{$field} = '*';
                }
            }
            if (exists $entry->{timing}->{smear} && $entry->{timing}->{smear}) {
                my $smear = $entry->{timing}->{smear};
                if ($smear > 60*24) {
                    $self->error("timing for $name is smeared by more than a day; skipping");
                }
                if ($timing->{minute} !~ /^\d+$/) {
                    $self->error("timing for $name is smeared and so the minutes field must be specified exactly (not '$timing->{minute}') in order to determine the possible start time of the smear; skipping");
                    next;
                }
                if ($timing->{hour} !~ /^\d+$/ && $smear > 60) {
                    $self->error("timing for $name is smeared by more than an hour, and so the hours specification must be specified exactly (not '$timing->{hour}'); skipping");
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
            if (!exists $entry->{frequency} ||
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
        if ( $entry->{command}) {
            $command = $entry->{command};
        } else {
            $self->error("Undefined command for entry $name; skipping");
            next;
        }

        # Pull out the optional comment.  Will be added just after
        # the generic autogenerated file warning.
        # Split the comment by line.  Prefix each line with a hash.
        my $comment = '';
        if ( $entry->{comment}) {
            $comment = $entry->{comment};
            my @lines = split /\n/m, $comment;
            $comment = '';
            foreach (@lines) {
                $comment .= "# " . $_ . "\n";
            }
        }

        # Determine if there is an environment to set.  If so,
        # extract the key value pairs.
        my $cronenv = '';
        my $env_entries = $entry->{env};
        if ( $env_entries ) {
            foreach (sort keys %{$env_entries}) {
                $cronenv .= "$_=" . $env_entries->{$_} . "\n";
            }
        }


        # Generate the contents of the cron entry and write the output
        # file.  Ensure permissions are appropriate for execution by
        # cron (permission x must not be set).  If there is no log
        # file associated with the cron, disable execution of 'date'
        # command to avoid sending an email to root at each execution
        # (because of date output).
        my $contents = "#\n# File generated by ncm-cron. DO NOT EDIT.\n#\n";
        $contents .= $comment;
        $contents .= $cronenv;
        if ( $log_disabled ) {
	    $contents .= "$frequency $user ($command)";
        } else {
	    $contents .= "$frequency $user ($date; $command) >> $log_name 2>&1";
        }
        $contents .= "\n";

        my $changes = LC::Check::file("$file",
                                      contents => encode_utf8($contents),
                                      mode => 0644,
	    );
        if ( $changes < 0 ) {
            $self->error("Error updadating cron file $file");
        }

        # Create the log file and change the owner if necessary.
        if ( ! $log_params->{'disabled'} ) {
	    if ( -f $log_name ) {
		$changes = LC::Check::status($log_name,
					     owner => $log_owner,
					     group => $log_group,
					     mode => $log_mode,
		    );
		if ( $changes < 0 ) {
		    $self->error("Error setting owner/permissions on log file $log_name");
		}
	    } else {
		$changes = LC::Check::file($log_name,
					   contents => '',
					   owner => $log_owner,
					   group => $log_group,
					   mode => $log_mode,
		    );
		if ( $changes < 0 ) {
		    $self->warn("Error creating log file $log_name");
		}
	    }
        }
    }

    return 1;
}

sub Unconfigure {
    my ($self, $config) = @_;
    # Collect the current entries in the cron.d directory.
    opendir DIR, $crond;
    my @files = grep /\.ncm-cron\.cron$/, map "$crond/$_", readdir DIR;
    closedir DIR;

    # Actually delete them.  This should always be done as no entries
    # in the profile indicates that there should be no entries in the
    # cron.d directory either.
    foreach (@files) {
        unlink $_;
        $self->log("error ($?) deleting file $_") if $?;
    }
    return;
}

# doesn't work with "named" elements (e.g. 'mon' instead of 1).
sub addtime {
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
            push(@list, $range % $max);
        }
    }
    # unique the list....
    my $seen = {};
    @list = grep { !exists $seen->{$_} } @list;

    foreach my $item (sort { $a <=> $b } @list) {
        $item += $add;
        if ($item > $max) {
            $overflow = int($item / ($max+1));
            $item = $item % ($max+1) + $min;
        }
    }

    return (join(",", @list), $overflow);
}

sub security_file {
    my ($file_type,$user_list) = @_;
    my $user_contents = '';
    my $file = '';

    for my $user (@{$user_list}) {
	$user_contents .= $user . "\n";
    }
    my $contents = "#\n# File generated by ncm-cron. DO NOT EDIT.\n#\n";
    $contents .= $user_contents;

    if ( $file_type eq 'deny' ) {
	$file = '/etc/cron.deny';
    } else {
	$file = '/etc/cron.allow';
    }

    my $changes = LC::Check::file("$file",
				  contents => encode_utf8($contents),
				  mode => 0644,
	);
    return $changes;
}

1;      # Required for PERL modules
