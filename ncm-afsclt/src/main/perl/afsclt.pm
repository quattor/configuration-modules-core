# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::afsclt;

use strict;
use Readonly;
use NCM::Component;
use NCM::Check;
use LWP::Simple;
use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;

use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

Readonly my $AFS_CACHEINFO => '/usr/vice/etc/cacheinfo';
Readonly my $LOCALCELLDB   => '/usr/vice/etc/CellServDB';
Readonly my $THISCELL      => '/usr/vice/etc/ThisCell';
Readonly my $THESECELLS    => '/usr/vice/etc/TheseCells';
Readonly my $AFSD_ARGS     => '/etc/afsd.args';
Readonly my $PREFIX        => '/software/components/afsclt';

Readonly my $AFS_MOUNTPOINT_DEF => '/afs';


sub Configure {
    my ( $self, $config ) = @_;

    my $afsclt_config = $config->getElement($PREFIX)->getTree();

    $self->Configure_Cell($afsclt_config);
    $self->Configure_TheseCells($afsclt_config);
    $self->Configure_Cache($afsclt_config);
    $self->Configure_CellServDB($afsclt_config);
    $self->Configure_Afsd_Args($afsclt_config);
}

sub Configure_Cell {
    my ( $self, $config ) = @_;
    unless ( defined($config->{thiscell}) ) {
        $self->error("$PREFIX/thiscell missing in the configuration");
        return 1;
    }

    my $thiscell_fh = CAF::FileWriter->new( $THISCELL, log => $self );
    print $thiscell_fh "$config->{thiscell}\n";

    if ( $thiscell_fh->close() ) {
        $self->info("Updated thiscell to $config->{thiscell}");
    }

    return 0;
}

sub Configure_TheseCells {
    my ( $self, $config ) = @_;

    if ( defined($config->{thesecells}) ) {
        my $thesecells_fh = CAF::FileWriter->new( $THESECELLS, log => $self );
        print $thesecells_fh join ( " ", @{$config->{thesecells}} ) . "\n";
        if ( $thesecells_fh->close() ) {
            $self->info("Configured cell list for authentication $THESECELLS");
        }
    } elsif ( -f $THESECELLS ) {
        if ($NoAction) {
            $self->info("Would remove $THESECELLS");
        } else {
            if ( unlink($THESECELLS) ) {
                $self->info("Removed cell list for authentication $THESECELLS");
            } else {
                $self->error("Could not remove $THESECELLS: $!");
            }
        }
    }

    return 0;
}

sub Configure_Cache {
    my ( $self, $config ) = @_;

    my $run_cache       = 0;     # how much cache the AFS kernel module believes it now has
    my $file_cache      = 0;     # how much cache is actually configured now in the config file
    my $file_cachemount = '';    # where should the cache be mounted per config file
    my $new_cache       = 0;     # in 1k blocks.
    my $file_afsmount   = '';

    if ( defined($config->{cachesize}) ) {
        $new_cache = $config->{cachesize}
    } else {
        $self->info("$PREFIX/cachesize undefined: not setting cache size");
        return 1;
    }

    if ( defined($config->{cachemount}) ) {
        $file_cachemount = $config->{cachemount};    # mount point for AFS cache partition
    } else {
        $self->debug(1, "No explicit cache mount point defined in the configuration: will use currently defined one, if any");
    }

    if ( defined($config->{afs_mount}) ) {
        $file_afsmount = $config->{afs_mount};    # AFS mount point
    } else {
        $self->debug(1, "No explicit AFS mount point defined in the configuration");
    }

    my $proc = CAF::Process->new( [ "fs", "getcacheparms" ], log => $self, keeps_state => 1 );
    my $output = $proc->output();
    if ( !( $? >> 8 ) && $output =~ /AFS using \d+ of the cache's available (\d+) (\w+) byte blocks/ ) {
        if ( $2 ne "1K" ) {
            $self->error("Cannot handle $2 (non-1K) AFS cache block sizes");
            return 1;
        }
        $run_cache = $1;
    }
    else {
        $self->warn("Cannot determine current AFS cache size, changing only config file");
    }

    my $afs_cacheinfo_fh = CAF::FileEditor->new( $AFS_CACHEINFO, log => $self );
    $afs_cacheinfo_fh->cancel();
    $self->debug(2, "$AFS_CACHEINFO current contents: >>>$afs_cacheinfo_fh<<<");
    if ( "$afs_cacheinfo_fh" =~ m;^([^:]+):([^:]+):(\d+|AUTOMATIC)$; ) {
        $file_afsmount   = $1 if $file_afsmount eq "";
        $file_cachemount = $2 if $file_cachemount eq "";
        $file_cache      = $3;
    } elsif ( "$afs_cacheinfo_fh" ne "" ) {
        $self->error("Cannot parse stored AFS cache mount or size from $AFS_CACHEINFO");
        return 1;
    } else {
        $self->debug(1, "No existing cacheinfo file found");
    }
    $afs_cacheinfo_fh->close();

    if ( $new_cache ne "AUTOMATIC" ) {
        # sanity check - don't allow cachesize bigger than 95% of a partition size
        $proc = CAF::Process->new( [ "df", "-k", $file_cachemount ], log => $self, keeps_state => 1 );
        foreach my $line ( split ( "\n", $proc->output() ) ) {
            if ($line =~ m{^.*?\s+(\d+)\s+\d+\s+\d+\s+\d+%\s+(.*)}) {
                my $disk_cachesize = $1;
                my $mount          = $2;
                if ( $mount eq $file_cachemount && $new_cache > 0.95 * $disk_cachesize ) {
                    $self->error("Cache size ($disk_cachesize) on $mount cannot exceed 95% of its partition size. Not changing.");
                    return 1;
                }
            }
        }
    }

    # Adjust cacheinfo file if needed.
    # Force string interpolation of cache size as it can be AUTOMATIC
    if ( $file_afsmount eq "" ) {
        $self->debug(1, "AFS mount point not defined: using default ($AFS_MOUNTPOINT_DEF)");
        $file_afsmount = $AFS_MOUNTPOINT_DEF;
    }
    $afs_cacheinfo_fh = CAF::FileWriter->new( $AFS_CACHEINFO, log => $self );
    print $afs_cacheinfo_fh "$file_afsmount:$file_cachemount:$new_cache\n";
    if ( $afs_cacheinfo_fh->close() ) {
        $self->info("Changed AFS cache config ($AFS_CACHEINFO). New cache size (1K blocks): $new_cache (current: $run_cache)");
    }

    # adjust online (in-kernel) value
    if ( $run_cache && ( $new_cache ne "AUTOMATIC" ) && ( $run_cache != $new_cache ) ) {
        $proc = CAF::Process->new([ "fs", "setcachesize", $new_cache ], log => $self );
        $output = $proc->output();
        if ( $? >> 8 ) {
            $self->warn( "Problem changing running AFS cache size via \"$proc\": $output" );
        }
        else {
            $self->info("Changed running AFS cache $run_cache -> $new_cache (1K blocks)");
        }
    }

    return 0;
}

sub Configure_CellServDB {
    my ( $self, $config ) = @_;
    my $master_cellservdb;
    if ( defined($config->{cellservdb}) ) {
        $master_cellservdb = $config->{cellservdb};
        if ( $master_cellservdb =~ m/^\/\w/i ) {    # non-URI -> file
            $master_cellservdb = "file://" . $master_cellservdb;
        } elsif ( $master_cellservdb !~ m/^(ftp|http|file)/i ) {    # known URIs
            $self->error("Unsupported protocol to access master CellServDB ($master_cellservdb), giving up");
            return 1;
        }
    } else {
        return 0;
    }

    # LWP::Simple means  no error messages etc.
    my $cellservdb_content = LWP::Simple::get($master_cellservdb);
    if ( !$cellservdb_content ) {
        $self->info("Cannot read $master_cellservdb, AFS cell info not changed");
        return 1;
    }

    my $cellservdb_fh = CAF::FileWriter->new($LOCALCELLDB, log => $self);
    print $cellservdb_fh $cellservdb_content;
    if ($cellservdb_fh->close()) {
        $self->info("Updated CellServDB");
    }

    return $self->update_afs_cells();
}

# update the list of known AFS cells and run "fs newcell" when needed
# This will only add new cells, not remove currently known ones.
#
sub update_afs_cells ( $$ ) {
    my ($self) = @_;
    my ( $cell, %seen, %ipaddrs, @hosts, $todo, @todo, $error, $afsutil );

    my $localcelldb_fh = CAF::FileEditor->new( $LOCALCELLDB, log => $self ); # TODO use FileReader
    $localcelldb_fh->cancel();
    foreach my $line ( split ( /\n/, "$localcelldb_fh" ) ) {
        if ($line =~ /^>(.\S+)/) {
            $cell = $1;
            $ipaddrs{$cell} = [];
        } elsif ($line =~ /^(\S+)\s+\#\s*\S+/) {
            # new entry
            push ( @{ $ipaddrs{$cell} }, $1 );
        }
    }
    $localcelldb_fh->close();
    foreach $cell ( sort keys(%ipaddrs) ) {
        @{ $ipaddrs{$cell} } = sort( @{ $ipaddrs{$cell} } );
        $self->debug( 1, "CellServDB $cell -> @{$ipaddrs{$cell}}" );
    }

    # read known cells
    @todo = ();
    my $proc = CAF::Process->new( [ "fs", "listcell", "-numeric" ], log => $self, keeps_state => 1 );
    my $output = $proc->output();

    if ( $? >> 8 ) {
        $self->error( "Cannot read current AFS cell info via fs: $output" );
        return 1;
    }

    foreach my $line ( split ( /\n/, $output ) ) {
        chomp $line;
        next unless $line =~ /^Cell\s+(\S+)\s+on hosts\s+(\S.+)\.$/;
        $cell = $1;
        @hosts = split ( /\s+/, $2 );
        $seen{$cell} = 1;
        next unless $ipaddrs{$cell} && @{ $ipaddrs{$cell} };
        @hosts = sort(@hosts);
        if ( "@hosts" ne "@{$ipaddrs{$cell}}" ) {
            push ( @todo, $cell );
            $self->debug( 1, "Cell info for $cell changed from @hosts to @{$ipaddrs{$cell}}" );
        }
    }

    # check new cells
    foreach $cell ( sort keys(%ipaddrs) ) {
        next if $seen{$cell};
        next unless @{ $ipaddrs{$cell} };
        push ( @todo, $cell );
        $self->info("New cell $cell with @{$ipaddrs{$cell}}");
    }

    if (@todo) {
        $error = 0;
        foreach $cell (@todo) {
            $proc = CAF::Process->new( [ "fs", "newcell", $cell, @{ $ipaddrs{$cell} } ], log => $self );
            my $output = $proc->output();
            if ( $? >> 8 ) {
                $self->error( "Error while updating AFS cell info for $cell: $output" );
                $error++;
            }
        }
        if ( !$error ) {
            $self->info( "Updated cell information for @todo", $error );
        }
    }
    else {
        $self->info("Nothing to do for AFS cell information");
    }

    return 0;
}

sub Configure_Afsd_Args {
    my ( $self, $config ) = @_;

    if ( defined($config->{afsd_args}) ) {
        my $fh = CAF::FileWriter->new( $AFSD_ARGS, log => $self, backup => ".old" );
        foreach my $key (sort keys %{$config->{afsd_args}}) {
            print $fh "$key:$config->{afsd_args}->{$key}\n";
        }
        if ( $fh->close() ) {
            $self->info("Updated afsd.args");
        }
    }

    return 0;
}

1;    #required for Perl modules
