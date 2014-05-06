# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


# This component needs a 'ceph' user. 
# The user should be able to run these commands with sudo without password:
# /usr/bin/ceph-deploy
# /usr/bin/python -c import sys;exec(eval(sys.stdin.readline()))
# /usr/bin/python -u -c import sys;exec(eval(sys.stdin.readline()))
# /bin/mkdir
#

package NCM::Component::Ceph::crushmap;

use 5.10.1;
use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use LC::Exception;
use LC::Find;
use LC::File qw(makedir);

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
# taint-safe since 1.23;
# Packages @ http://www.city-fan.org/ftp/contrib/perl-modules/RPMS.rhel6/ 
# Attention: Package has some versions like 1.2101 and 1.2102 .. 
use Data::Compare 1.23 qw(Compare);
use Data::Dumper;
use Config::Tiny;
use File::Basename;
use List::Util qw( min max );
use JSON::XS;
use Readonly;
use Socket;
our $EC=LC::Exception::Context->new->will_store_all;
Readonly my $CRUSH_TT_FILE => 'ceph/crush.tt';

# Get the osd name from the host and path
sub get_osd_name {
    my ($self, $host, $location) = @_;
    my @catcmd = ('/usr/bin/ssh', $host, 'cat');
    my $id = $self->run_command_as_ceph([@catcmd, "$location/whoami"]) or return 0;
    chomp($id);
    $id = $id + 0; # Only keep the integer part
    return "osd.$id";
}   

# Do actions after deploying of daemons and global configuration
sub do_crush_actions {
    my ($self, $cluster, $gvalues) = @_;
    if ($cluster->{crushmap} && $gvalues->{is_deploy}) {
        $self->process_crushmap($cluster->{crushmap}, $cluster->{osdhosts}, $gvalues) or return 0;
    }
    return 1;
}

# Get crushmap and store backup
sub ceph_crush {
    my ($self, $crushdir) = @_;
    my $jstr = $self->run_ceph_command([qw(osd crush dump)]) or return 0;
    my $crushdump = decode_json($jstr); #wrong weights, but ignored at this moment
    $self->run_ceph_command(['osd', 'getcrushmap', '-o', "$crushdir/crushmap.bin"]);
    $self->run_command(['/usr/bin/crushtool', '-d', "$crushdir/crushmap.bin", '-o', "$crushdir/crushmap"]);
    $self->git_commit($crushdir, "$crushdir/crushmap", "decoded crushmap from ceph");
    return $crushdump;
}

# Merge the osd info in the crushmap hierarchy
sub crush_merge {
    my ($self, $buckets, $osdhosts, $devices) = @_;
    foreach my $bucket ( @{$buckets}) {
        my $name = $bucket->{name};
        if ($bucket->{buckets}) {
            # Recurse.

            if (!$self->crush_merge($bucket->{buckets}, $osdhosts, $devices)){
                $self->debug(2, "Failed to merge buckets of $bucket->{name} with osds",
                    "Buckets:", Dumper($bucket->{buckets}));  
                return 0;
            }
        } else {
            if ($bucket->{type} eq 'host') {
                if ($osdhosts->{$name}){
                    my $osds = $osdhosts->{$name}->{osds};
                    $bucket->{buckets} = [];
                    foreach my $osd (sort(keys %{$osds})){
                        my $osdname = $self->get_osd_name($name, $osds->{$osd}->{osd_path});
                        if (!$osdname) {
                            $self->error("Could not find osd name for ", 
                                $osds->{$osd}->{osd_path}, " on $name");
                            return 0;
                        }
                        my $osdb = { 
                            name => $osdname, 
                            # Ceph is rounding the weight
                            weight => int((1000 * $osds->{$osd}->{crush_weight}) + 0.5)/1000.0 , 
                            type => 'osd',
                        };
                        if ($osds->{$osd}->{labels}) {
                            $osdb->{labels} = $osds->{$osd}->{labels};
                        }
                        push(@{$bucket->{buckets}}, $osdb);
                        (my $id = $osdname) =~ s/^osd\.//;
                        my $device = { 
                            id => $id, 
                            name => $osdname 
                        };
                        push(@$devices, $device);
                    }
                } else {
                    $self->error("No such hostname in ceph cluster: $name");
                    return 0;
                }    
            }
        }
    }
    return 1;
}

# get a bucket hash for a labeled root
sub labelize_bucket {
    my ($self, $tbucket, $label ) = @_; 
    my %lhash = %{$tbucket};
    if ($lhash{type} ne 'osd') {
        $lhash{name} = "$lhash{name}-$label";
    }
    if ($tbucket->{buckets} && @{$tbucket->{buckets}}) { 
        $lhash{buckets} = [];
        foreach my $bucket (@{$tbucket->{buckets}}) {
            if (!$bucket->{labels} || ($label ~~ $bucket->{labels})) {
                push(@{$lhash{buckets}}, $self->labelize_bucket($bucket, $label));
            }        
        }
        if (!@{$lhash{buckets}}) {
            # check/eliminate empty buckets
            $self->warn("Bucket $lhash{name} has no child buckets after labeling");
        }
    }
    delete $lhash{labels}; # Not needed anymore
    return \%lhash;
}

#If applicable, replace buckets with labeled ones
sub labelize_buckets {
    my ($self, $buckets ) = @_;    
    my @newbuckets = ();
    foreach my $bucket (@{$buckets}){
        if ($bucket->{labels} && @{$bucket->{labels}}) {
            foreach my $label (@{$bucket->{labels}}) {
                push(@newbuckets, $self->labelize_bucket($bucket, $label));
            }
        } else {
             push(@newbuckets, $bucket);
        }
    }
    return \@newbuckets;
}

# Escalate the weights that have been set
sub set_weights {
    my ($self, $bucket ) = @_;

    if ($bucket->{buckets}) {
        my $weight = 0.00;
        foreach my $child (@{$bucket->{buckets}}) {
            my $chweight = $self->set_weights($child);
            if (!defined($chweight)) {
                $self->debug(1, "Something went wrong when getting weight of $child->{name}");
                return;
            } 
            $weight += $chweight;
        }
        if (!$bucket->{weight}){
            $bucket->{weight} = $weight;
        } elsif ($weight != $bucket->{weight}) {
            $self->warn("Bucket weight of $bucket->{name} ", 
                "in Quattor differs from the sum of the child buckets! ",
                "Quattor: $bucket->{weight} ", 
                "Sum: $weight");
        }
    } else {
        if ($bucket->{type} ne 'osd') {
            $self->error('Lowest level of crushmap should be an OSD, but ', $bucket->{name},
                ' has no child buckets and is not an osd!' );
            return;
        }
    }
    return $bucket->{weight};
}

# Makes an one-dimensional array of buckets from a hierarchical one.
# Also fix default attributes (See Quattor schema)
sub flatten_buckets {
    my ($self, $buckets, $flats, $defaults) = @_;
    my $titems = [];
    foreach my $tmpbucket ( @{$buckets}) {
        # First fix attributes
        if (!$defaults) { #top bucket; set default values
            $defaults = { alg => $tmpbucket->{defaultalg}, hash => $tmpbucket->{defaulthash}};
        }
        my %bucketh = %$defaults;
        # update with tmpbucket
        @bucketh{keys %$tmpbucket} = values %$tmpbucket;
        my $bucket = \%bucketh;
        
        push(@$titems, { name => $bucket->{name}, weight => $bucket->{weight} });
        if ($bucket->{buckets}) {
            my $citems = $self->flatten_buckets($bucket->{buckets}, $flats, $defaults);         
            $bucket->{items} = $citems; 
            delete $bucket->{buckets};
        
        }
        if($bucket->{type} ne 'osd'){
            push(@$flats, $bucket);
        }
    }
    return $titems;
}

# Build up the quattor crushmap
sub quat_crush {
    my ($self, $crushmap, $osdhosts) = @_;
    my @newtypes = ();
    my $type_id = 0;
    my ($type_osd, $type_host);
    foreach my $type (@{$crushmap->{types}}) {
        #Must at least contain 'host' and 'osd', because we do the merge on these types.
        if ($type eq 'osd') {
            $type_osd = 1;
        } elsif ($type eq 'host') {
            $type_host = 1;
        } 
        push(@newtypes, { type_id => $type_id, name => $type });
        $type_id +=1;
    }
    if (!$type_osd || !$type_host){
        $self->error("list of types should at least contain 'osd' and 'host'!");
        return 0; 
    }
    $crushmap->{types} = \@newtypes;

    my $devices = [];
    if (!$self->crush_merge($crushmap->{buckets}, $osdhosts, $devices)){
        $self->error("Could not merge the required information into the crushmap");
        return 0;
    }
    my @sorted = sort { $a->{id} <=> $b->{id} } @$devices;
    $crushmap->{devices} = \@sorted;
    
    $crushmap->{buckets} = $self->labelize_buckets($crushmap->{buckets});
    
    foreach my $bucket (@{$crushmap->{buckets}}){
        if (!defined($self->set_weights($bucket))) {
            $self->debug(1, "Something went wrong when setting weight of $bucket->{name}");
            return 0;
        }
    }
    my $newbuckets=[];
    $self->flatten_buckets($crushmap->{buckets}, $newbuckets);
    $crushmap->{buckets} = $newbuckets;

    return $crushmap;
}

# Collect the already used crush ids, all id's should be unique
sub set_used_bucket_id {
    my ($self, $id, $crush_ids) = @_;
    if ($id ~~ @{$crush_ids}) {
        $self->error("ID $id already used in crushmap buckets!");
        return 0;
    } 
    push(@{$crush_ids}, $id);
    return 1;
}

# Collect the already used ruleset ids, id's can be the same
sub set_used_ruleset_id {
    my ($self, $id, $ruleset_ids) = @_;
    
    push(@{$ruleset_ids}, $id);
    return 1;
}

# Generate an available (not used) ruleset id
# Make sure the used id's are already inserted
sub generate_ruleset_id {
    my ($self, $ruleset_ids) = @_;
    my $newid;
    if (!@{$ruleset_ids}) { #crushmap from scratch
        $newid = 0;
    } else {
        my $max = max(@{$ruleset_ids});
        $newid = $max + 1;
    }
    $self->set_used_ruleset_id($newid, $ruleset_ids);
    return $newid;
}

# Generate an available (not used) crush bucket id
# Make sure the used id's are already inserted
sub generate_bucket_id {
    my ($self, $crush_ids) = @_;
    my $newid;
    if (!@{$crush_ids}) { #crushmap from scratch
        $newid = -1;
    } else {
        my $min = min(@{$crush_ids});
        $newid = $min - 1;
    }
    $self->set_used_bucket_id($newid, $crush_ids);
    return $newid;
}

# Compare Crushmap buckets
# Also get ids here
sub cmp_crush_buckets {
    my ($self, $cephbucks, $quatbucks) = @_;
    my $crush_ids = [];
    foreach my $cbuck (@{$cephbucks}) {
        my $found = 0;
        foreach my $qbuck (@{$quatbucks}){
            if ($cbuck->{name} eq $qbuck->{name}){
                if ($cbuck->{type_name} ne $qbuck->{type}) {
                    $self->warn("Type of $cbuck->{name} changed from $cbuck->{type_name} to $qbuck->{type}!");
                }
                if (!$self->set_used_bucket_id($cbuck->{id}, $crush_ids)) {
                     $self->error("Could not set id of $cbuck->{name}!");
                     return 0;
                }
                $qbuck->{id} = $cbuck->{id};
                $found = 1;
                last;
            }
        } 
        if (!$found) {
            $self->info("Existing ceph bucket $cbuck->{name} removed from quattor crushmap");
        }
    }
    foreach my $qbuck (@{$quatbucks}){
        if (!defined($qbuck->{id})){
            $qbuck->{id} = $self->generate_bucket_id($crush_ids);
            $self->info("Bucket $qbuck->{name} added to crushmap");
        }     
    }
    return 1;
}
        
# Comparing crushmap rules 
# Also get rulesets here
sub cmp_crush_rules {
    my ($self, $cephrules, $quatrules) = @_;
    my $ruleset_ids = [];
    foreach my $crule (@{$cephrules}) {
        my $found = 0;
        foreach my $qrule (@{$quatrules}){
            if ($crule->{rule_name} eq $qrule->{name}){
                if (defined($qrule->{ruleset})){
                    if ($crule->{ruleset} ne $qrule->{ruleset}) {
                        $self->warn("Ruleset of $qrule->{name} changed",
                            "from $crule->{ruleset} to $qrule->{ruleset}!");
                    }
                } else {
                    $qrule->{ruleset} = $crule->{ruleset};
                }
                $self->set_used_ruleset_id($qrule->{ruleset}, $ruleset_ids);
                $found = 1;
                last;
            }
        }
        if (!$found) {
            $self->info("Existing ceph rule $crule->{rule_name} removed from quattor crushmap");
        }
    }
    foreach my $qrule (@{$quatrules}){
        if (!defined($qrule->{ruleset})){
            $qrule->{ruleset} = $self->generate_ruleset_id($ruleset_ids);
            $self->info("Rule $qrule->{name} added to crushmap");
        }     
    }       
     
    return 1;
}

# Compare the generated crushmap with the installed one
sub cmp_crush {
    my ($self, $cephcr, $quatcr) = @_;
    # Use already existing ids
    # Devices: this should match exactly
    if (!Compare($cephcr->{devices}, $quatcr->{devices})) {
        $self->warn("Devices list of Quattor does not match with devices in existing crushmap.");
    }
    # Types
    if (!Compare($cephcr->{types}, $quatcr->{types})) {
        $self->warn("Types are changed in the crushmap!");
    }    
 
    # Buckets
    $self->debug(2, "Comparing crushmap buckets"); 
    $self->cmp_crush_buckets($cephcr->{buckets}, $quatcr->{buckets}) or return 0;
        
    # Rules 
    $self->debug(2, "Comparing crushmap rules"); 
    $self->cmp_crush_rules($cephcr->{rules}, $quatcr->{rules});
     
    return 1;
}

# write out the crushmap and install into cluster
sub write_crush {
    my ($self, $crush, $crushdir) = @_;
    #Use tt files
    my $plainfile = "$crushdir/crushmap"; 

    my $fh = CAF::FileWriter->new($plainfile, log => $self);
    
    print $fh  "# begin crush map\n";
    $self->debug(5, "Crushmap hash ready to be written to file:", Dumper($crush));
    my $ok = $self->template()->process($CRUSH_TT_FILE, $crush, $fh);
    if (!$ok) {
        $self->error("Unable to render template $CRUSH_TT_FILE : ",
                     $self->template()->error());
        $fh->cancel();
        $fh->close();
        return 0;
    }
    my $changed = $fh->close();

    if ($changed) {
        $self->git_commit($crushdir, $plainfile, "crushmap edited by ncm-ceph");
        # compile and set crushmap    
        if (!$self->run_command(['/usr/bin/crushtool', '-c', "$plainfile", '-o', "$crushdir/crushmap.bin"])){
            $self->error("Could not compile crushmap!");
            return 0;
        }
        if (!$self->run_ceph_command(['osd', 'setcrushmap', '-i', "$crushdir/crushmap.bin"])) {
            $self->error("Could not install crushmap!");
            return 0;
        }
        $self->debug(1, "Changed crushmap installed");
    } else {
        $self->debug(2, "Crushmap not changed");
    }
    return 1;
}   

# Processes the Ceph CRUSHMAP
sub process_crushmap {
    my ($self, $crushmap, $osdhosts, $gvalues) = @_;
    my $crushdir = $gvalues->{qtmp} . 'crushmap';
    my $cephcr = $self->ceph_crush($crushdir) or return 0;
    my $quatcr = $self->quat_crush($crushmap, $osdhosts) or return 0;
    $self->cmp_crush($cephcr, $quatcr) or return 0;

    return $self->write_crush($quatcr, $crushdir);
}
1; # Required for perl module!
