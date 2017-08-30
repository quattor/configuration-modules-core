#${PMcomponent}

# Implementation of ncm-amandaserver
# Author: Laura del Caño Novales <laura.delcano@ft.uam.es>

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use CAF::Process;
use CAF::FileWriter;
use LC::File qw(makedir);

use constant PATH       => '/software/components/amandaserver/';
use constant AMANDA_CONFIG_DIR => '/etc/amanda';
use constant AMANDA_USER => 'amanda';
use constant AMANDA_HOSTS_FILE => '.amandahosts';

# getpwnams values.
use constant { NAME     => 0,
               PASSWD   => 1,
               UID      => 2,
               GID      => 3,
               QUOTA    => 4,
               COMMENT  => 5,
               GCOS     => 6,
               HOMEDIR  => 7,
               SHELL    => 8,
               EXPIRE   => 9
       };

my ($uid, $gid, $home);

# Prints tapetypes section
sub print_tapetypes
{
        my ($self, $fh, $tapetypes) = @_;
        
        my @quoted_pars = qw(comment lbl-templ);

        foreach my $tapetype (@{$tapetypes}) {
        	print $fh "define tapetype $tapetype->{'tapetype_name'} {\n";
                while (my ($k1, $v1) = each %{$tapetype->{'tapetype_conf'}}) {
                	# If parameter is on the quoted_pars array print it with quotes
                	if (scalar(grep(/^$k1$/, @quoted_pars)) > 0) {
                        print $fh "\t$k1 \"$v1\"\n";
                    } elsif ($k1 eq 'inc_tapetypes') {
                        foreach my $i (@$v1) {
                        	print $fh "\t$i\n";
                        }
                    } else {
                    	print $fh "\t$k1 $v1\n";
                    }
                }
                print $fh "}\n";
        }
}

# Prints dumptypes section
sub print_dumptypes
{
        my ($self, $fh, $dumptypes) = @_;
        
        my @quoted_pars = qw(auth comment program);

        foreach my $dumptype (@{$dumptypes}) {
        	print $fh "define dumptype $dumptype->{'dumptype_name'} {\n";
                while (my ($k1, $v1) = each %{$dumptype->{'dumptype_conf'}}) {
                	# If parameter is on the quoted_pars array print it with quotes
                	if (scalar(grep(/^$k1$/, @quoted_pars)) > 0) {
                        print $fh "\t$k1 \"$v1\"\n";
                    } elsif ($k1 eq 'inc_dumptypes') {
                        foreach my $i (@$v1) {
                        	print $fh "\t$i\n";
                        }
                    # 'exclude' and 'include' parameter are printed with quotes only on the pathname
                    } elsif ($k1 eq 'exclude' || $k1 eq 'include') {
                    	$v1 =~ m/^([\w|\s]+)\s(.+)$/;
                        print $fh "\t$k1 $1 \"$2\"\n";
                    } else {
                    	print $fh "\t$k1 $v1\n";
                    }
                }
                print $fh "}\n";
        }
}

# Prints interfaces section
sub print_interfaces
{
        my ($self, $fh, $interfaces) = @_;

		my @quoted_pars = qw(comment);
		
        foreach my $interface (@{$interfaces}) {
        	print $fh "define interface $interface->{'interface_name'} {\n";
                while (my ($k1, $v1) = each %{$interface->{'interface_conf'}}) {
					# If parameter is on the quoted_pars array print it with quotes
                	if (scalar(grep(/^$k1$/, @quoted_pars)) > 0) {
                        print $fh "\t$k1 \"$v1\"\n";
                    } elsif ($k1 eq 'inc_interfaces') {
                        foreach my $i (@$v1) {
                        	print $fh "\t$i\n";
                        }
                    } else {
                    	print $fh "\t$k1 $v1\n";
                    }
                }
                print $fh "}\n";
        }
}

# Prints amanda.conf file.
sub print_conf_file
{
        my ($self, $fh, $cfg, $backup) = @_;
        
        my @quoted_pars = qw(org mailto dumpuser printer tapedev rawtapedev tpchanger string
        					changerfile labelstr disklist infofile logdir indexdir tapelist includefile);
        
        # local variables needed to create the virtual tapes
        my $tpchanger = "";
        my $tapecycle = 0;
        my $tapedev = "";
        my $tapelist = AMANDA_CONFIG_DIR . "/$backup/tapelist";
        # print general options
        while (my ($k, $v) = each %{$cfg->{'config'}->{'general_options'}}) {
        		# If element is 'tpchanger' store it on a local var
        		if ($k eq 'tpchanger') {
        			$tpchanger=$v;
        		}
        		# If element is 'tapecycle' store it on a local var
        		if ($k eq 'tapecycle') {
        			$tapecycle=$v;
        		}
        		# If element is 'tapedev' store it on a local variable
        		if ($k eq 'tapedev') {
        			$tapedev = $v;
        		}
        		# If element is 'tapelist' store it on a local variable
        		if ($k eq 'tapelist') {
        			$tapelist = $v;
        		}        		
				# If element is 'logdir', 'indexdir' or 'infofile' create the path
        		if (($k eq 'logdir')||($k eq 'indexdir')||($k eq 'infofile')) {
        			makedir("$v");
        			# Cambiar owner del dir creado
       				chown($uid, $gid, $v);
        		}
                # If element is 'columnspec' format it to print it
                if ($k eq 'columnspec') {
                    print $fh "$k$v->{name}=$v->{space}:$v->{width}\n";
                } elsif (scalar(grep(/^$k$/, @quoted_pars)) > 0) {
                # The elements that are on the quoted_pars array are printed quoted
                	print $fh "$k \"$v\"\n";
                } else {
                	print $fh "$k $v\n";
                }
        }

        # print holdingdisk sections

		my @quoted_pars_hd = qw(comment directory);
		
        while (my ($k, $v) = each %{$cfg->{'config'}{'holdingdisks'}}) {
                print $fh "holdingdisk $k {\n";
                while (my ($k1, $v1) = each (%$v)) {
                	# If element is 'directory' create the path
                	if ($k1 eq 'directory') {
        				makedir("$v1");
        				# Cambiar owner del dir creado
       					chown($uid, $gid, $v1);
        			}
        			# The elements that are on the quoted_pars array are printed quoted
                    if (scalar(grep(/^$k1$/, @quoted_pars_hd)) > 0) {
                		print $fh "\t$k1 \"$v1\"\n";
                	} else {
                		print $fh "\t$k1 $v1\n";
                	}
                }
                print $fh "}\n";
        }

        # print tapetype sections
        $self->print_tapetypes($fh, $cfg->{'config'}{'tapetypes'});

        # print dumptype sections
        $self->print_dumptypes($fh, $cfg->{'config'}{'dumptypes'});

        # print interface sections
        $self->print_interfaces($fh, $cfg->{'config'}{'interfaces'});

        my %tape_pars=('tpchanger'=>$tpchanger,'tapecycle'=>$tapecycle,'tapedev'=>$tapedev,'tapelist'=>$tapelist);

        return \%tape_pars;

}

# Function that creates the virtual tapes when needed
sub create_virtual_tapes($$$$) {

	my ($self, $backup, $tapecycle, $tapedev, $tapelist) = @_;
    # Extract the tape path from the $tapedev parameter

    $tapedev =~ m/^file:(.*)$/;
    my $i = 1;
    $tapedev = $1;    
    # If tapedev does not exists we create it
    unless (-d $1) {
    	$self->info(print "Tapedev does not exist, create tapedev, slots and symbolic link data to first slot\n");
    	makedir($tapedev);
    	# Change owner
    	chown($uid, $gid, $tapedev);
		# Create as many slots dir as specified in tapecycle
		while ($i<=$tapecycle) {
			makedir("$tapedev/slot$i");
			chown($uid, $gid, "$tapedev/slot$i");			
			$i++;
		}
		# Create a simbolic link called 'data' to the first slot
		symlink("$tapedev/slot1","$tapedev/data");
		chown($uid, $gid, "$tapedev/data");      
	}

	my $proc;

	# If a tapelist does not exist create it
	unless (-e $tapelist) { 
		$self->info(print "Tapelist does not exist, create tapelist, label tapes and change slot\n");
		# Create an empty tapelist file

		my $fh = CAF::FileWriter->new ($tapelist, ("owner"=>$uid,"group"=>$gid));
		$fh->close();
		
		chown($uid, $gid, $tapelist);	

		$i = 1;
		my @cmd;
		while ($i<=$tapecycle) {
                        $proc = CAF::Process->new (["/bin/su", AMANDA_USER, "-c", "/usr/sbin/amlabel $backup $backup$i slot $i"]);
                        $proc->run();
			$i++;
		}
	
		# Reset the changer to the first slot
                $proc = CAF::Process->new (["/bin/su", AMANDA_USER, "-c", "/usr/sbin/amtape $backup reset"]);
                $proc->run();

	}
}

# Returns the interesting information from a user. Wrapper for Perl's
# getpwnam.
#
# Arguments: $_[1]: the user name.
sub getpwnam
{
        my ($self,$user) = @_;
        my @val = getpwnam ($user);
        if (@val) {
                return @val[UID, GID, HOMEDIR];
        } else {
                $self->error ("Couldn't get system data for $user");
                return undef;
        }
}

##########################################################################
sub Configure($$) {
##########################################################################
    my ($self,$config)=@_;

	# get system info for AMANDA_USER
	($uid, $gid, $home) = $self->getpwnam (AMANDA_USER);
	
    my $t = $config->getElement (PATH)->getTree;

    my ($fha,$fhb);
    my $bks = $t->{'backups'};
    # For each backup specified write a config and a disklist file
    while (my ($k, $v) = each (%$bks)) {
        my $backup = $k;
    	# Create a dir under AMANDA_CONFIG_DIR
    	my $backup_dir = AMANDA_CONFIG_DIR . "/" . $backup;
		makedir($backup_dir,0755);

       	# Cambiar owner del dir de backup
       	chown($uid, $gid, $backup_dir);

        $fha = CAF::FileWriter->new ($backup_dir . "/amanda.conf", ("owner"=>$uid,"group"=>$gid));
        my $tape_pars = $self->print_conf_file($fha,$v, $backup);
        my $tpchanger = $tape_pars->{'tpchanger'};
        my $tapecycle = $tape_pars->{'tapecycle'};
        my $tapedev = $tape_pars->{'tapedev'};
        my $tapelist = $tape_pars->{'tapelist'};

        $fhb = CAF::FileWriter->new ($backup_dir . "/disklist", ("owner"=>$uid,"group"=>$gid));
        foreach my $dl (@{$v->{'disklist'}}) {
                print $fhb "$dl->{'hostname'} $dl->{'diskname'} $dl->{'dumptype'}\n";
        }
    	$fha->close;
    	$fhb->close;
    	
        # If tpchanger is 'chg-disk we need to create the virtual tapes
        if ($tpchanger eq 'chg-disk') {
                $self->create_virtual_tapes($backup, $tapecycle, $tapedev, $tapelist);
        }

    }
    
    # Create AMANDA_HOSTS_FILE file
    my $fhc = CAF::FileWriter->new ("$home/" . AMANDA_HOSTS_FILE, ("owner"=>$uid,"group"=>$gid));
    foreach my $ah (@{$t->{'amandahosts'}}) {
    	print $fhc "$ah->{'domain'} $ah->{'user'}\n";
    }
    $fhc->close;
    return; # return code is not checked.
}

1; # Perl module requirement.
