#${PMcomponent}

=head1 NAME

C<ncm-autofs>: NCM component to manage autofs configuration.

=head1 DESCRIPTION

The I<autofs> component manages autofs master map and generated maps. It allows
both exclusive management by the component or preservation of local changes.

=head1 EXAMPLES

=head2 Scenario 1 : Configure a NFS mountpoint

We will mount the NFS filesystem nfsserv.example.org: C<< /data >> under C<< /tmp_mnt/nfsdata >>

   prefix '/software/components/autofs/maps/data';
   'entries/nfsdata/location' = 'nfsserv.example.org:/data';
   'mapname' = '/etc/auto.nfsdata';
   'mountpoint' = '/tmp_mnt';
   'options' = 'rw,noatime,hard';

=head2 Scenario 2 : Configuration with dict() usage

    prefix '/software/components/autofs';
    'preserveMaster' = false;

    prefix '/software/components/autofs/maps/misc';
    'enabled' = true;
    'preserve' = false;
    'mapname' = '/etc/auto.misc';
    'type' = 'file';
    'mountpoint' = '/misc';
    'entries' = dict(
        'kickstart', dict(
            'location', 'misc.example.com:/misc'
        )
    );

    prefix '/software/components/autofs/maps/garden';
    'enabled' = true;
    'preserve' = false;
    'mapname' = '/etc/auto.garden';
    'type' = 'file';
    'options' = '';
    'mountpoint' = '/home/garden';
    'entries' = dict(
        escape('*'), dict(
            'options', '-rw,intr,rsize=8192,wsize=8192,actimeo=60,addr=10.21.12.10',
            'location', 'crown-city.albion.net:/home/garden/&'
        )
    );

=cut

use parent qw(NCM::Component);

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use LC::Check;
use Readonly;

Readonly my $AUTO_MASTER => '/etc/auto.master';
Readonly my $AUTOFS_CONF => '/etc/autofs.conf';
Readonly my $ERROR_PREFIX => "ERROR IN: ";

use EDG::WP4::CCM::Path qw(unescape);

# convenience method to handle file creation or editing
# $data is an array ref of array refs with [linere, goodre, linecontent]
# (no newline is added to linecontent)
sub _write_or_edit
{
    my ($self, $filename, $edit, $msg, $data) = @_;

    my $fh;

    my $attrs = {
        backup => ".ncm-autofs", # backups with edit too
        owner => "root",
        group => "root",
        mode => oct(644),
    };

    $self->debug(1, "$msg $filename ", $edit ? "" : "not ", "preserved.");

    if($edit) {
        $fh = CAF::FileEditor->new($filename, %$attrs);
    } else {
        $fh = CAF::FileWriter->new($filename, %$attrs);
        print $fh "# File managed by Quattor component ncm-autofs. Do not edit.\n\n";
    }

    foreach my $linedata (@$data) {
        if($edit) {
            $fh->add_or_replace_lines(@$linedata, ENDING_OF_FILE);
        } else {
            print $fh $linedata->[2];
        }
    }

    my $changed = $fh->close() || 0;
    $self->debug(1, "$msg $filename ", $changed ? "" : "not ", "modified.");

    # TODO: Handle errors; in case of such error return -1

    return $changed;
}

# generate a map
sub writeAutoMap
{
    my ($self, $mapname, $entries, $preserve) = @_;

    my $linedata;

    # Check if existing entries not defined in config must be preserved
    # Default : true for backward compatibility
    $preserve = 1 if (! defined($preserve));

    foreach my $entry_e (sort keys %$entries) {
        my $entry_config = $entries->{$entry_e};

        my $entry = unescape($entry_e);
        # For backward compatibility, useless with escaped values
        $entry =~ s/__wildcard/\*/;

        my $location = $entry_config->{location};
        my $options = $entry_config->{options} || "";

        # Ensure options start with a '-'
        $options =~ s/^(?!(?:-|$))/-/;

        # Just in case, mandatory in schema...
        unless ( $location ) {
            $self->warn("Location for entry $entry in map $mapname is empty: skipping entry");
            next;
        }

        my $reentry = $entry;
        $reentry =~ s/\*/\\*/;

        push(@$linedata, [
                 '^#?' . $reentry . '\s+.*', # linere
                 '^' . $reentry . '\s+' . $options . '\s+' . $location . '\s*$', # goodre
                 "$entry\t" . $options . "\t" . $location . "\n",
             ]);
    }

    # when no entries are defined, the file is wiped unless it's preserved.
    return 0 if ($preserve and ! $linedata);

    my $changed = $self->_write_or_edit($mapname, $preserve, "Map", $linedata);

    return $changed;
}

sub Configure
{

    my ($self, $config) = @_;

    # Define paths for convenience.
    my $cnt = 0;


    # Variables to keep track for each map of mountpoints and the mount attributes to use
    # with each map.
    # The key is the same in both hashes (map name)
    my %mount_points;
    my %master_entry_attrs;

    # Load configuration into a perl hash
    my $autofs_config = $config->getElement($self->prefix())->getTree();

    if ( $autofs_config->{maps} ) {
        foreach my $map (sort keys %{$autofs_config->{maps}}) {
            my @map_mpoints;
            my $map_config = $autofs_config->{maps}->{$map};
            $self->info("Checking map $map...");

            if ( $map_config->{mpaliases} ) {
                $self->warn("Using deprecated mpaliases (multiple mount) functionality for $map");
                foreach my $mpalias (@{$map_config->{mpaliases}}) {
                    $self->debug(1,"Adding mount point alias $mpalias");
                    push @map_mpoints, $mpalias;
                }
            }

            # Default mount point = /mapname
            if ( $map_config->{mountpoint} ) {
                push @map_mpoints, $map_config->{mountpoint};
            } elsif ( ! @map_mpoints ) {
                push @map_mpoints, "/$map";
            }

            my $maptype = $map_config->{type};
            my $mapname = $map_config->{mapname};
            # Normally already checked by the schema
            if ( $mapname ) {
                if ( ($maptype eq 'file') and ($mapname !~ /^\//) ) {
                    # TODO and return instead of continuing?
                    $self->error("Map $map file name for type file must be an absolute path ($mapname specified)");
                }
            } else {
                foreach ( $maptype ) {
                    m/^(program|file)$/ and $mapname = "/etc/auto.$map";
                    m/^yp$/ and $mapname = "auto.$map";
                }
                if ( ! $mapname ) {
                    $self->error("Map $map file name undefined (type $maptype).");
                }
            }

            $master_entry_attrs{$mapname} = {
                type => $maptype,
                options => $map_config->{options} || "",
            };
            # Ensure options start with a '-'
            $master_entry_attrs{$mapname}->{options} =~ s/^(?!(?:-|$))/-/;

            if ( $map_config->{enabled} ) {
                $master_entry_attrs{$mapname}->{prefix} = "";
                if ( ($maptype eq 'file') || ($maptype eq 'direct') ) {
                    my $changes = $self->writeAutoMap($mapname, $map_config->{entries}, $map_config->{preserve});
                    if ( $changes < 0 ) {
                        $self->error("Error updating map $map ($mapname)");
                        $master_entry_attrs{$mapname}->{prefix} = "#$ERROR_PREFIX";
                    } else {
                        $cnt += $changes;
                    }
                } elsif ( $maptype eq 'program' ) {
                    my $status = LC::Check::status(
                        $mapname,
                        owner => "root",
                        group => "root",
                        mode => oct(755),
                        );

                    # TODO: check for changes?
                    if ( ! defined( $status ) || $status < 0 ) {
                        $self->warn("Program map file $mapname cannot be made executable");
                    }
                }
            } else {
                $master_entry_attrs{$mapname}->{prefix} = "#";
            }

            # Add mount points to the global list
            $mount_points{$mapname} = \@map_mpoints;
        }
    }


    # Update auto.master if preserveMaster = true
    $self->info("Checking $AUTO_MASTER...");

    my $masterdata;
    foreach my $map (sort keys %mount_points) {
        my $map_attrs = $master_entry_attrs{$map};
        my $map_type_prefix = $map_attrs->{type} eq 'direct' ? '' : $map_attrs->{type}.':';
        foreach my $mountp ( @{$mount_points{$map}} ) {
            $self->debug(2, "Checking entry for mount point $mountp (map $map)...");
            push(@$masterdata, [
                     '^#?\s*(' . $ERROR_PREFIX . '\s*)?' . $mountp . '\s+.*', # linere
                     '^' . $map_attrs->{prefix}.$mountp .'\s+' . $map_type_prefix.$map . '\s+' . $map_attrs->{options} . '\s*$', # goodre
                     $map_attrs->{prefix} . "$mountp\t$map_type_prefix$map\t" . $map_attrs->{options} . "\n",
                 ]);
        }
    }

    my $masterchanged = $self->_write_or_edit($AUTO_MASTER, $autofs_config->{preserveMaster}, "Master map", $masterdata);
    $cnt += $masterchanged;

    # autofs.conf; no preserve
    if ($autofs_config->{conf}) {
        my $autofs_conf = EDG::WP4::CCM::TextRender->new(
            "autofs_conf.tt",
            $config->getElement($self->prefix()."/conf"),
            relpath => 'autofs',
            log => $self,
            element => { yesno => 1 },
            );
        if (!$autofs_conf) {
            $self->error("TT processing of $AUTOFS_CONF failed: $autofs_conf->{fail}");
        }
        my $autofs_conf_fh = $autofs_conf->filewriter($AUTOFS_CONF);
        my $autofs_conf_changed = $autofs_conf_fh->close();
        $self->debug(1, "$AUTOFS_CONF ", $autofs_conf_changed ? "" : "not ", "modified.");

        $cnt += $autofs_conf_changed;
    } else {
        $self->debug(1, "Skipping $AUTOFS_CONF.");
    }

    # reload if any of the conf-files changed
    if($cnt) {
        $self->info("Checking if autofs is running");
        # TODO: CAF::Service
        my $cmd = CAF::Process->new(['/sbin/service', 'autofs', 'status'],
                                    log => $self, keeps_state => 1);
        my $output = $cmd->output();
        if ( $? ) {
            $self->info("autofs not running, skipping reload.");
        } else {
            $self->info("Reloading autofs");
            $cmd = CAF::Process->new(['/sbin/service', 'autofs', 'reload'], log => $self);
            $output = $cmd->output();       # Also executes the command
            if ( $? ) {
                $self->error('command "/sbin/service autofs reload" failed. Command ouput: '.$output);
                return;
            }
        }
    } else {
        $self->verbose("No changes detected in any of the config files; not reloading autofs.");
    }

    return 1;
}

1;      # Required for PERL modules
