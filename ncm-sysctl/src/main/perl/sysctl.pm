#${PMcomponent}

#######################################################################
#
# sysctl component
#
# generates the sysctl configuration file, /etc/sysctl.conf
#
#
# For license conditions see http://www.eu-datagrid.org/license.html
#
#######################################################################

use parent qw(NCM::Component);
use LC::Exception qw(throw_error);
our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

use CAF::FileWriter;
use CAF::Process;
use NCM::Check;

sub Configure
{
    my ($self,$config)=@_;

    # Load config into a hash
    my $sysctl_config = $config->getElement($self->prefix)->getTree();
    my $variables = $sysctl_config->{variables};
    my $configFile = $sysctl_config->{confFile};
    my $changes;
    my $sysctl_exe = $sysctl_config->{command};
    unless ($sysctl_exe =~ m{^(/\S+)$}) {
        throw_error("Invalid sysctl command on the profile: $sysctl_exe");
        return();
    }

    $sysctl_exe = $1;

    unless (-x $sysctl_exe) {
        $self->error ("$sysctl_exe not found");
        return;
    }

    if ($configFile =~ m{/}) {
        $self->debug(1, "confFile setting is a path");
        $changes = $self->sysctl_file($configFile, $sysctl_exe, $variables);
    } else {
        $self->debug(1, "confFile is a relative filename, using sysctl.d");
        $changes = $self->sysctl_dir($configFile, $sysctl_exe, $variables);
        # update the configFile path for the sysctl execution
        $configFile = "/etc/sysctl.d/$configFile";
    }

    #
    # execute /sbin/sysctl -p if any change made to sysctl configuration file
    #
    if ( $changes ) {
        $self->verbose("Changes made to $configFile, running sysctl on it");
        my $cmd = CAF::Process->new([$sysctl_exe, '-e', '-p', $configFile],
                                    log => $self);
        my $output = $cmd->output;
        if ($?) {
            $self->error("Error loading sysctl settings from $configFile: ",
                         $output);
        } else {
            $self->debug(1, "$sysctl_exe output: $output");
        }
    }
    return 1;
}

# new method for managing files in /etc/sysctl.d
sub sysctl_dir
{
    my ($self, $configFile, $sysctl_exe, $variables) = @_;
    # *.bak is on the list of ignored files
    my $fh = CAF::FileWriter->new("/etc/sysctl.d/$configFile",
                                  backup => ".bak",
                                  owner => "root",
                                  group => "root",
                                  mode => 0444,
                                  log => $self);
    print $fh "# Written by ncm-sysctl, do not modify\n";
    foreach my $key (sort(keys(%$variables))) {
        my $value = $variables->{$key};
        print $fh "$key = $value\n";
    }
    return $fh->close();
}

# legacy code for managing /etc/sysctl.conf
sub sysctl_file
{
    my ($self, $configFile, $sysctl_exe, $variables) = @_;
    unless (-e $configFile && -w $configFile) {
        $self->warn("Sysctl configuration file does not exist ",
                    "or is not writable ($configFile)");
        return;
    }

    my $changes = 0;
    foreach my $key (sort(keys(%$variables))) {
        my $value = $variables->{$key};
        my $st = NCM::Check::lines($configFile,
                                   backup => '.old',
                                   linere => '#?\s*'.$key.'\s*=.*',
                                   goodre => '\s*'.$key.'\s*=\s*'.$value,
                                   good => "$key = $value",
                                   add => 'last'
                                  );
        if ($st < 0) {
            $self->error("Failed to update sysctl $key (value=$value)");
        } else {
            $changes += $st;
        }
    }
    return $changes;
}

1; # required for Perl modules
