# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

package NCM::Component::fmonagent;

#
# a few standard statements, mandatory for all components
#

use strict;
use diagnostics;
use LC::Check;
use NCM::Check;
use NCM::Component;
use vars qw(@ISA $EC);

use File::Basename;
use Storable;
use Digest::MD5 qw(md5_hex);

sub MD5sum($);
sub InfoConfig($);

@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

my $cfgfile = "/etc/edg-fmon-agent.conf";
my $init_file = "/etc/rc.d/init.d/lemon-agent";
my $service = "lemon-agent";
my $cfgdir  = dirname $cfgfile;
my $modified = 0;
my $split_config = 0;
my @sensor_files = ();
my %active_sensors = ();
my %metric_id_map = ();
my @def_sensors = ();
my $offset = "\t\t";
undef my $self;
my $e;
my $class_name;
my $key;
my $val;
my $active;
my $name;
my $actuator_active;
my $execve;
my $maxrun;
my $window;
my $timeout;
my @param;
my $period;
my $id;
my $offset_time;
my $s_file;
my $status;
my %filtered;
my %group_sensors;


##########################################################################
sub Configure {
##########################################################################
	($self,my $mon)=@_;        

	#
	# can we find monitoring information in CDB?
	#
	
	my $toplevel = "/software/components/lemon";
	if (not $mon->elementExists($toplevel)) {
		if (not $mon->elementExists("/system/monitoring")) {
			$self->error("Nothing found in \"$toplevel\"");
			return;
		} 
		$toplevel = "/system/monitoring";
	}
	
	# figure out what is the config file/directory
	if ($mon->elementExists($toplevel."/general/configfile")) {
		$cfgfile = $mon->getValue($toplevel."/general/configfile");
	}

	#
	# Change the default in the init.d script for config file...
	#
	InitConfig();
	
	#
	# is monitoring installed?
	#
	if ( ! -e $init_file ) {
		$self->error("Monitoring agent not installed. Aborting.");
		return;
	}
	
	my $default_cfg   = "$cfgfile/general.conf";
	my $transport_cfg = "$cfgfile/transport/udp.conf";
	my $sensor_cfg    = "$cfgfile/sensors";
	my $metric_cfg    = "$cfgfile/metrics";

	# are we using split file config?
	if (-d $cfgfile) {
		$self->info("Mode: modular configuration style: $cfgfile");
		$split_config = 1;
		$offset = "";
		if (not CORE::open(CFG,">$default_cfg.tmp")) {
			$self->error("Cannot open \"$default_cfg.tmp\": $!");
			return -1;
		}
		$self->debug(1, "Using default global file $default_cfg");
		
		# remove the old config file by default in this case
		# just the transition step...
		if (-e "/etc/edg-fmon-agent.conf") {
			unlink("/etc/edg-fmon-agent.conf");
		}
		
		# delete all _CDB files...
		remove_old_files();
		
	} else {
		$self->info("Mode: monolithic configuration style");
		if (not CORE::open(CFG,">$cfgfile.tmp")) {
			$self->error("Cannot open \"$cfgfile.tmp\": $!");
			return -1;
		}
	}
		
	# remove the metric.dat file used by the SURE sensor
	if (-e "$cfgdir/metric.dat") {
		unlink("$cfgdir/metric.dat");
	}
	
	#
	# print header
	#	
	if ($mon->elementExists("$toplevel/general/identifier")) {
		print CFG "MSA\t".$mon->getValue("$toplevel/general/identifier")."\n";
	} else {
		print CFG "MSA\n";
	}
	
	#
	# general section
	#
	my $general    = "$toplevel/general";
	my $logfile    = $mon->getValue("$toplevel/general/logfile");
	my $cachedir   = $mon->getValue("$toplevel/general/cachedir");
	my $resetmmaps = $mon->getValue("$toplevel/general/resetmmaps") || "false";

	print CFG "\tGeneral\n";
	print CFG "\t\tLogFile $logfile\n";
	print CFG "\t\tLocalCache\n";
	print CFG "\t\t\tPath\t$cachedir\n";
	print CFG "\t\tSampleOnDemand\n";

	if ($mon->elementExists("$toplevel/general/sodpipe")) {
		print CFG "\t\t\tPipePath\t".$mon->getValue("$toplevel/general/sodpipe")."\n";
	} 
	if ($mon->elementExists("$toplevel/general/maxsamplelength")) {
		print CFG "\t\tMaxSampleLength\t".$mon->getValue("$toplevel/general/maxsamplelength")."\n";
	}
	if ($mon->elementExists("$toplevel/general/shorthostname")) {
		if ($mon->getValue("$toplevel/general/shorthostname") eq "true") {
			print CFG "\t\tShortHostname\tyes\n";
		} else {
			print CFG "\t\tShortHostname\tno\n";
		}
	}
	if ($mon->elementExists("$toplevel/general/resetmmaps")) {
		print CFG "\t\tResetMetricsMap\tyes\n" if $mon->getValue("$toplevel/general/resetmmaps") eq "true";
	}
	if ($mon->elementExists("$toplevel/general/privatekeyfile")) {
		print CFG "\t\tPrivateKeyFile\t".$mon->getValue("$toplevel/general/privatekeyfile")."\n";
	}
	if ($mon->elementExists("$toplevel/general/digesttype")) {
		print CFG "\t\tDigestType\t".$mon->getValue("$toplevel/general/digesttype")."\n";
	}
	if ($mon->elementExists("$toplevel/general/statepath")) {
		print CFG "\t\tException\n";
		print CFG "\t\t\tStatePath\t".$mon->getValue("$toplevel/general/statepath")."\n";
	}		
	if ($mon->elementExists("$toplevel/general/user")) {
		print CFG "\t\tUser\t".$mon->getValue("$toplevel/general/user")."\n";
	}
	if ($mon->elementExists("$toplevel/general/sensoruser")) {
		print CFG "\t\tDefaultSensorUser\t".$mon->getValue("$toplevel/general/sensoruser")."\n";
	}

	#
	# Group sensors
	#
	my $grpsensor = "$toplevel/group";
	if ($mon->elementExists("$grpsensor") && ($split_config)) {
		my $se = $mon->getElement($grpsensor);
		while ($se->hasNextElement()) {
			$name = $se->getNextElement()->getName();
			$name =~ s/^\s+//;
			my $cmdline = $mon->getValue("$grpsensor/$name/cmdline");
	
			# this should never happen as a cmdline is mandatory in CDB!
			if (!$cmdline) {
				next;
			}
			$group_sensors{$name}{"cmdline"} = $cmdline;
		}
	}

	#
	# sensors section
	#
	my $sensor = "$toplevel/sensor";
	my $se = $mon->getElement($sensor);
	if (!$split_config) {
		print CFG "\tSensors\n";
	}
	my %sensor = (); 
	my %class_fields = ();
	
	while ($se->hasNextElement()) {
		$name = $se->getNextElement()->getName();
		$name =~ s/^\s+//;
		my $cmdline = $mon->getValue("$sensor/$name/cmdline");
		push(@def_sensors,$name);	
		
		if ( $split_config ) {
			if ($cmdline eq "" and $name ne "MSA") { next; };
			close(CFG);
			
			my $tmp_fname = "$sensor_cfg/$name"."_CDB.conf";
			if (not CORE::open(CFG,">$tmp_fname.tmp")) {
				$self->error("Cannot open \"$tmp_fname.tmp\": $!");
				return -1;
			}
		}
	
		# is this sensor definition part of a group ?
		if ($mon->elementExists("$sensor/$name/group_name") && ($split_config)) {
			my $group  = $mon->getValue("$sensor/$name/group_name");

			if (!$mon->elementExists("$sensor/$name/module_names")) {
				$self->error("Missing module_name element for sensor $name");
				return -1;
			}
			my $module = $mon->getValue("$sensor/$name/module_names");

			if (!exists($group_sensors{$group})) {
				$self->error("Failed to associate sensor module '$name' with sensor group '$group'");
				return -1;
			}

			if (!$module) {
				$self->error("Module name missing for sensor '$name'");
				return -1;
			}

			# record the module name
			my $found = 0;
			foreach my $tmp (@{ $group_sensors{$group}{"modules"} }) {
				if ($tmp eq $module) {
					$found = 1;
					last;
				}
			}
			if ($found) {
				next;
			}
			push(@{ $group_sensors{$group}{"modules"} }, $module);
	
			# record the classes exposed by the module
			my $cnt = 0;	
			while ($mon->elementExists("$sensor/$name/class/$cnt")) {
				my $class_name = $mon->getValue("$sensor/$name/class/$cnt/name");
				$class_name =~ s/^\s+//;
	
				$cnt++;
				$group_sensors{$group}{"classes"}{$class_name} = 1;
				$sensor{$class_name} = $group;
			}
					
			next;
		}

		if ($cmdline ne "") {
			print CFG "$offset$name\n";
			print CFG "$offset\tCommandLine\t$cmdline\n";
		}elsif ($name eq "MSA") { # special case for the internal MSA sensors
			print CFG "$offset$name\n";
		} else {   
			next;
		}
		if ($mon->elementExists("$sensor/$name/env")) {
			print CFG "$offset\tEnv\n";
			my $env = $mon->getElement("$sensor/$name/env");
			while ($env->hasNextElement()) {
				$e = $env->getNextElement();
				$key = $e->getName();
				$key =~ s/^\s+//;
				$val = $e->getValue();
				print CFG "$offset\t\t$key\t$val\n";
			}
		}
		
		if ($mon->elementExists("$sensor/$name/supports")) {
			my $supports = $mon->getValue("$sensor/$name/supports");
			print CFG "$offset\tSupports\t$supports\n";
		}

		if ($mon->elementExists("$sensor/$name/user")) {
			my $user = $mon->getValue("$sensor/$name/user");
			print CFG "$offset\tUser\t$user\n";
		}
		
		print CFG "$offset\tMetricClasses\n";
		my $cnt = 0;
		my @class = ();
		
		while ($mon->elementExists("$sensor/$name/class/$cnt")) {
			my $class_n = $mon->getValue("$sensor/$name/class/$cnt/name");
			$class_n =~ s/^\s+//;
			push(@class,$class_n);
			$cnt++;
			$sensor{$class_n} = $name;
		}
		map {print CFG "$offset\t\t$_\n"} sort @class;
	}
	
	# print the group sensors
	if ($split_config) {
		foreach my $group (sort keys %group_sensors) {
			if (!exists($group_sensors{$group}{"modules"})) {
				next;    # no modules using this group
			}

			# expand the command line
			my $mods = join(" ", @{ $group_sensors{$group}{"modules"} });
			my $cmdline = $group_sensors{$group}{"cmdline"};
			$cmdline =~ s/\$modules/$mods/g;
			
			# write the file	
			close(CFG);
			
			my $tmp_fname = "$sensor_cfg/$group"."_CDB.conf";
			if (not CORE::open(CFG,">$tmp_fname.tmp")) {
				$self->error("Cannot open \"$tmp_fname.tmp\": $!");
				return -1;
			}

			print CFG "$group\n";
			print CFG "\tCommandLine\t$cmdline\n";

			if ($mon->elementExists("$grpsensor/$group/supports")) {
				my $supports = $mon->getValue("$grpsensor/$group/supports");
				print CFG "\tSupports\t$supports\n";
			}

			if ($mon->elementExists("$grpsensor/$group/env")) {
				print CFG "\tEnv\n";
				my $env = $mon->getElement("$grpsensor/$group/env");
				while ($env->hasNextElement()) {
					$e = $env->getNextElement();
					$key = $e->getName();
					$key =~ s/^\s+//;
					$val = $e->getValue();
					print CFG "\t\t$key\t$val\n";
				}
			}	

			print CFG "\tMetricClasses\n";

			foreach my $class (sort keys %{ $group_sensors{$group}{"classes"} }) {
				print CFG "\t\t$class\n";
			}		
		}
	}

	#
	# metrics section
	#
	my $metric = "$toplevel/metric";
	my $re = $mon->getElement($metric);
	if (!$split_config) {
		print CFG "\tMetrics\n";
	}
	my %sample = my %metrics = my %sure = ();
	while ($re->hasNextElement()) {
		$id = $re->getNextElement()->getName();
		$id =~ s/^_//;
		$active = $mon->getValue("$metric/_$id/active");
		next if $active ne "true";
		$name = $mon->getValue("$metric/_$id/name");
		$class_name = $mon->getValue("$metric/_$id/class");
		
		# mapping metric id to sensor
		$metric_id_map{$id} = $sensor{$class_name};
		$metrics{$id}  = "$offset$id\n";
		$metrics{$id} .= "$offset\tMetricName\t$name\n";
		$metrics{$id} .= "$offset\tMetricClass\t$class_name\n";
		if ($split_config) {
			my $m_period = $mon->getValue("$metric/_$id/period");
			my $m_offset = 0;
			my $m_reftime = 0;
			if ($mon->elementExists("$metric/_$id/offset")) {
				$m_offset = $mon->getValue("$metric/_$id/offset");
			}
			$metrics{$id} .= "$offset\tTiming\t$m_period\t$m_offset\n";
			if ($mon->elementExists("$metric/_$id/reftime")) {
				$m_reftime = $mon->getValue("$metric/_$id/reftime");
				$metrics{$id} .= "$offset\tReferenceTime\t$m_reftime\n";
			}

		}

		# parameters
		my $correct = 1;
		if ($mon->elementExists("$metric/_$id/param")) {
			$e = $mon->getElement("$metric/_$id/param");
			@param = $e->getList();
			$metrics{$id} .= "$offset\tParameters\n";
			while(@param) {
				($key,$val) = splice(@param,0,2);
				$key = $key->getValue();
				$key =~ s/^\s+//;
				$val = $val->getValue();

				# replace symlink('X') with symlink("X")
				$val =~ s/symlink\(\'(.*?)\'\)/symlink\(\"$1\"\)/g;
			
				# resolve symlinks
				while ($val =~ /symlink\(\"(.*?)\"\)/g) {
					my $symlink = $1;
					if (!$mon->elementExists($symlink)) {
						$self->warn("Failed to resolve symlink '$symlink' for parameter $key in metric $id.");
						$correct = 0;
						last;
					}
					my $resolved_value = $mon->getValue($symlink);
					$val =~ s/symlink\(\"$symlink\"\)/$resolved_value/;
				}					
				
				$metrics{$id} .= "$offset\t\t$key\t$val\n";
			}
		}

		# if the parameter symlink expansion failed, disable the metric
		if ($correct == 0) {
			$metrics{$id} .= "$offset\tEnable\tno\n";
		}

		# smoothing
		if (($mon->elementExists("$metric/_$id/smooth") && ($mon->getValue("$metric/_$id/period")) != 0)) {
			$e = $mon->getElement("$metric/_$id/smooth");
			my $Type = ($mon->getValue("$metric/_$id/smooth/typeString") eq "true" ? "string" : "number");
			$metrics{$id} .= "$offset\tSmoothing\n";
			if ($mon->elementExists("$metric/_$id/smooth/index")) {
				$metrics{$id} .= "$offset\t\tIndex\t".$mon->getValue("$metric/_$id/smooth/index")."\n";
			} else {
				$metrics{$id} .= "$offset\t\tIndex\t0\n"; 
			}
			$metrics{$id} .= "$offset\t\tType\t$Type\n";
			$metrics{$id} .= "$offset\t\tCacheAll\t1\n";
			if ($mon->elementExists("$metric/_$id/smooth/maxdiff")) {
				$metrics{$id} .= "$offset\t\tMaxdiff\t".$mon->getValue("$metric/_$id/smooth/maxdiff")."\n";
			}
			if ($mon->elementExists("$metric/_$id/smooth/maxtime")) {

				# prevent the maxtime being greater the the cache expiry
				my $maxtime       = $mon->getValue("$metric/_$id/smooth/maxtime");
				my $maxtime_upper = 0;
				if ($mon->elementExists("$metric/_10001/param/0")) {
					if ($mon->getValue("$metric/_10001/param/0") eq "expiry") {
						$maxtime_upper = ($mon->getValue("$metric/_10001/param/1") - 1) * 86400;
					}
				}
				if (($maxtime_upper != 0) && ($maxtime > $maxtime_upper)) {
					$maxtime = $maxtime_upper;
				}
				$metrics{$id} .= "$offset\t\tMaxtime\t".$maxtime."\n";
			}
			if ($mon->elementExists("$metric/_$id/smooth/cacheall")) {
				$metrics{$id} .= "$offset\t\tCacheAll\t".$mon->getValue("$metric/_$id/smooth/")."\n";
			}
			if ($mon->elementExists("$metric/_$id/smooth/onvalue")) {
				$metrics{$id} .= "$offset\t\tOnValue\t".$mon->getValue("$metric/_$id/smooth/onvalue")."\n";
			}
			if ($mon->elementExists("$metric/_$id/smooth/primarykeys")) {
				$metrics{$id} .= "$offset\t\tPrimaryKeys\t".$mon->getValue("$metric/_$id/smooth/primarykeys")."\n";
			}
		}
		#
		# group the metrics per sampling interval
		#
		$period = $mon->getValue("$metric/_$id/period");
		my $offset_m = 0;
		if ($mon->elementExists("$metric/_$id/offset")) {
			$offset_m = $mon->getValue("$metric/_$id/offset");
		}
		$key = sprintf("%8d $offset_m",$period);
		if ($mon->elementExists("$metric/_$id/reftime")) {
			$key .= $mon->getValue("$metric/_$id/reftime");
		}
		push(@{$sample{$key}},$id);

		# local metric ?
		if ($mon->elementExists("$metric/_$id/local")) {
			if ($mon->getValue("$metric/_$id/local") eq "true") {
				$metrics{$id} .= "$offset\t\tLocal\tyes\n";
				$filtered{$id} = 1;
			}
		}
	}
	
	#
	# exceptions section
	#
	my $exception = "$toplevel/exception";
	if ($mon->elementExists("$exception")) {
		$re = $mon->getElement($exception);
		$class_name = "alarm.exception";

		my %exception_errs;

		while ($re->hasNextElement()) {
			$id = $re->getNextElement()->getName();
			$id =~ s/^_//;
			$active = $mon->getValue("$exception/_$id/active");
			next if $active ne "true";
			$name = $mon->getValue("$exception/_$id/name");
			$period = 0;
			my $period_offset = 30;
			
			# period and offset
			if ($mon->elementExists("$exception/_$id/period")) {
				$period = $mon->getValue("$exception/_$id/period");
			}
			
			if ($mon->elementExists("$exception/_$id/offset")) {
				$period_offset = $mon->getValue("$exception/_$id/offset");
			}
	
			# using new exception style
			# check if we have correlation element
			my $correlation = "";
			if ($mon->elementExists("$exception/_$id/correlation")) {
				$correlation = $mon->getValue("$exception/_$id/correlation");
			} else {
				$self->warn("Correlation element for exception $id is not defined.");
				next;
			}
				
			my $symlink     = "";
			my $value       = "";
			my $pos         = 0;
			my $str_pos     = 0;
			my $correct     = 1;
			my $high_freq   = 864000;
			my $tmp         = undef;

			# remove the on-behalf component of the correlation
			#   - lxb0001:10002:1 != 10003:3   becomes  10003:2 != 10003:3
			#   - all we are interested in is that the metrics involved in the correlation are configured
			#     not that they same a particular machine or collection of machines
			$tmp = $correlation;
			$tmp =~ s/.*:(\d+):([+-]?\d+)/$1:$2/g;
				
			while(index($tmp,":",$pos) >= 0) {
				$str_pos = index($tmp,":",$pos);
				my $content = substr($tmp,$pos,$str_pos - $pos+1);
				my($ref_metric) = $content =~ m/(\w+)\:/;		
				my $path = $metric;

				# exception or metric ?
				if ($mon->elementExists("$metric/_$ref_metric")) {
					$path = $metric;
				} elsif ($mon->elementExists("$exception/_$ref_metric")) {
					$path = $exception;
				} 

				if(!$mon->elementExists("$path/_$ref_metric")){
					$correct = 0;
					$exception_errs{$id}{"reason"}    = "missing";
					$exception_errs{$id}{"refmetric"} = $ref_metric;
				} elsif ($mon->getValue("$path/_$ref_metric/active") ne "true") {
					$correct = 0;
					$exception_errs{$id}{"reason"}    = "disabled";
					$exception_errs{$id}{"refmetric"} = $ref_metric;		
				} else {
					if ($mon->elementExists("$path/_$ref_metric/period")) {
						my $per = $mon->getValue("$path/_$ref_metric/period");
						if ($per < $high_freq) { 
							$high_freq = $per; 
						}
					}
					if ($mon->elementExists("$path/_$ref_metric/offset")) {
						my $off = $mon->getValue("$path/_$ref_metric/offset");
						if ($off >= $period_offset) { 
							$period_offset = ($off + 30); 
						}
					}
				}
				
				$pos = $str_pos + 1;
			}
			if ($correct eq 0) { 
				next; 
			}
				
			# replace symlink('X') with symlink("X")
			$correlation =~ s/symlink\(\'(.*?)\'\)/symlink\(\"$1\"\)/g;
				
			# resolve symlinks
			$correct = 1;
			while ($correlation =~ /symlink\(\"(.*?)\"\)/g) {
				$symlink = $1;
				if (!$mon->elementExists($symlink)) {
					$self->warn("Failed to resolve symlink '$symlink' in exception $id.");
					$correct = 0;
					last;
				}
				$value = $mon->getValue($symlink);
				$correlation =~ s/symlink\(\"$symlink\"\)/$value/;
			}
			if ($correct eq 0) {
				next;
			}
			
			if ($period eq 0) {
				$period = $high_freq;
			}					
			
			# define metric now
			# mapping metric id to sensor
			$metric_id_map{$id} = $sensor{$class_name};
			
			$metrics{$id}  = "$offset$id\n";
			$metrics{$id} .= "$offset\tMetricName\texception.$name\n";
			$metrics{$id} .= "$offset\tMetricClass\t$class_name\n";
			$metrics{$id} .= "$offset\tParameters\n";
			$metrics{$id} .= "$offset\t\tCorrelation\t$correlation\n";
			
			# check for localised alarm
			if ($mon->elementExists("$exception/_$id/local")) {
				if ($mon->getValue("$exception/_$id/local") eq "true") {
					$metrics{$id} .= "$offset\t\tLocal\tyes\n";
					$filtered{$id} = 1;
				}
			}

			# check for silent alarm
			if ($mon->elementExists("$exception/_$id/silent")) {
				if ($mon->getValue("$exception/_$id/silent") eq "true") {
					$metrics{$id} .= "$offset\t\tSilent\tyes\n";
				}
			}

			# check for minimum occurences
			if ($mon->elementExists("$exception/_$id/minoccurs")) {
				$metrics{$id} .= "$offset\t\tMinOccurs\t".$mon->getValue("$exception/_$id/minoccurs")."\n";
			}
			
			# now actuator
			if ($mon->elementExists("$exception/_$id/actuator")) {
				$actuator_active = $mon->getValue("$exception/_$id/actuator/active") || "false";
				if ($actuator_active eq "true") {
					$execve = $mon->getValue("$exception/_$id/actuator/execve");

					# resolve any symlinks
					my $symlink = "";
					my $correct = 1;
					my $value   = "";

					# replace symlink('X') with symlink("X")
					$execve =~ s/symlink\(\'(.*?)\'\)/symlink\(\"$1\"\)/g;

					while ($execve =~ /symlink\(\"(.*?)\"\)/g) {
						$symlink = $1;
						if (!$mon->elementExists($symlink)) {
							$self->warn("Failed to resolve symlink '$symlink' in exception $id for actuator.");
							$correct = 0;
							last;
						}
						$value = $mon->getValue($symlink);
						$execve =~ s/symlink\(\"$symlink\"\)/$value/;
					}
					if ($correct ne 0) {
						$metrics{$id} .= "$offset\t\tActuator\t$execve\n";
						
						$maxrun = $mon->getValue("$exception/_$id/actuator/maxruns");
						$window = 0;
						if ($mon->elementExists("$exception/_$id/actuator/window")) {
							$window = $mon->getValue("$exception/_$id/actuator/window");
						}	
						$metrics{$id} .= "$offset\t\tMaxRuns\t$maxrun\t$window\n";
					
						$timeout = $mon->getValue("$exception/_$id/actuator/timeout");
						$metrics{$id} .= "$offset\t\tTimeout\t$timeout\n";
						if ($mon->elementExists("$exception/_$id/actuator/resampleoffset")) {
							my $resampleoffset = $mon->getValue("$exception/_$id/actuator/resampleoffset");
							$metrics{$id} .= "$offset\t\tReSampleOffset\t$resampleoffset\n";
						}	
					}
				}
			}
			
			if ($split_config) {
				$metrics{$id} .= "$offset\tTiming\t$period\t$period_offset\n";
			}
			
			# if the period is 0 smoothing is pointless!
			if ($period != 0) {

				# if smoothing not defined, use default
				if (!$mon->elementExists("$exception/_$id/smooth")) {
					$metrics{$id} .= "$offset\tSmoothing\n";
					$metrics{$id} .= "$offset\t\tIndex\t0\n";
					$metrics{$id} .= "$offset\t\tType\tstring\n";
					$metrics{$id} .= "$offset\t\tCacheAll\t1\n";
					$metrics{$id} .= "$offset\t\tOnValue\t0 000 (null)\n";
					$metrics{$id} .= "$offset\t\tMaxtime\t3600\n";
				} else {
					$e = $mon->getElement("$exception/_$id/smooth");
					my $Type = ($mon->getValue("$exception/_$id/smooth/typeString") eq "true" ? "string" : "number");
					$metrics{$id} .= "$offset\tSmoothing\n";
					$metrics{$id} .= "$offset\t\tIndex\t0\n";
					$metrics{$id} .= "$offset\t\tType\t$Type\n";
					$metrics{$id} .= "$offset\t\tCacheAll\t1\n";
					if ($mon->elementExists("$exception/_$id/smooth/maxdiff")) {
						$metrics{$id} .= "$offset\t\tMaxdiff\t".$mon->getValue("$exception/_$id/smooth/maxdiff")."\n";
					}
					if ($mon->elementExists("$exception/_$id/smooth/maxtime")) {
						
						# prevent the maxtime being greater the the cache expiry
						my $maxtime       = $mon->getValue("$exception/_$id/smooth/maxtime");
						my $maxtime_upper = 0;
						if ($mon->elementExists("$metric/_10001/param/0")) {
							if ($mon->getValue("$metric/_10001/param/0") eq "expiry") {
								$maxtime_upper = ($mon->getValue("$metric/_10001/param/1") - 1) * 86400;
							}
						}
						if (($maxtime_upper != 0) && ($maxtime > $maxtime_upper)) {
							$maxtime = $maxtime_upper;
						}
						$metrics{$id} .= "$offset\t\tMaxtime\t".$maxtime."\n";
					}
					if ($mon->elementExists("$exception/_$id/smooth/cacheall")) {
						$metrics{$id} .= "$offset\t\tCacheAll\t".$mon->getValue("$exception/_$id/smooth/")."\n";
					}
					if ($mon->elementExists("$exception/_$id/smooth/onvalue")) {
						$metrics{$id} .= "$offset\t\tOnValue\t".$mon->getValue("$exception/_$id/smooth/onvalue")."\n";
					}
					if ($mon->elementExists("$exception/_$id/smooth/primarykeys")) {
       	                                	$metrics{$id} .= "$offset\t\tPrimaryKeys\t".$mon->getValue("$exception/_$id/smooth/primarykeys")."\n";
					}
				}
			}
			
			# SURE phaseout
                        if ($mon->elementExists("$exception/_$id/alarmtext")) {
				$metrics{$id} .= "$offset\tSure\n";
				$metrics{$id} .= "$offset\t\tAlarmtext\t".$mon->getValue("$exception/_$id/alarmtext")."\n";
				if ($mon->elementExists("$exception/_$id/descr")) {
					$metrics{$id} .= "$offset\t\tDesc\t".$mon->getValue("$exception/_$id/descr")."\n";
				}
			}
			
			#
			# group the metrics per sampling interval
			#
			$key = sprintf("%8d $period_offset",$period);
			if ($mon->elementExists("$exception/_$id/reftime")) {
				$key .= $mon->getValue("$exception/_$id/reftime");
			}
			push(@{$sample{$key}},$id);
		}

		# any warning messages
		if (scalar(keys %exception_errs)) {
			$self->info("The following exceptions could not be configured:");
		}	

		foreach my $id (sort keys %exception_errs) {
			if ($exception_errs{$id}{"reason"} eq "missing") {
				$self->warn("   $id - metric $exception_errs{$id}{'refmetric'} is not defined");
			} else {
				$self->warn("   $id - metric $exception_errs{$id}{'refmetric'} is disabled");
			}
		}
	}
	
	# open file for writing - header
	if ($split_config) {
		close(CFG);
		if (not CORE::open(CFG,">$transport_cfg.tmp")) {
			$self->error("Cannot open \"$transport_cfg.tmp\": $!");
			return -1;
		}
		$self->debug(1, "Using transport file $transport_cfg");
	}

	#
	# transport section
	#
	my $transport = "$toplevel/transport";
	$re = $mon->getElement($transport);
	if (!$split_config) {
		print CFG "\tTransport\n";
	}
	while ($re->hasNextElement()) {
		$name = $re->getNextElement()->getName();
		print CFG "$offset".$mon->getValue("$transport/$name/proto")."\n";
		print CFG "$offset\tServer\t".$mon->getValue("$transport/$name/server")."\n";
		print CFG "$offset\tPort\t".$mon->getValue("$transport/$name/port")."\n";
		if ($mon->elementExists("$transport/$name/nowarnings")) {
			print CFG "$offset\tNoWarnings\n" if $mon->getValue("$transport/$name/nowarnings") eq "true";
		}
		if ($mon->elementExists("$transport/$name/useauth")) {
			print CFG "$offset\tUseAuth\tyes\n" if $mon->getValue("$transport/$name/useauth") eq "true";
		}
		if ($mon->elementExists("$transport/$name/MaxCacheBytes")) {
			print CFG "$offset\tMaxCacheBytes\t".$mon->getValue("$transport/$name/MaxCacheBytes")."\n";
		}
		if ($mon->elementExists("$transport/$name/MaxCacheItems")) {
			print CFG "$offset\tMaxCacheItems\t".$mon->getValue("$transport/$name/MaxCacheItems")."\n";
		}
		if (scalar(keys %filtered)) {
			print CFG "$offset\tFilterMetrics Reject\n";
			foreach my $mid (sort keys %filtered) {
				print CFG "$offset\t\t$mid\n";
			}
		}
	}
	
	# write metric definition file(s)
	@sensor_files = ();
	if (!$split_config) {        
		map {print CFG $metrics{$_}} sort {$a <=> $b} keys %metrics;
	} else {
		# get list of active sensors
		my $err_msg = 0;
		for (keys %metric_id_map) {
			if (!defined($_) || !exists($metric_id_map{$_}) || !$metric_id_map{$_}) {
				if (!$err_msg) {
					$self->warn("The following metric classes could not be found:");
					$err_msg = 1;
				}
				$class_name = $mon->getValue("$metric/_$_/class");
				$self->warn("   $class_name - $_");
				next;
			}
			if (!exists($active_sensors{$metric_id_map{$_}} )) {
				$active_sensors{$metric_id_map{$_}} = '';
				push(@sensor_files,"$sensor_cfg/$metric_id_map{$_}_CDB.conf");
			}
		}
		
		my @output = sort keys %active_sensors;
		$self->info("Active sensors: @output");

		# remove not active ones and default installed ones
		for (keys %active_sensors) {
			if ( -e "$metric_cfg/$_.conf" ) {
				CORE::unlink "$metric_cfg/$_.conf";
			}
			if ( -e "$sensor_cfg/$_.conf" ) {
				CORE::unlink "$sensor_cfg/$_.conf";
			}
		}

		# remove sensors and metrics which are obsolete
		#   - these sensors and metrics must have been previously generated with a _CDB prefix
		#
		opendir(DIR, "$sensor_cfg") || die "can't opendir $sensor_cfg: $!";
		while (my $name = readdir(DIR)) {
			if ($name =~ m/(\w+)_CDB.conf/) {
				if (!exists($active_sensors{$1})) {
					CORE::unlink "$sensor_cfg/$1"."_CDB.conf";
				}
			}
		}
		closedir DIR;
	
		opendir(DIR, "$metric_cfg") || die "can't opendir $metric_cfg: $!";
		while (my $name = readdir(DIR)) {
			if ($name =~ m/(\w+)_CDB.conf/) {
				if (!exists($active_sensors{$1})) {
					CORE::unlink "$metric_cfg/$1"."_CDB.conf";
				}
			}
		}
		closedir DIR;

		foreach my $s_name (@def_sensors) {
			if ( ! exists($active_sensors{$s_name} )) {
				my $tmp_name = "$sensor_cfg/$s_name"."_CDB.conf.tmp";
				if ( -e "$tmp_name") {
					$self->debug(1, "Removing sensor config file: $tmp_name");
					CORE::unlink "$tmp_name";
				}
				$tmp_name = "$sensor_cfg/$s_name"."_CDB.conf";
				if ( -e "$tmp_name") {
					$self->debug(1, "Removing sensor config file: $tmp_name");
					CORE::unlink "$tmp_name";
				}
				$tmp_name = "$sensor_cfg/$s_name".".conf";
				if ( -e "$tmp_name") {
					$self->debug(1, "Removing sensor config file: $tmp_name");
					CORE::unlink "$tmp_name";
				}
				$tmp_name = "$metric_cfg/$s_name"."_CDB.conf.tmp";
				if ( -e "$tmp_name") {
					$self->debug(1, "Removing metric config file: $tmp_name");
					CORE::unlink "$tmp_name";
				}
				$tmp_name = "$metric_cfg/$s_name"."_CDB.conf";
				if ( -e "$tmp_name") {
					$self->debug(1, "Removing metric config file: $tmp_name");
					CORE::unlink "$tmp_name";
				}
				$tmp_name = "$metric_cfg/$s_name".".conf";
				if ( -e "$tmp_name") {
					$self->debug(1, "Removing metric config file: $tmp_name");
					CORE::unlink "$tmp_name";
				}
			} else {
				my $tmp_name = "$metric_cfg/$s_name"."_CDB.conf";
				$self->debug(1, "Using sensor file $tmp_name");
			}
		}		
		
		# now write individual metric files
		for (keys %active_sensors) {
			
			# close previous file
			close(CFG);
			# open file
			my $tmp_sensor = $_;
			my $tmp_metric_file =  "$metric_cfg/$tmp_sensor"."_CDB.conf";
			if (not CORE::open(CFG,">$tmp_metric_file.tmp")) {
				$self->error("Cannot open \"$tmp_metric_file.tmp\": $!");
				return -1;
			}
			$self->debug(1, "Using metric file $tmp_metric_file");
			push(@sensor_files,"$tmp_metric_file");
			
			# write metrics into the file
			for (sort {$a <=> $b} keys %metrics) {
				my $mx = $_;
				if ($metric_id_map{$mx} && ($metric_id_map{$mx} eq $tmp_sensor)) {
					print CFG $metrics{$_};
				}
			}		
		}
	}
	
	
	#
	# samples
	#
	# if split file configuration, skip this one
	if (!$split_config) {
		print CFG "\tSamples\n";
		my $dummy = 0;
		for (sort keys %sample) {
			my ($period,$offset_tmp,$reftime) = split;
			#$offset = sprintf("%04d",$offset_tmp);
			print CFG "\t\tSampling_".++$dummy."\n";
			print CFG "\t\t\tTiming\t$period\t$offset_tmp\n";
			print CFG "\t\t\tReferenceTime\t$reftime\n" if defined $reftime;
			print CFG "\t\t\tMetrics\n";
			map {print CFG "\t\t\t\t$_\n"} sort {$a <=> $b} @{$sample{$_}};
		}
	}
	close(CFG);
	
	#
	# if there was no cfg file (ie lemon-agent was never running),
	# just put the cfg file in place and start the monitoring
	#
	push(@sensor_files,$default_cfg);
	push(@sensor_files,$transport_cfg);
	if (!$split_config) {
		if (not -e $cfgfile) {
			  CORE::rename "$cfgfile.tmp",$cfgfile;                              # put cfg files in place
			  $status = CORE::system("/sbin/service $service start");            # start monitoring
			  if ($status ne 0) {
				  $self->error("Unable to start monitoring: $?");
			  }
			  return;
		  }
	} else {
		if ( not -e $default_cfg ) {
			foreach $s_file( @sensor_files ) {
				CORE::rename "$s_file.tmp",$s_file;
			}
		}
	}
	
	#
	# if the configuration has not changed, do nothing
	#
	if ($split_config) {
		my $changed = 0;
		foreach $s_file( @sensor_files ) {
			if ( -e $s_file && -e "$s_file.tmp" ) {
				if (MD5sum($s_file) ne MD5sum("$s_file.tmp")) { $changed = 1;};
			} else {
				$changed = 1;
			}
			CORE::rename "$s_file.tmp",$s_file;
			CORE::unlink "$s_file.tmp";
		}
	} else {
		if (MD5sum($cfgfile) eq MD5sum("$cfgfile.tmp") and $modified eq 0) {
			CORE::unlink "$cfgfile.tmp";
			return;
		}
		#
		# otherwise, put cfg file in place and restart monitoring
		#
		CORE::rename "$cfgfile.tmp",$cfgfile;                     # put cfg files in place
	}
		
        my $state = qx%/sbin/service $service status%;
        my $restartcmd = undef;
        if ( $state =~ "running" ) {
          $restartcmd = "restart";
        } else {
	  my $booting = "false";
	  if ( defined($ENV{"NOTD_EXEC_TODO"}) ) {
            if ( $ENV{"NOTD_EXEC_TODO"} =~ "boot" ) {
              $booting = "true";
            }
          }
	  if ( ( $booting =~ "false" ) && ( CORE::system("/sbin/chkconfig $service") == 0 ) ) {
            $restartcmd = "start";
          }
        }
        if ( defined($restartcmd) ) {
	  $status = CORE::system("/sbin/service $service $restartcmd"); # restart monitoring
	  if ($status ne 0) {
		$self->error("Unable to restart monitoring: $?");
	  }
        } else {
          $self->log("Monitoring was stopped. Not restarted");
        } 

	return;
}


##########################################################################
sub Unconfigure {
##########################################################################
	my ($self,$config)=@_;

	InitConfig();	
	$self->info("Unconfiguring $service");
	
	$status = CORE::system("/sbin/service $service stop");
	if ($status ne 0) {
		$self->error("Unable to stop monitoring: $?");
	}

	return;
}


########################################################################
#
# return hexadecimal checksum of contents of a file
#

sub MD5sum($) {
	my $file = shift;
	if (not CORE::open(FILE,"<$file")) {
		$self->info("MD5::Cannot open \"$file\" for reading: $!");
		return -1;
	}
	binmode(FILE);
	my $md5 = Digest::MD5->new->addfile(*FILE)->hexdigest;
	close(FILE);
	return $md5;
}


########################################################################
#
# remove all _CDB files to get rid of unconfigured sensors/metrics
#
sub remove_old_files() {
	opendir(DIR, "$cfgfile/sensors") || die "can't opendir $cfgfile/sensors: $!";
	while ($name = readdir(DIR)) {
		if ($name =~ /^(\w+)$/){
			$name = $1;
		 	if ($name =~ m/_CDB.conf/) {
				CORE::unlink "$cfgfile/sensors/$name";
			}
		}
	}
	closedir DIR;

	opendir(DIR, "$cfgfile/metrics") || die "can't opendir $cfgfile/sensors: $!";
	while ($name = readdir(DIR)) {
		if ($name =~ /^(\w+)$/){
			$name = $1;
			if ($name =~ m/_CDB.conf/) {
				CORE::unlink "$cfgfile/metrics/$name";
			}
		}
	}
	closedir DIR;
}


########################################################################
#
# write "$init_file" - changes the default config file to 
# configured one - to split-file or single file
#

sub InitConfig($) {
	if ( not -e "$init_file") {
		$service ="edg-fmon-agent";
		$init_file = "/etc/rc.d/init.d/$service";
	}
	return 0 if not -e "$init_file";
	
	# get rid of the old file
	if ( -e "$init_file.old") {
		CORE::unlink "$init_file.old";
	}
	NCM::Check::lines("$init_file",
			  linere => "^CFG_FILE=\".*\"",
			  goodre => "^CFG_FILE=\"$cfgfile\"",
			  good   => "CFG_FILE=\"$cfgfile\"",
			  backup => ".old",
			  );
	# if .old exists return flag about change
	if ( -e "$init_file.old") {
		$modified = 1;
		chmod 0755, $init_file;
	}
	return 1;
}


1;

__END__
