# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# NCM component for autofs configuration
#
#
# ** Generated file : do not edit **
#
#######################################################################

package NCM::Component::autofs;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use File::Path;

use CAF::Process;
use LC::Check;

use EDG::WP4::CCM::Element qw(unescape);


local(*DTA);


##########################################################################
sub writeAutoMap($$@) {
##########################################################################
    my ($self,$mapname,$entries,$preserve) = @_;

    my $changes = 0;

    my $contents="# File managed by Quattor component ncm-autofs. DO NOT EDIT.\n\n";

    if ( $entries ) {
        for my $entry_e (keys(%{$entries})) {
          my $entry_config = $entries->{$entry_e};
          my $entry=unescape($entry_e);
          # For backward compatibility, useless with escaped values
          $entry=~s/__wildcard/\*/;
    
          my $opt = $entry_config->{options};
          # Ensure options start with a '-'
          if ( (length($opt) > 0) && ($opt !~ /^-/) ) {
            $opt = '-' . $opt;
          }
          my $location = $entry_config->{location};
          # Just in case, mandatory in schema...
          unless ( $location ) {
            $self->warn("Location for entry $entry in map $mapname is empty: skipping entry");
            next;
          }
    
          if ( $preserve ) {
            my $reentry=$entry; $reentry=~s/\*/\\\*/;
            $changes += NCM::Check::lines($mapname,
                                          linere => "^#?$reentry\\s+.*",
                                          goodre => "^$reentry\\s+$opt\\s+$location\$",
                                          good   => "$entry\t$opt\t$location",
                                          keep   => "first",
                                          add    => "last" );
          } else {
            $contents .= "$entry\t$opt\t$location\n";
          }
        }

    # No entries : if preserve is true, do not modify existing map, else erase its contents.
    } else {
      if ( $preserve ) {
        return 0;            # No change
      }
    };

    # When preserve is true, amp has already been updated.
    if ( $preserve == 0 ) {
      $changes = LC::Check::file($mapname,
                                 backup => ".ncm-autofs.old",
                                 contents => $contents,
                                 owner => "root",
                                 group => "root",
                                 mode => 0644
                                );

    }

    if ( $changes > 0 ) {
          $self->debug(1,"Map $mapname modified, $changes updates");
    }
    
    return $changes;
}

##########################################################################
sub Configure($$@) {
##########################################################################

    my ($self, $config) = @_;

    # Define paths for convenience.
    my $base = "/software/components/autofs";
    my $cnt  = 0;

    # Variables to keep track for each map of mountpoints and line prefix to use in
    # master map (used to comment out some entries).
    my %mount_points;
    my %master_entry_prefix;

    # Load configuration into a perl hash
    my $autofs_config = $config->getElement($base)->getTree();
    
    # Default is to preserve local edits to auto.aster
    my $preserveMaster = $autofs_config->{preserveMaster} && (-e '/etc/auto.master');
    if ( $preserveMaster ) {
      $self->debug(1,"Flag set to preserve master map existing content");
    };
      
    if ( $autofs_config->{maps} ) {
      foreach my $map (keys(%{$autofs_config->{maps}})) {
        my @map_mpoints;
        my $map_config = $autofs_config->{maps}->{$map};
        $self->info("Checking map $map...");
        
        if ( $map_config->{mpaliases} ) {
          $self->warn("Using depricated mpaliases (multiple mount) functionality for $map");
          foreach my $mpalias (@{$map_config->{mpaliases}}) {
            $self->debug(1,"Adding mount point alias $mpalias");
            push @map_mpoints, $mpalias;
          }
        }

        # Default mount point = /mapname
        if ( $map_config->{mountpoint} ) {
          push @map_mpoints, $map_config->{mountpoint};
        } elsif ( ! @map_mpoints ) {
          push @map_mpoints, "/".$map;
        }
        
        $mount_points{$map} = @map_moints;

        my $maptype = $map_config->{type};
        my $mapname = $map_config->{mapname};
        # Normally already checked by the schema
        if ( $mapname ) {
          if ( ($maptype eq 'file') and ($mapname !~ /^\//) ) {
            $self->error("Map file name for type file must be an absolute path ($mapname specified)");
          }
        } else {
          foreach ( $maptype ) {
            /program/ and $mapname="/etc/auto.$map";
            /file/ and $mapname="/etc/auto.$map";
            /yp/   and $mapname="auto.$map";
          }
          if ( ! $mapname ) {
            $self->error("Map $map file name undefined.");
          }
        }

        my $mpopts = $map_config->{options};
        # Ensure options start with a '-'
        if (  (length($mpopts) > 0) && ($mpopts !~ /^-/) ) {
          $mpopts = '-' . $mpopts;
        }

        # Check if existing entries not defined in config must be preserved
        # Default : true for backward compatibility
        my $preserve_entries = $map_config->{preserve} && (-e $mapname);
        if ( $preserve_entries ) {
           $self->debug(1,"Flag set to preserve map $map existing content");
        }

        if ( $map_config->{enabled} ) {
          $master_entry_prefix{$map} = "";
          if ( ($maptype eq 'file') || ($maptype eq 'direct') ) {
            my $changes = $self->writeAutoMap($mapname,$map_config->{entries},$preserve_entries);
            if ( $changes < 0 ) {
              $self->error("Error updating map $map ($mapname)");
              $master_entry_prefix{$map} = "#ERROR IN: ";
            } else {
              $cnt += $changes;
            }
          } elsif ( $maptype eq 'program' ) {
            my $status = LC::Check::status("$mapname",
                                           owner=> "root",
                                           group=>"root",
                                           mode=>0755);
            unless ( $status ) {
              $self->warn("Program map file $mapname cannot be made executable");
            }
          }
        } else {
          $master_entry_prefix{$map} = "#";
        }
      }
    }

    # Update auto.master if preserveMaster = true
    $self->info("Checking /etc/auto.master...");
    if ( $preserveMaster ) {
      $self->debug(1,"Update will preserve existing entries not managed by ncm-autofs");
      foreach my $map (keys(%mount_points)) {
        foreach my $mountp ( $mountpoints{$map} ) {
          $cnt+=NCM::Check::lines("/etc/auto.master",
                                  linere => "^#?( ERROR IN: )?$mountp\\s+.*",
                                  goodre => "^$master_entry_prefix{$map}$mountp\\s+".$maptype.":".$mapname."\\s+".$mpopts."\\s*\$",
                                  good   => "$master_entry_prefix{$map}$mountp\t$maptype:$mapname\t$mpopts",
                                  keep   => "first",
                                  add    => "last");
          }
        }
      }

    # Create/replace auto.master if preserveMaster is false (file managed exclusively by Quattor)
    } else {
      $auto_master_contents = "# File managed by Quattor component ncm-autofs. Do not edit.\n\n";
      foreach my $map (keys(%mount_points)) {
        foreach my $mountp ( $mountpoints{$map} ) {
          $auto_master_contents .= "$master_entry_prefix{$map}$mountp\t$maptype:$mapname\t$mpopts\n";
        }
      }
      $cnt += LC::Check::file("/etc/auto.master",
                           backup => ".ncm-autofs.old",
                           contents => $auto_master_contents,
                           owner => "root",
                           group => "root",
                           mode => 0644
                          );
    }

    #reload if changed the conf-file
    if($cnt) {
      $self->info("Reloading autofs");
      my $cmd = CAF::Process->new(['/sbin/service autofs reload'], log => $self);
      my $output = $cmd->output();       # Also executes the command
      if ( $? ) {
        $self->error('command "/sbin/service autofs reload" failed. Command ouput: '.$output);
        return;
      }
    }

    return 1;
  }

1;      # Required for PERL modules


