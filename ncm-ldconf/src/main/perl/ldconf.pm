#${PMcomponent}

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;
use LC::Check;
use File::Basename;

my $ldconfig_config_dir = '/etc/ld.so.conf.d';
my $ldconf_config_file = 'ncm-ldconf.conf';


sub Configure
{

    my ($self, $config) = @_;

    # Define paths for convenience.
    my $base = "/software/components/ldconf";

    # File to modify (default is /etc/ld.so.conf).
    my $fname = $config->getValue("$base/conffile");
    my $fname_dir = dirname($fname);
    $fname_dir =~ s%/$%%;        # Be sure there is no trailing /
    $self->debug(2,'Root directory for ld configuration = '.$fname_dir);
    my $ldconfig_config_rel_dir = $ldconfig_config_dir;
    $ldconfig_config_rel_dir =~ s%^$fname_dir/%%;
    $self->debug(2,'Relative directory for ld includes = '.$ldconfig_config_rel_dir);

    # Hash containing all paths (used to make paths unique).
    my %toAdd;

    # Hash to help transitioning from SL3 to SL4 behaviour
    my %toRemove;

    # Changes made to configuration. Run of ldconfig required.
    my $changes = 0;

    # If the list of paths exists, get the full list.
    if ($config->elementExists("$base/paths")) {

        # Get the list of VOs to configure, should be a list.
        my @paths = $config->getElement("$base/paths")->getList();
        foreach my $element (@paths) {
            my $path = $element->getValue();

            # Ensure that value is OK.
            if ($path =~ m/^\s*(\S+)\s*$/) {
                $path = $1;
                $toAdd{$path} = 'new';
            } else {
                $self->warn("bad path ($path) in configuration");
            }
        }
    }


    # Read ldconfig main configuration file, if it exists and
    # detect if 'include' directive is supported (assume that if
    # supported, it is used).

    my @config_contents;
    my $include_supported = 0;
    if (-e $fname) {
        open TMP, "<$fname";
        @config_contents = <TMP>;
        close TMP;
        $include_supported = grep(/^include/, @config_contents);
    }


    # If ldconfig supports 'include' directive, create a specific file for entries
    # managed by ncm-ldconf

    if ( $include_supported ) {
        # Create configuration file with Quattor managed entries
        my $contents = "# File managed by Quattor component ncm-ldconf. Don't edit\n\n";
        $contents .= join("\n",(sort keys %toAdd)) . "\n";
        my $config_file = "$ldconfig_config_dir/$ldconf_config_file";
        my $result = LC::Check::file($config_file,
                                     backup => ".old",
                                     contents => $contents,
                                     owner => "root",
                                     group => "root",
                                     mode => 0644,
            );
        if ( $result ) {
            $self->log("config_file updated");
            $changes = $result;
        }
        %toRemove = %toAdd;
        $toAdd{'include '.$ldconfig_config_rel_dir.'/*.conf'} = 'new';
    }

    # Entries must be added to main configuration file (D: /etc/ld.so.conf), if it exists.
    # In case, the new SL4 behaviour is used, remove corresponding entries from
    # main configuration file.

    if ( @config_contents ) {

        # Split on valid delimiters.
        # Need to process specifically 'include' directive.
        # This processing includes joining include directive and the following line
        # in case they have been splitted (bug in version < 1.0.8)
        my $buggy_line = 0;
        foreach my $line (@config_contents) {
            chomp $line;
            if ( ($line =~ /^include/) || $buggy_line ) {
                if ( $line =~ /^include\s*$/ ) {      # Need to join with next line
                    $self->debug(1,'Buggy include line found... joining with next line');
                    $buggy_line = 1;
                    next;
                } else {
                    # include line is parsed to removed multiple or trailing spaces in order
                    # to avoid duplicating entries
                    my $directory;
                    if ( $buggy_line ) {
                        $self->debug(1,"Continuation of buggy include line found ($line)");
                        $buggy_line = 0;
                        $line =~ m/\s*(\S+)\s*/;
                        $directory = $1;
                    } else {
                        $line =~ m/include\s*(\S+)\s*/;
                        $directory = $1;
                    };
                    $directory =~ s%^$fname_dir/%%;
                    my $entry = 'include ' . $directory;
                    # Rewrite the line with the expected format if necessary
                    if ( $entry ne $line ) {
                        $toAdd{$entry} = 'modified';
                    } elsif ( exists($toAdd{$entry}) && ($toAdd{$entry} ne 'modified') ) {
                        $toAdd{$entry} = 'existing';
                    }
                }
            } else {
                my @directories = split /[,:\s\t]+/m, $line;
                foreach my $directory (@directories) {
                    $toAdd{$directory} = 'existing';
                }
            }
        }
    }


    # Remove from main configuration file, entries moved to the Quattor specific file.
    foreach my $entry (keys(%toAdd)) {
        if ( exists($toRemove{$entry}) ) {
            # If entry is marked 'existing', means it is currently in the main configuration file
            if ( $toAdd{$entry} eq 'existing' ) {
                $self->debug(1,"Removing $entry from main configuration file");
                $changes = 1;
            }
            delete($toAdd{$entry});
        }
    }


    # Determine if there are any changes to be made and update main configuration
    # file if necessary.
    foreach my $key (keys %toAdd) {
        $changes = 1 if ($toAdd{$key} ne 'existing');
    }

    if ($changes) {
        # For debugging
        my $entry_list = '';
        foreach my $entry (keys(%toAdd)) {
            $entry_list .= $entry . " : " . $toAdd{$entry} . "\n";
        }
        $self->debug(2, "List of entries for main configuration file :\n".$entry_list);

        # Create the merged output.
        my $contents = join("\n",(sort keys %toAdd)) . "\n";

        # Already exists. Make backup and create new file.
        my $result = LC::Check::file($fname,
                                     backup => ".old",
                                     contents => $contents,
                                     owner => "root",
                                     group => "root",
                                     mode => 0644,
            );
        $self->log("$fname updated") if $result;

        # Make sure to reinitialize the ld.so.conf cache.
        `/sbin/ldconfig`;
        $self->warn("error running ldconfig") if $?;

    } else {
        $self->log("no changes need to be made");
    }

    return 1;
}

1;      # Required for PERL modules
