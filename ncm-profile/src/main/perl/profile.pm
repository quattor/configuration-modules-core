#${PMcomponent}

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Path 16.8.0 qw(unescape);

use File::Path;
use File::Basename;
use LC::Check;
use Encode qw(encode_utf8);

sub Configure
{

    my ($self, $config) = @_;

    my %scripts = ('sh' => {},
                   'csh' => {},
        );
    my %script_config_name;

    # Define paths for convenience.
    my $base = "/software/components/profile";

    # Load component configuration into a hash
    my $profile_config = $config->getElement($base)->getTree();
    my $scripts_config = $profile_config->{scripts};
    unless ( $scripts_config ) {
        $scripts_config = ();
    }

    # Location of list of scripts managed by this component
    my $managedScriptsList = '/usr/lib/ncm/config/profile/managed_files';

    # Get the configuration directory.
    my $defaultScriptDir = "/etc/profile.d";
    if ( $profile_config->{configDir} ) {
        $defaultScriptDir = $profile_config->{configDir};
    }

    # Get the default script name (without suffix).
    my $defaultScriptName = "env";
    if ( $profile_config->{configName} ) {
        $defaultScriptName = $profile_config->{configName};
    }

    # Copy default script configuration under 'scripts' (as for other scripts)
    if ( ($profile_config->{env}) || $profile_config->{path} ) {
        $scripts_config->{$defaultScriptName}->{env} = $profile_config->{env};
        $scripts_config->{$defaultScriptName}->{path} = $profile_config->{path};
        $scripts_config->{$defaultScriptName}->{flavors} = $profile_config->{flavors};
        $scripts_config->{$defaultScriptName}->{flavorSuffix} = $profile_config->{flavorSuffix};
    }


    # Loop over all scripts
    for my $escript (sort(keys(%{$scripts_config}))) {
        my $script = unescape($escript);
        if ( $script !~ /^\// ) {
            $script = $defaultScriptDir . '/' . $script;
        }
        $self->info("Building script $script contents...");

        my $entry_config = $scripts_config->{$escript};

        # Initialize the contents of the scripts.
        my $comment = "#\n# Created by ncm-profile. DO NOT EDIT.\n" .
                      "# Manual changes will be overwritten.\n#\n";
        my $sh = $comment;
        my $csh = $comment;

        # First loop over all of the environment variables.
        for my $envVar (sort(keys(%{$entry_config->{env}}))) {
            my $value = $entry_config->{env}->{$envVar};
            $sh .= "export $envVar=\"" . $self->escape_sh($value) . "\"\n";
            $csh .= "setenv $envVar \"". $self->escape_csh($value) . "\"\n";
        }
        $sh .= "\n";
        $csh .= "\n";

        # Now loop over all of the paths.
        for my $pathVar (sort(keys(%{$entry_config->{path}}))) {
            my $pathEntry = $entry_config->{path}->{$pathVar};
            my %epaths;       # A hash of existing elements.  This is used to avoid duplicates.

            # Do the prepended values first.  This make duplicate
            # removal easier later.
            my @pre;
            foreach my $v (@{$pathEntry->{prepend}}) {
                $self->debug(2,"$pathVar prepend list: adding value $v");
                push @pre, $v unless $epaths{$v};
                $epaths{$v} = 1;
            }

            # Now the definitive value if set if defined and written to script
            my @path;
            if ( $pathEntry->{value} ) {
                foreach my $v (@{$pathEntry->{value}}) {
                    $self->debug(2,"$pathVar base list: adding value $v");
                    push @path, $v unless $epaths{$v};
                    $epaths{$v} = 1;
                }

                my $s = join(':',@path);
                $s = '""' if ($s eq '');
                $self->debug(1,"$pathVar : Defining base value as $s");
                $sh .= "export $pathVar=\"$s\"\n";
                $csh .= "setenv $pathVar \"$s\"\n";
            }

            # Finally the appended values.
            my @post;
            foreach my $v (@{$pathEntry->{append}}) {
                $self->debug(2,"$pathVar append list: adding value $v");
                push @post, $v unless $epaths{$v};
                $epaths{$v} = 1;
            }

            # Now add the prepended values.  Be careful to ensure
            # proper behavior if the variable is not defined.
            if ( @pre > 0 ) {
                my $s = join(':',@pre);
                $self->debug(1,"$pathVar : prepending $s");

                my $ssh = $self->escape_sh($s);
                $sh .= "if [ -z \${$pathVar} ]; then\n";
                $sh .= "$pathVar=\"$ssh\"\n";
                $sh .= "else\n";
                $sh .= "$pathVar=\"$ssh:\${$pathVar}\"\n";
                $sh .= "fi\n";
                $sh .= "export $pathVar\n\n";

                my $scsh = $self->escape_csh($s);
                $csh .= "if (\$?$pathVar) then\n";
                $csh .= "setenv $pathVar \"$scsh:\${$pathVar}\"\n";
                $csh .= "else\n";
                $csh .= "setenv $pathVar \"$scsh\"\n";
                $csh .= "endif\n\n";
            }

            # Now add the prepended values.  Be careful to ensure
            # proper behavior if the variable is not defined.
            if ( @post > 0 ) {
                my $s = join(':',@post);
                $self->debug(1,"$pathVar : appending $s");

                my $ssh = $self->escape_sh($s);
                $sh .= "if [ -z \${$pathVar} ]; then\n";
                $sh .= "$pathVar=\"$ssh\"\n";
                $sh .= "else\n";
                $sh .= "$pathVar=\"\${$pathVar}:$ssh\"\n";
                $sh .= "fi\n";
                $sh .= "export $pathVar\n\n";

                my $scsh = $self->escape_csh($s);
                $csh .= "if (\$?$pathVar) then\n";
                $csh .= "setenv $pathVar \"\${$pathVar}:$scsh\"\n";
                $csh .= "else\n";
                $csh .= "setenv $pathVar \"$scsh\"\n";
                $csh .= "endif\n\n";
            }
        }

        $scripts{'csh'}->{$script} = $csh;
        $scripts{'sh'}->{$script} = $sh;
        # Keep track of key in config for this script as the script name is escaped in profile configuration
        $script_config_name{$script} = $escript;
    }


    # Update all scripts, if needed.
    # List of script is retrieved from keys in $scripts{sh} as it contains an entry
    # even if the flavor is not actually created.

    my %managedScripts;
    for my $script (sort(keys(%{$scripts{'sh'}}))) {
        my @scriptFlavors;
        if ( $scripts_config->{$script_config_name{$script}}->{flavors} ) {
            @scriptFlavors = @{$scripts_config->{$script_config_name{$script}}->{flavors}};
        } else {
            @scriptFlavors = keys(%scripts);
        }
        $self->info("Checking script $script (flavors: ".join(", ",@scriptFlavors).")...");

        for my $flavor (@scriptFlavors) {
            my $scriptName = $script;
            if ( $scripts_config->{$script_config_name{$script}}->{flavorSuffix} ) {
                $scriptName .= '.' . $flavor;
            }
            my $result = LC::Check::file($scriptName,
                                         backup => ".old",
                                         contents => encode_utf8($scripts{$flavor}->{$script}),
                                         mode => 0755,
                );
            unless ( $result >= 0 ) {
                $self->error("Error updating script $scriptName");
            }

            $managedScripts{$scriptName} = 1;       # Value meaningless
        }
    }


    # Remove scripts previously managed by this component but no longer part of the configuration.

    # Read list of previously managed scripts
    my %oldScripts;
    if ( -f $managedScriptsList ) {
        my $status = open (SCRIPTLIST, "$managedScriptsList");
        if ( $status ) {
            my @scriptList = <SCRIPTLIST>;
            close SCRIPTLIST;
            for my $script (@scriptList) {
                chomp $script;
                $oldScripts{$script} = 1;
            }
        } else {
            $self->error("Error opening managed script list ($managedScriptsList). Removed scripts not deleted.");
        }
    }

    # Add to oldScripts all existing scripts with extension .ncm-profile.c?sh in default directory.
    # These scrips where created by previous version of the component and should be
    # removed, except if they are still part of the current configuration.
    opendir DIR, $defaultScriptDir;
    my @legacyScripts = grep /\.ncm-profile.c?sh/, readdir DIR;
    closedir DIR;
    for my $script (@legacyScripts) {
        $script = $defaultScriptDir . '/' . $script;
        $oldScripts{$script} = 1;
    }

    # Actually remove scripts no longer part of the configuration
    for my $script (sort(keys(%oldScripts))) {
        unless ( $managedScripts{$script} ) {
            $self->info("Removing script $script (no longer part of configuration)");
            unlink $script;
        }
    }


    # Save the new list of managed scripts
    my $status = open(SCRIPTLIST, ">$managedScriptsList");
    if ( $status ) {
        $self->debug(1,"Updating list of managed scripts ($managedScriptsList)");
        print SCRIPTLIST join("\n",sort(keys(%managedScripts)))."\n";
        close SCRIPTLIST;
    } else {
        $self->error("Error creating managed script list ($managedScriptsList).");
    }


    return 0;
}

sub escape_sh
{
    my ($self, $s) = @_;
    $s =~ s/"/\\"/g;
    return $s;
}

sub escape_csh {
    my ($self, $s) = @_;
    $s =~ s/"/"\\""/g;
    return $s;
}


1;      # Required for PERL modules
