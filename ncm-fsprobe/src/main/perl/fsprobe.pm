# ${license-info}
# ${developer-info}
# ${author-info}


#
# a few standard statements, mandatory for all components
#

package NCM::Component::fsprobe;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use LC::Process;
use LC::File;
use Socket;
use Data::Dumper;

#
# OO stuff
#
$EC->error_handler(\&my_handler);
sub my_handler {
	my($ec, $e) = @_;
	$e->has_been_reported(1);
}

##########################################################################
sub Configure {
##########################################################################
	my ($self,$config)=@_;

	my $valPath = '/software/components/fsprobe';

	unless ($config->elementExists($valPath)) {
		$self->error("cannot get $valPath");
		return;
	}

	my $re; # root element (of subtrees in our config)
	my $val; # value (temporary) retrieved for a given config element

	my $cdbpath;
	my @fields;
	my $fsprobeoptions="";

	$cdbpath=$valPath."/options";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    $fsprobeoptions=$re->getValue();
	}

	my $logfile="/var/log/fsprobe.log";
	$cdbpath=$valPath."/logfile";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    $logfile=$re->getValue();
	}
	$fsprobeoptions.=" --LogFile $logfile";

	my $mailto=undef;
	$cdbpath=$valPath."/mailto";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    $mailto=$re->getValue();
	    $mailto=~s/ /,/;
	    $fsprobeoptions.=" --MailTo $mailto";
	}
	my $mailsubject=undef;
	$cdbpath=$valPath."/mailsubject";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    $mailsubject=$re->getValue();
	    $fsprobeoptions.=" --MailSubject \\\"$mailsubject\\\"";
	}

	my $maildelay=undef;
	$cdbpath=$valPath."/maildelay";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    $maildelay=$re->getValue();
	    $fsprobeoptions.=" --MailDelay \\\"$maildelay\\\"";
	}


	my $syslog=undef;
	$cdbpath=$valPath."/syslog";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    $syslog=$re->getValue();
	    if ($syslog eq "true") {
		$fsprobeoptions.=" --Syslog";
	    }
	}

	my $filesize=2*1024*1024*1024;	# 2G
	$cdbpath=$valPath."/filesize";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    my $filesizetxt=$re->getValue();
	    $filesize=$filesizetxt;
	    $fsprobeoptions.=" --FileSize $filesize";
	}

	my $buffersize=4*1024*1024;	# 4M
	$cdbpath=$valPath."/buffersize";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    my $buffersizetxt=$re->getValue();
	    $buffersize=$buffersizetxt;
	    $fsprobeoptions.=" --BufferSize $buffersize";
	}

	my $localflag="-l";
	$cdbpath=$valPath."/remotefs";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    my $remotefs=$re->getValue();
	    if ($remotefs eq "true") {
		$localflag="";
	    }
	}

	my @filesystems;
	my %fskfree;

	# List local file systems only
	if (open(DF,"df $localflag -k |")) {
	    while (<DF>) {
		next if (/^Filesystem/);
	    	chomp;
		my @dffields=split / +/,$_;
		my $fsname=$dffields[5];
		my $kfree=$dffields[3];
		next unless (defined($fsname));
		push @filesystems,$fsname;
		$fskfree{$fsname}=$kfree;
	    }
	    close DF;
	}

	my $dir=".fsprobe";
	$cdbpath=$valPath."/dir";
	if ($config->elementExists($cdbpath)) {
	    $re=$config->getElement("$cdbpath");
	    $dir=$re->getValue();
	}

	my @fsprobe_fslist;
	$cdbpath=$valPath."/filesystems";
	$re=$config->getElement("$cdbpath");
	while ($re->hasNextElement()) {
	    my $he=$re->getNextElement();
	    my $heval=$he->getValue();
	    my $fsp;
	    $heval=~s/\//\\\//g;
	    for $fsp (@filesystems) {
		if ($fsp =~ /$heval/) {
		    my $fdir=$fsp."/".$dir;
		    # Must have at least 3 GB free
		    my $kfree=$fskfree{$fsp};
		    my $filesizek=int($filesize/1024);
		    if (defined($kfree) && $kfree<3*$filesizek) {
			$self->warn("Insufficient space to monitor $fdir ($kfree Kb free, file size $filesizek Kb)");
			next;
		    }
		    if (! -d $fdir) {
			if (!mkdir($fdir,0600)) {
			    $self->error("Cannot create directory $fdir");
			}
		    }
		    if (-d $fdir) {
			push @fsprobe_fslist,$fdir;
		    }
		}
	    }
	}

	my $fsprobesysconfig="/etc/sysconfig/fsprobe";
	my $oldcontents="";

	if (open(SYS,"$fsprobesysconfig")) {
	    while (<SYS>) {
		next if (/^#/);
		$oldcontents.="$_";
	    }
	    close SYS;
	}

	my $newcontents="";
	$newcontents.="RUN_FSPROBE=YES\n";
	$newcontents.="FSPROBE_FS=\"".join(" ",@fsprobe_fslist)."\"\n";
	$newcontents.="FSPROBE_OPTIONS=\"".$fsprobeoptions."\"\n";
	$newcontents.="FSPROBE_LOG=\"".$logfile."\"\n";
	$newcontents.="FSPROBE_FILESIZE=\"".$filesize."\"\n";

	if ($newcontents ne $oldcontents) {
	    $self->info("Updating $fsprobesysconfig");
	    if (open(SYS,">$fsprobesysconfig")) {
		print SYS "# Automatically generated by ncm-fsprobe at ".localtime(time())."\n";
		print SYS "$newcontents";
		close SYS;

		my $cmd="service fsprobe restart";
		$self->info("Running $cmd");
		system("$cmd");
	    }
	}
	return;
}

##########################################################################
sub Unconfigure {
##########################################################################
}


1; #required for Perl modules
