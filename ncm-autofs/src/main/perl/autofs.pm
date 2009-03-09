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
use LC::Process;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use File::Path;

use EDG::WP4::CCM::Element qw(unescape);


local(*DTA);


##########################################################################
sub getValueDefault() {
##########################################################################
    my ($config, $pathname, $default) = @_;

    if ($config->elementExists($pathname)) {
        return $config->getValue($pathname);
    } else {
      return $default;
    }
}


##########################################################################
sub writeAutoMap($$@) {
##########################################################################
    my ($self,$config,$mapname,$cfpathname,$preserve) = @_;

    my ($changes) = (0);

    $self->debug(2,"Updating $mapname");

    stat $mapname or do {
      # create empty file only if map does not yet exist
      local(*TMPH);
      open TMPH,">$mapname" and close TMPH;
    };
    LC::Check::status("$mapname", owner=> "root", group=>"root", mode=>0644);

    my $contents="# File managed by Quattor component ncm-autofs. Do not edit.\n\n";

    if ( ! $config->elementExists("$cfpathname") ) {
      return 1 if ( $preserve == 1 );
    }
    else
    {
    my $entrylist = $config->getElement("$cfpathname");
    while ( $entrylist->hasNextElement() ) {
      my $entry_e=$entrylist->getNextElement()->getName();
      my $entry=unescape($entry_e);
      # For backward compatibility, useless with escaped values
      $entry=~s/__wildcard/\*/;

      my $opt = &getValueDefault($config,"$cfpathname/$entry_e/options","");
      # Ensure options start with a '-'
      if ( $opt !~ /^-/ ) {
        $opt = '-' . $opt;
      }
      my $location = &getValueDefault($config,"$cfpathname/$entry_e/location","");
      if ( $location eq "" ) {
        $self->warn("Location for entry $entry in $mapname is empty,".
                  " ignoring map");
        return 0;
      }

      if ( $preserve == 1 ) {
        my $reentry=$entry; $reentry=~s/\*/\\\*/;
        $changes+=NCM::Check::lines( $mapname,
              linere => "^#?$reentry\\s+.*",
              goodre => "^$reentry\\s+$opt\\s+$location\$",
              good   => "$entry\t$opt\t$location",
              keep   => "first",
              add    => "last" );

      } else {
        $contents .= "$entry\t$opt\t$location\n";
      }
    }
    }

    if ( $preserve == 0 ) {
      $changes = LC::Check::file($mapname,
                                 backup => ".ncm-autofs.old",
                                 contents => $contents,
                                 owner => "root",
                                 group => "root",
                                 mode => 0644
                                );

    }

    $changes and
          $self->info("Automount map $mapname modified, $changes updates");

    return 1;
}

##########################################################################
sub Configure($$@) {
##########################################################################

    my ($self, $config) = @_;

    # Define paths for convenience.
    my $base = "/software/components/autofs";
    my $cnt  = 0;
    my $auto_master_contents='';

    # Default is to preserve local edits to auto.aster
    my $preserveMaster = 1;
    if ( $config->elementExists("$base/preserveMaster") &&
          $config->getElement("$base/preserveMaster")->getValue() eq 'false') {
      $preserveMaster = 0;
      $auto_master_contents = "# File managed by Quattor component ncm-autofs. Do not edit.\n\n";
    }


    if ( $config->elementExists("$base/maps") ) {

      my $maps = $config->getElement("$base/maps");
      while ( $maps->hasNextElement() ) {
        my $map=$maps->getNextElement()->getName();

        my @mountpoints;

        # Check if existing entries not defined in config must be preserved
        # Default : true for backward compatibility
        my $preserve_entries = 1;
        if ( $config->elementExists("$base/maps/$map/preserve") ) {
          if ( $config->getElement("$base/maps/$map/preserve")->getValue() eq "false" ) {
            $preserve_entries = 0;
          } elsif ( $config->getElement("$base/maps/$map/preserve")->getValue() ne "true" ) {
            $self->error("Invalid value for preserve flag of map $map");
          }
        }

        if ( $config->elementExists("$base/maps/$map/mpaliases") ) {
          $self->warn("Using depricated mpaliases (multiple mount) functionality for $map");
          my $mpaliases = $config->getElement("$base/maps/$map/mpaliases");
          while ( $mpaliases->hasNextElement() ) {
            push @mountpoints,$mpaliases->getNextElement()->getValue();
          }
        }

        if ( $config->elementExists("$base/maps/$map/mountpoint") ) {
          push @mountpoints,$config->getValue("$base/maps/$map/mountpoint");
        } elsif ( ! @mountpoints ) {
          push @mountpoints, "/".$map
        }

        my $maptype=$config->getValue("$base/maps/$map/type");
        my $mapname;
        my $mpopts;
        if ( $config->elementExists("$base/maps/$map/mapname") ) {
          $mapname=$config->getValue("$base/maps/$map/mapname");
        } else { # we need to guess a mapname
          foreach ( $maptype ) {
          /program/ and $mapname="/etc/auto.$map";
          /file/ and $mapname="/etc/auto.$map";
          /yp/   and $mapname="auto.$map";
          }
        }
        $mapname or $self->error("Cannot figure out mapname for $map, sorry.");
        ( $maptype eq 'file' ) and ( $mapname !~ /^\// ) and
           $self->error("File mapname for type file not absolute ($mapname)");

        if ( $config->elementExists("$base/maps/$map/options") ) {
          $mpopts=$config->getValue("$base/maps/$map/options");
          # Ensure options start with a '-'
          if ( $mpopts !~ /^-/ ) {
            $mpopts = '-' . $mpopts;
          }
        }

        my $etok;
        if ( &getValueDefault($config,"$base/maps/$map/enabled",'true')
                ne 'false' ) {
          $etok="";
          if ( ( $maptype eq 'file' || $maptype eq 'direct' ) ) {
            $self->writeAutoMap($config,$mapname,"$base/maps/$map/entries",$preserve_entries) or
                                                                              $etok="#ERROR IN: ";
          } elsif ( $maptype eq 'program' ) {
            defined LC::Check::status("$mapname",
                              owner=> "root", group=>"root", mode=>0755) or
            $self->warn("Program map file $mapname cannot be made executable");
          }
        } else {
          $etok="#";
        }

        foreach my $mountp ( @mountpoints ) {
          if ( $preserveMaster ) {
            $cnt+=NCM::Check::lines(
                "/etc/auto.master",
                linere => "^#?( ERROR IN: )?$mountp\\s+.*",
                goodre => "^$etok$mountp\\s+".$maptype.":".$mapname.
                                "\\s+".$mpopts."\\s*\$",
                good   => "$etok$mountp\t$maptype:$mapname\t$mpopts",
                keep   => "first",
                add    => "last");
          } else {
            $auto_master_contents .= "$etok$mountp\t$maptype:$mapname\t$mpopts\n";
          }
        }
      }
    }

    # Update auto.master if preserveMaster is false (file managed exclusively by Quattor)
    if ( ! $preserveMaster ) {
      $cnt = LC::Check::file("/etc/auto.master",
                           backup => ".ncm-autofs.old",
                           contents => $auto_master_contents,
                           owner => "root",
                           group => "root",
                           mode => 0644
                          );
    }

    #reload if changed the conf-file
    if($cnt) {
      $self->info("auto.master map modified, reloading autofs");
      unless (LC::Process::run('/sbin/service autofs reload')) {
        $self->error('command "/sbin/service autofs reload" failed');
        return;
      }
    }

    return 1;
  }

1;      # Required for PERL modules


