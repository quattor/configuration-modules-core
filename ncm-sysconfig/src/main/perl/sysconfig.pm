#${PMcomponent}

=head1 NAME

sysconfig: management of sysconfig files

=head1 DESCRIPTION

The I<sysconfig> component manages system configuration files in
C<< /etc/sysconfig >> . These are files which contain key-value pairs.
However there is the possibility to add verbatim text either before or after the key-value pair definitions.

=cut

use parent qw(NCM::Component CAF::Path);

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

use Readonly;

Readonly my $SYSCONFIGDIR => "/etc/sysconfig"; # The base directory for sysconfig files.

sub filelist_read
{
    my ($self) = @_;

    # Read first the list of sysconfig files which have been
    # previously managed by this component.  These will have to
    # be deleted if no longer in the configuration.
    my %filelist;
    my $fh = CAF::FileReader->open("$SYSCONFIGDIR/ncm-sysconfig", log => $self);
    while (my $line = <$fh>) {
        chomp($line);
        $filelist{$line} = 1;
    }
    $fh->close();

    return %filelist;
}

sub filelist_write
{
    my ($self, %filelist) = @_;

    # Write the list of managed configuration files.
    my $fh = CAF::FileWriter->open("$SYSCONFIGDIR/ncm-sysconfig", log => $self);
    for my $file (keys %filelist) {
        print $fh "$file\n";
    }
    $fh->close();

    return 1;
}

sub Configure
{
    my ($self, $config) = @_;

    # Load configuration into a hash
    my $sysconfig_config = $config->getTree($self->prefix());

    # Ensure that sysconfig directory exists.
    $self->directory($SYSCONFIGDIR, owner=>0, group=>0, mode=>0755);

    # This will be a list of the configuration files managed by this component.
    my %files_managed;

    my %files_previous = $self->filelist_read();

    # Loop over all of the defined files, writing each as necessary.
    if ( $sysconfig_config->{files} ) {
        foreach my $file (sort keys %{$sysconfig_config->{files}}) {

            my $pairs = $sysconfig_config->{files}->{$file};

            # Start with an empty file.
            my $contents = '';

            # Add the prologue if it exists.
            if (defined($pairs->{prologue})) {
                $contents .= "$pairs->{prologue}\n";
            }

            # Loop over the pairs adding the information to the file.
            for my $key (sort keys %$pairs) {
                if ($key ne 'prologue' && $key ne 'epilogue') {
                    my $value = $pairs->{$key};
                    # Remove any leading or trailing whitespace from the value
                    $value =~ s/^\s+|\s+$//g;
                    # Quote values containing whitespace.
                    # Only if they have not already been quoted and do not look like an array.
                    # If a value contains quotes, use a different quotation mark.
                    # Values without whitespace should not be modified.
                    if ($value !~ m/^".*"$/ && $value !~ m/^'.*'$/ && $value !~ m/^\(.*\)$/ && $value =~ m/\s/) {
                        if ($value =~ m/"/) {
                            $value = "'$value'";
                        } else {
                            $value = "\"$value\"";
                        }
                    }
                    $contents .= "$key=$value\n";
                }
            }

            # Add the epilogue if it exists.
            if (defined($pairs->{epilogue})) {
                $contents .= "$pairs->{epilogue}\n";
            }

            # Now actually update the file, if needed.
            my $fh = CAF::FileWriter->open("$SYSCONFIGDIR/$file", backup => ".old", log => $self);
            print $fh $contents;
            $fh->close();

            # Remove this file from the list of old configuration
            # files add to the new configuration files.
            delete($files_previous{"$SYSCONFIGDIR/$file"});
            $files_managed{"$SYSCONFIGDIR/$file"} = 1;
        }
    }

    # Remove any old configuration files which haven't been updated.
    for my $file (keys %files_previous) {
        $self->cleanup($file);
    }

    $self->filelist_write(%files_managed);

    return 1;
}

1; # Required for PERL modules
