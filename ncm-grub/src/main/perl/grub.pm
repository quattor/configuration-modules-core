# ${license-info}
# ${developer-info}
# ${author-info}

#
# grub - NCM grub configuration component
#
# set the correct kernel in /etc/grub.conf using grubby
#
###############################################################################

package NCM::Component::grub;

#
# a few standard statements, mandatory for all components
#

use strict;
use CAF::FileEditor;
use CAF::FileWriter;
use NCM::Component;
use Readonly;
use EDG::WP4::CCM::Element;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::grub::NoActionSupported = 1;

Readonly::Scalar my $GRUBCONF => '/boot/grub/grub.conf';

sub parseKernelArgs {
    my ($kernelargs)=@_;

    ## howto remove an argument: precede with a -
    my @allargs=split(/ /,$kernelargs);
    my $kernelargsadd = "";
    my $kernelargsremove = "";
    my $i;
    foreach $i (@allargs) {
        if ($i =~ /^-/) {
            $i =~ s/^-//;
            $kernelargsremove .= $i." ";
        } else {
            $kernelargsadd .= $i." ";
        }
    }

    if ($kernelargsadd ne "") {
        chop($kernelargsadd);
    }
    if ($kernelargsremove ne "") {
        chop($kernelargsremove);
    }

    return ($kernelargsadd, $kernelargsremove);
}

sub grubbyArgsOptions {
    my ($kernelargs, $mb)=@_;
    my ($kernelargsadd, $kernelargsremove) = parseKernelArgs($kernelargs);

    if ($kernelargsadd ne "") {
#        chop($kernelargsadd);
        $kernelargsadd = "--".$mb."args=\"".$kernelargsadd."\"";
    }
    if ($kernelargsremove ne "") {
#        chop($kernelargsremove);
        $kernelargsremove = "--remove-".$mb."args=\"".$kernelargsremove."\"";
    }

    return ($kernelargsadd, $kernelargsremove);

}

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  my $grubby='/sbin/grubby';
  my $prefix='/boot';
  if ($config->elementExists("/software/components/grub/prefix")) {
    $prefix = $config->getValue("/software/components/grub/prefix");
  }
  my $kernelname='vmlinuz';
  my $kernelpath='/system/kernel/version';
  unless ($config->elementExists($kernelpath)) {
    $self->error("cannot get $kernelpath");
    return;
  }
  my $kernelversion=$config->getValue($kernelpath);
  my $fulldefaultkernelpath=$prefix.'/'.$kernelname.'-'.$kernelversion;

  my $cons = undef;
  my $consolepath = "/hardware/console/serial";
  my $serialcons  = undef;
  my $newserial = "";
  my $newterminal = "";
  if ($config->elementExists($consolepath)) {
    my %consnode = $config->getElement($consolepath)->getHash();

    my $unit = "0";
    if (exists $consnode{"unit"}) {
      $unit = $consnode{"unit"}->getValue();
    }

    my $speed = "9600";
    if (exists $consnode{"speed"}) {
      $speed = $consnode{"speed"}->getValue();
    }

    my $word = "8";
    if (exists $consnode{"word"}) {
      $word = $consnode{"word"}->getValue();
    }

    my $parity = "n";
    if (exists $consnode{"parity"}) {
      $parity = $consnode{"parity"}->getValue();
    }
    $cons = " console=ttyS$unit,$speed$parity$word";
    $newserial   = "serial --unit=$unit --speed=$speed --parity=$parity --word=$word\n";
    $newterminal = "terminal serial console\n";
  }

  my $path = "/software/components/grub/kernels";

  my @kernels;

  # read information in as array of hashes
  if ($config->elementExists($path)) {
      my $configroot = $config->getElement($path);

      while ($configroot->hasNextElement()) {
          my $el = $configroot->getNextElement();
          my $eln = $el->getName();
          $self->verbose ("Element: $eln");
          if ($el->isType(EDG::WP4::CCM::Element::NLIST)) {
              my %kernelhash = $el->getHash();
              $kernels[$eln]=\%kernelhash;

              while( my ($k, $v) = each %kernelhash ) {
                  if ($v->isProperty()) {
                      my $value = $v->getValue();
                      $kernelhash{$k}=$value;
                      $self->verbose("  key: $k, value $value");
                  }
              }
          }
      }
  }


# check to see whether grubby has native support for configuring
# multiboot kernels
  my $check_grubby_mbsupport=`$grubby --add-multiboot 2>&1`;
  chomp($check_grubby_mbsupport);

  my $grubby_has_mbsupport;

  if ("$check_grubby_mbsupport" eq "grubby: bad argument --add-multiboot: missing argument") {
      $grubby_has_mbsupport=1;
      $self->verbose("This version of grubby has support for multiboot kernels");
  }
  else {
      $grubby_has_mbsupport=0;
      $self->verbose("This version of grubby has no support for multiboot kernels");
  }


  # Check the serial console settings if neccessary
  if ($newserial) {
      my $modified = 0;
      # grab a copy of the old file (if it exists)
      my @grublines = ();
      if (open(my $fh, '<', $GRUBCONF)) {
          @grublines = <$fh>;
      } else {
        $self->warn("Unable to open $GRUBCONF");
        @grublines = (
		"# Generated by ncm-grub\n",
                $newserial,
                $newterminal,
        );
        $modified++;
      }

      # must find out how to use the std library, for now we'll just manually
      # do it.... If there are no serial console settings in there already,
      # then we insert them just before the first kernel (the first title line)
      my $gotserial = 0;
      my $gotterminal = 0;
      foreach my $g (@grublines) {
          if ($g =~ /^title/) {
              my $add = "";
              if (!$gotserial) {
                  $add = $newserial;
              }
              if (!$gotterminal) {
                  $add .= $newterminal;
              }
              if ($add) {
                  $g = "$add$g";
              }
              $modified++;
              last;
          }

          if ($g =~ /^serial/) {
              if ($g ne $newserial) {
                $g = $newserial;
                $modified++;
              }
              $gotserial++;
          }
          if ($g =~ /^terminal/) {
              if ($g ne $newterminal) {
                  $g = $newterminal;
                  $modified++;
              }
              $gotterminal++;
          }
      }

      my $fw = CAF::FileWriter->new($GRUBCONF,
                                    owner => "root",
                                    group => "root",
                                    mode => 0400,
                                    log => $self);
      print $fw @grublines;
      $fw->close();
  }

  foreach my $kernel (@kernels) {

      my ($kernelpath, $kernelargs, $kerneltitle, $kernelinitrd,
          $multibootpath, $fullkernelpath, $fullkernelinitrd, $fullmultibootpath,$mbargs);

      if ($kernel->{'kernelpath'}) {
          $kernelpath=$kernel->{'kernelpath'};
          $fullkernelpath=$prefix.$kernelpath;
      }
      else {
          $self->error("Mandatory kernel path missing, skipping this kernel");
          next;
      }

      if ($kernel->{'kernelargs'}) {
          $kernelargs=$kernel->{'kernelargs'};
          if ($cons) {
              # by $cons we mean serial cons, so we should only sub serial entries.
              $kernelargs =~ s{console=(ttyS[^ ]*)}{};
              $kernelargs .= $cons;
          }
      }

      if ($kernel->{'title'}) {
          $kerneltitle=$kernel->{'title'};
      }
      else {
          $kerneltitle=$kernelpath;
      }

      if ($kernel->{'initrd'}) {
          $kernelinitrd=$kernel->{'initrd'};
          $fullkernelinitrd=$prefix.$kernel->{'initrd'};
      }
      if ($kernel->{'multiboot'}) {
          $multibootpath=$kernel->{'multiboot'};
          $fullmultibootpath=$prefix.$kernel->{'multiboot'};

      }
      if ($kernel->{'mbargs'}) {
          $mbargs=$kernel->{'mbargs'};
      }

      my $grubbystring="";



      # check whether this kernel is already installed
      `$grubby --info=$fullkernelpath 2>&1`;
      my $kernelinstalled = $?;

      # check whether the multiboot loader is installed
      my $mbinstalled=1;
      if ($multibootpath) {
          `$grubby --info=$fullmultibootpath 2>&1`;
          $mbinstalled= $?;
      }

      if ($kernelinstalled && $mbinstalled) {
          $self->info ("Kernel $kernelpath not installed, trying to add it");

          # installing multiboot loader
          if ($kernel->{'multiboot'}) {
              if (!$grubby_has_mbsupport) {
                  $self->info ("This version of grubby doesn't support multiboot");

                  # in this case, we write out the whole entry ourselves
                  # as it is easier than working round grubby
                  my ($kernelargsadd, $kernelargsremove, $mbargsadd, $mbargsremove);

                  if ($kernelargs) {
                      ($kernelargsadd, $kernelargsremove) = parseKernelArgs($kernelargs);
                  }
                  if ($mbargs) {
                      ($mbargsadd, $mbargsremove) = parseKernelArgs($mbargs);
                  }

                  my $grubconfstring="title $kerneltitle\n";
                  $grubconfstring.="\tkernel $multibootpath $mbargsadd\n";
                  $grubconfstring.="\tmodule $kernelpath $kernelargs\n";
                  $grubconfstring.=($kernelinitrd)?"\tmodule $kernelinitrd":"";
                  $self->verbose("Generating grub entry ourselves: \n$grubconfstring");


                  # append this entry to grub.conf
                  open(GRUBCONF,">>/boot/grub/grub.conf") || die("Cannot Open File");
                  print GRUBCONF $grubconfstring;
                  close(GRUBCONF);

              }
              else {
                  $self->verbose("Adding kernel using native grubby multiboot support");
                  my ($mbargsadd, $mbargsremove, $kernelargsadd, $kernelargsremove);

                  $grubbystring.=" --add-multiboot=\"$fullmultibootpath\"";

                  if ($kernelargs) {
                      ($kernelargsadd, $kernelargsremove) = parseKernelArgs($kernelargs);
                  }
                  if ($mbargs) {
                      ($mbargsadd, $mbargsremove) = parseKernelArgs($mbargs);
                  }

                  $grubbystring.=($mbargsadd)?" --mbargs=\"$mbargsadd\"":"";
                  $grubbystring.=($mbargsremove)?" --remove-mbargs=\"$mbargsremove\"":"";

                  $grubbystring.=" --add-kernel=\"$fullkernelpath\"";

                  $grubbystring.=($kernelargsadd)?" --args=\"$kernelargsadd\"":"";
                  $grubbystring.=($kernelargsremove)?" --args=\"$kernelargsremove\"":"";

                  $grubbystring.=" --title=\"$kerneltitle\"";
                  $grubbystring.=($kernelinitrd)?" --initrd=\"$fullkernelinitrd\"":"";

                  $self->verbose("Configuring kernel using grubby command: $grubbystring");
                  my $grubbyresult=`$grubby $grubbystring 2>&1`;
              }
          }
          else {
              $self->info("Adding new standard kernel");
              $grubbystring.=" --add-kernel=\"$fullkernelpath\"";

              my ($kernelargsadd, $kernelargsremove);
              if ($kernelargs) {
                  ($kernelargsadd, $kernelargsremove) = parseKernelArgs($kernelargs);
              }

              $grubbystring.=($kernelargsadd)?" --args=\"$kernelargsadd\"":"";
              $grubbystring.=($kernelargsremove)?" --remove-args=\"$kernelargsremove\"":"";

              $grubbystring.=" --title=\"$kerneltitle\"";
              $grubbystring.=($kernelinitrd)?" --initrd=\"$fullkernelinitrd\"":"";
              $self->verbose("Adding kernel using grubby command: $grubbystring");
              my $grubbyresult=`$grubby $grubbystring 2>&1`;
          }
      }
      else {  # updating existing kernel entry

          $self->info ("Updating installed kernel $kernelpath");

          if ($kernel->{"multiboot"}) {

              if ($grubby_has_mbsupport) {
                  $self->verbose("Updating kernel using native grubby multiboot support");
                  $grubbystring.=" --add-multiboot=\"$fullmultibootpath\"";

                  $grubbystring.=" --update-kernel=\"$fullkernelpath\"";

                  my ($kernelargsadd, $kernelargsremove, $mbargsadd, $mbargsremove);

                  if ($kernelargs) {
                      ($kernelargsadd, $kernelargsremove) = parseKernelArgs($kernelargs);
                  }
                  if ($mbargs) {
                      ($mbargsadd, $mbargsremove) = parseKernelArgs($mbargs);
                  }

                  $grubbystring.=($mbargsadd)?" --mbargs=\"$mbargsadd\"":"";
                  $grubbystring.=($mbargsremove)?" --remove-mbargs=\"$mbargsremove\"":"";


                  $grubbystring.=($kernelargsadd)?" --args=\"$kernelargsadd\"":"";
                  $grubbystring.=($kernelargsremove)?" --remove-args=\"$kernelargsremove\"":"";

                  $self->verbose("Updating kernel using grubby command: $grubbystring");
                  my $grubbyresult=`$grubby $grubbystring 2>&1`;

              }
              else {
                  $self->warn("Updating multiboot kernel using non-multiboot grubby: check results");
                  $grubbystring.=" --update-kernel=\"$fullmultibootpath\"";

                  my ($mbargsadd, $mbargsremove);

                  if ($mbargs) {
                      ($mbargsadd, $mbargsremove) = parseKernelArgs($mbargs);
                  }

                  $grubbystring.=($mbargsadd)?" --args=\"$mbargsadd\"":"";
                  $grubbystring.=($mbargsremove)?" --remove-args=\"$mbargsremove\"":"";


                  # TODO: use NCM::Check::lines to try and
                  # edit the module args lines?


                  my $grubbyresult=`$grubby $grubbystring 2>&1`;
              }

          }
          else {

              $self->verbose("Updating standard kernel $kernelpath");
              my ($kernelargsadd, $kernelargsremove);
              if ($kernelargs) {
                  ($kernelargsadd, $kernelargsremove) = parseKernelArgs($kernelargs);
              }
              $grubbystring.=($kernelargsadd)?" --args=\"$kernelargsadd\"":"";
              $grubbystring.=($kernelargsremove)?" --remove-args=\"$kernelargsremove\"":"";

              $grubbystring.=" --update-kernel=\"$fullkernelpath\"";
              my $grubbyresult=`$grubby $grubbystring 2>&1`;
          }
      }

  }



  # next section of code processes the default kernel as defined in
  # /system/kernel/version and comes from the earlier version of ncm-grub

  my $oldkernel=undef;

  unless (-x $grubby) {
      $self->error ("$grubby not found");
      return;
  }
  unless (-e $fulldefaultkernelpath) {
      $self->error ("Kernel $fulldefaultkernelpath not found");
      return;
  }


  # the checks that grub uses to determine whether a kernel is "good"
  # are simplistic, and include checking that the name is like "vmlinuz"
  # so we disable them for now
  $oldkernel=`$grubby --default-kernel --bad-image-okay`;
  chomp($oldkernel);
  if ($?) {
      $self->error ("Can't run $grubby --default-kernel, (return code $?)");
      return;
  }

  if ($oldkernel eq '') {
      $self->warn ("Can't get current default kernel");
  }


  unless ($NoAction) {
      if ($oldkernel eq $fulldefaultkernelpath) {
          $self->info("correct kernel (".$kernelversion.") already configured");
      } else {
          my $s=`$grubby --set-default $fulldefaultkernelpath`;

          if ($?) {

              $s=`$grubby --set-default $oldkernel` unless ($oldkernel eq '');
              $self->error("can't run $grubby --set-default $fulldefaultkernelpath, reverting to previous kernel $oldkernel");
              return;
          }

          # check that new kernel is really set
          # as grubby always returns 0 :-(
          #
          $s=`$grubby --default-kernel --bad-image-okay`;
          chomp($s);
          if ($s ne $fulldefaultkernelpath) {
              # check whether the specified kernel version exists within
              # another multiboot specification
              foreach my $kernel (@kernels) {

                  if ( ($prefix.($kernel->{"kernelpath"})) eq $fulldefaultkernelpath) {
                      my $fullmultibootpath=$prefix.($kernel->{"multiboot"});
                      $self->verbose("Trying to set kernel to $fullmultibootpath");
                      $s=`$grubby --set-default $fullmultibootpath`;

                      $s=`$grubby --default-kernel --bad-image-okay`;
                      chomp($s);

                      if ($s ne $fullmultibootpath) {
                          $s=`$grubby --set-default $oldkernel` unless ($oldkernel eq '');
                          $self->error ("Can't run $grubby --set-default $fulldefaultkernelpath, reverting to previous kernel $oldkernel");
                          return;
                      }
                  }
              }
          }
      }

      ## at this point the `$grubby --default-kernel` should equal $fulldefaultkernelpath

      # Check if 'fullcontrol' is defined in CDB
      my $fullcontrol = 0;
      if ( $config->elementExists("/software/components/grub/fullcontrol")
          && ($config->getValue("/software/components/grub/fullcontrol") eq "true")){
	  $fullcontrol = 1;
	  $self->debug(2,"fullcontrol is true");
      }
      else{
	  $self->debug(2,"fullcontrol is not defined or false");
      }

      # If we want full control of the arguments:
      if ( $fullcontrol ) {

	  my $kernelargspath="/software/components/grub/args";
	  my $kernelargsadd;
	  if ($config->elementExists($kernelargspath)) {
	      $kernelargsadd=$config->getValue($kernelargspath);
	  }
	  else{
	      $kernelargsadd="";
	  }

          ## Check current arguments
	  my $kernelargsremove;

	  my $info = `$grubby --info=$fulldefaultkernelpath`;
	  if($info =~ /args=\"(.*)\"\n/){
	      $kernelargsremove = $1;
	      print "\nKernelArgRemove", $kernelargsremove, "\n";
	  }

          ## Check if the arguments we want to add are the same we have
	  if ($kernelargsremove eq $kernelargsadd){
	      $self->OK("Updated boot kernel without changes in the arguments");
	  }
	  else{
	      ## Remove all the arguments
	      if ($kernelargsremove ne "") {
		  $kernelargsremove = "--remove-args=\"".$kernelargsremove."\"";
		  `$grubby --update-kernel=$fulldefaultkernelpath $kernelargsremove`;
		  if ($?) {
		      $self->error("can't run $grubby --update-kernel=$fulldefaultkernelpath $kernelargsremove");
		      return;
		  }
	      }

	      ## Add the specified inside $kernelargs
	      if ($kernelargsadd ne "") {
		  print "\nKernelArgAdd", $kernelargsadd, "\n";
		  $kernelargsadd = "--args=\"".$kernelargsadd."\"";
		  `$grubby --update-kernel=$fulldefaultkernelpath $kernelargsadd`;
		  if ($?) {
		      $self->error("can't run $grubby --update-kernel=$fulldefaultkernelpath $kernelargsadd");
		      return;
		  }
		  $self->OK("Updated boot kernel arguments with $kernelargsadd $kernelargsremove");
	      }

	      else {
		  $self->OK("Updated boot kernel with no arguments");
	      }
	  }
      }
      # If we want no full control of the arguments
      else {
	  my $kernelargspath="/software/components/grub/args";
	  if ($config->elementExists($kernelargspath)) {
	      my $kernelargs=$config->getValue($kernelargspath);
	      my ($kernelargsadd, $kernelargsremove) = grubbyArgsOptions($kernelargs,"");


	      my $s=`$grubby --update-kernel=$fulldefaultkernelpath $kernelargsadd $kernelargsremove`;
	      if ($?) {
		  $self->error("can't run $grubby --update-kernel=$fulldefaultkernelpath $kernelargsadd $kernelargsremove");
		  return;
	      }
	      ## since you can't check the current kernelargs with grubby, lets hope for the best?
	      $self->verbose("Updated boot kernel ($fulldefaultkernelpath) arguments with $kernelargsadd $kernelargsremove");
	  } else {
	      $self->verbose("No kernel arguments set");
	  }
      }
      # all OK
      $self->OK("Updated boot kernel version to $fulldefaultkernelpath");
  }
  return;
}

1; #required for Perl modules
