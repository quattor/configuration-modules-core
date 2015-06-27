# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::autofs;

use strict;
use warnings;

use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use File::Path;

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use LC::Check;
use Readonly;

Readonly my $AUTO_MASTER => '/etc/auto.master';

use EDG::WP4::CCM::Element qw(unescape);


local(*DTA);

# This method checks if a line is present using linere.
# If present, it checks the line content is the expected one (goordre)
# or it replaces it by 'good'.
# If not present, the line is added at the end of the current content.
# content_ref must be a string with the file content (multilines) as returned
# by File::Editor string_ref() method.
# Largely based on NCM::Check::lines ideas.
#
# TODO: why not use CAF::FileEditor->replace_lines()?
sub updateMap($$$$$) {
    my ($self, $content_ref, $linere, $goodre, $good) = @_;

    my $function_name = "updateMap";

    my $changes = 1;       # Assume change done

    if ( ${$content_ref} =~ /$linere/m ) {
        if ( ${$content_ref} !~ /$goodre/m ) {
            $self->debug(2,"$function_name: line found but not matching goodre ($goodre), replacing with <<<$good>>>");
            ${$content_ref} =~ s/$linere/$good/m;
        } else {
            $self->debug(2,"$function_name: line and up-to-date (matching <<<$goodre>>>)");
            $changes = 0;
        }
    } else {
        $self->debug(2,"$function_name: no match found for linere ($linere)");
        ${$content_ref} .= $good."\n";
    }

    return $changes;
}

sub writeAutoMap($$@) {
    my ($self, $mapname, $entries, $preserve) = @_;

    my %entry_attrs;

    if ( $entries ) {
        for my $entry_e (sort keys %{$entries}) {
            my $entry_config = $entries->{$entry_e};
            my $entry = unescape($entry_e);
            # For backward compatibility, useless with escaped values
            $entry =~ s/__wildcard/\*/;

            $entry_attrs{$entry} = ();
            $entry_attrs{$entry}->{options} = $entry_config->{options};

            # Ensure options start with a '-'
            if ( (length($entry_attrs{$entry}->{options}) > 0) && ($entry_attrs{$entry}->{options} !~ /^-/) ) {
                $entry_attrs{$entry}->{options} = '-' . $entry_attrs{$entry}->{options};
            }
            $entry_attrs{$entry}->{location} = $entry_config->{location};

            # Just in case, mandatory in schema...
            unless ( $entry_attrs{$entry}->{location} ) {
                $self->warn("Location for entry $entry in map $mapname is empty: skipping entry");
                next;
            }
        }
    }

    # Update the map if preserve=true
    my $changes = 0;

    if ( $preserve ) {
        $self->debug(1, "Map $mapname entries preserved.");
        # No entries : if preserve is true, do not modify existing map, else erase its contents.
        unless ( %entry_attrs ) {
            # No changes
            return 0;
        }

        # TODO: Force/set same permission as FileWriter
        my $map_fh = CAF::FileEditor->new($mapname);
        my $map_contents_ref = $map_fh->string_ref();

        foreach my $entry (sort keys %entry_attrs) {
            $self->debug(2,"Checking entry for mount point $entry...");
            my $entry_attrs = $entry_attrs{$entry};
            my $reentry = $entry;
            $reentry =~ s/\*/\\*/;
            $changes += $self->updateMap($map_contents_ref,
                                         '^#?' . $reentry . '\s+.*',
                                         '^' . $reentry . '\s+' . $entry_attrs{$entry}->{options} . '\s+' . $entry_attrs{$entry}->{location} . '$',
                                         "$entry\t" . $entry_attrs{$entry}->{options} . "\t" . $entry_attrs{$entry}->{location},
                );
        }
        $map_fh->close();

        # Create/replace map
    } else {
        $self->debug(1, "Map $mapname entries not preserved.");
        my $contents="# File managed by Quattor component ncm-autofs. DO NOT EDIT.\n\n";
        foreach my $entry (sort keys %entry_attrs) {
            $contents .= "$entry\t" . $entry_attrs{$entry}->{options} . "\t".$entry_attrs{$entry}->{location} . "\n";
        }

        my $map_fh = CAF::FileWriter->new(
            $mapname,
            backup => ".ncm-autofs",
            owner => "root",
            group => "root",
            mode => 0644
        );
        print $map_fh $contents;
        $changes = $map_fh->close() || 0;
    }

    if ( $changes > 0 ) {
        $self->debug(1, "Map $mapname modified, $changes updates");
    }

    return $changes;
}

# wrapper around -e for unittesting
sub _file_exists
{
    my ($self, $filename) = @_;
    return -e $filename;
}

sub Configure($$@)
{

    my ($self, $config) = @_;

    # Define paths for convenience.
    # TODO; use self->prefix() or move this to Readonly
    my $base = "/software/components/autofs";
    my $cnt = 0;
    my $error_prefix = "ERROR IN: ";

    # Variables to keep track for each map of mountpoints and the mount attributes to use
    # with each map.
    # The key is the same in both hashes (map name)
    my %mount_points;
    my %master_entry_attrs;

    # Load configuration into a perl hash
    my $autofs_config = $config->getElement($base)->getTree();

    # Default is to preserve local edits to $AUTO_MASTER
    # TODO FileEditor can handle non-existing files; so this is not needed?
    my $preserveMaster = $autofs_config->{preserveMaster} && $self->_file_exists($AUTO_MASTER);
    $self->debug(1, "Flag set to ", $preserveMaster ? "" : "not " ,
                 "preserve master map $AUTO_MASTER existing content");

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

            $master_entry_attrs{$mapname} = ();
            $master_entry_attrs{$mapname}->{type} = $maptype;
            $master_entry_attrs{$mapname}->{options} = $map_config->{options} || "";
            # Ensure options start with a '-'
            # TODO: use $master_entry_attrs{$mapname}->{options} =~ s/^(?!(?:-|$))/-/;
            if (  (length($master_entry_attrs{$mapname}->{options}) > 0) && ($master_entry_attrs{$mapname}->{options} !~ /^-/) ) {
                $master_entry_attrs{$mapname}->{options} = '-' . $master_entry_attrs{$mapname}->{options};
            }

            # Check if existing entries not defined in config must be preserved
            # Default : true for backward compatibility
            # TODO FileEditor can handle non-existing files; so this is not needed?
            my $preserve_entries = $map_config->{preserve} && $self->_file_exists($mapname);
            $self->debug(1, "Flag set to ", $preserve_entries ? "" : "not " ,
                         "preserve map $map existing content");

            if ( $map_config->{enabled} ) {
                $master_entry_attrs{$mapname}->{prefix} = "";
                if ( ($maptype eq 'file') || ($maptype eq 'direct') ) {
                    my $changes = $self->writeAutoMap($mapname,$map_config->{entries},$preserve_entries);
                    if ( $changes < 0 ) {
                        $self->error("Error updating map $map ($mapname)");
                        $master_entry_attrs{$mapname}->{prefix} = '#'.$error_prefix;
                    } else {
                        $cnt += $changes;
                    }
                } elsif ( $maptype eq 'program' ) {
                    my $status = LC::Check::status("$mapname",
                                                   owner => "root",
                                                   group => "root",
                                                   mode => 0755);
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
    if ( $preserveMaster ) {
        $self->debug(1,"Update will preserve existing entries in $AUTO_MASTER not managed by ncm-autofs");
        my $master_fh = CAF::FileEditor->new($AUTO_MASTER);
        my $master_contents_ref = $master_fh->string_ref();

        foreach my $map (sort keys %mount_points) {
            my $map_attrs = $master_entry_attrs{$map};
            my $map_type_prefix = $map_attrs->{type} eq 'direct' ? '' : $map_attrs->{type}.':';
            foreach my $mountp ( @{$mount_points{$map}} ) {
                $self->debug(2, "Checking entry for mount point $mountp (map $map)...");
                # TODO: replace with replace_lines ?
                $cnt += $self->updateMap($master_contents_ref,
                                         '^#?\s*('.$error_prefix.'\s*)?'.$mountp.'\s+.*',
                                         '^'.$map_attrs->{prefix}.$mountp.'\s+'.$map_type_prefix.$map.'\s+'.$map_attrs->{options}.'\s*$',
                                         $map_attrs->{prefix}."$mountp\t$map_type_prefix$map\t".$map_attrs->{options},
                    );
            }
        }
        $master_fh->close();

    # Create/replace auto.master if preserveMaster is false (file managed exclusively by Quattor)
    } else {
        $self->debug(1,"Update will not preserve existing entries in $AUTO_MASTER not managed by ncm-autofs");
        my $master_contents = "# File managed by Quattor component ncm-autofs. Do not edit.\n\n";
        foreach my $map (sort keys %mount_points) {
            my $map_attrs = $master_entry_attrs{$map};
            foreach my $mountp ( @{$mount_points{$map}} ) {
                my $map_type_prefix = $map_attrs->{type} eq 'direct' ? '' : $map_attrs->{type}.':';
                $master_contents .= $map_attrs->{prefix}.
                    "$mountp\t$map_type_prefix$map\t".$map_attrs->{options}."\n";
            }
        }
        my $master_fh = CAF::FileWriter->new(
            $AUTO_MASTER,
            backup => ".ncm-autofs",
            owner => "root",
            group => "root",
            mode => 0644
        );
        print $master_fh $master_contents;
        $cnt += $master_fh->close() || 0;
    }

    # reload if changed the conf-file
    if($cnt) {
        $self->info("Checking if autofs is running");
        # TODO: CAF::Service
        my $cmd = CAF::Process->new(['/sbin/service', 'autofs', 'status'], log => $self);
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
    }

    return 1;
}

1;      # Required for PERL modules
