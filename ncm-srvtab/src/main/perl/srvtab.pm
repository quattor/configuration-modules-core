# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

package NCM::Component::srvtab;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

#*** The following gives the OS name using the LC perl modules.
# In example, $OSname can be 'Linux' or 'Solaris'
# It's equivalent to perl's variable $^O (it gives the OS in lower-case)
use LC::Sysinfo;
my $OSname=LC::Sysinfo::os()->name;

my @arctools;      # list of possible helper scripts. Prefer *-keytab over *-srvtab
my $arctool;       # the one we will use after all
my $aksrvutil;

if ($OSname=~ /Linux/) {
   push(@arctools,'/usr/bin/cern-config-keytab','/afs/usr/local/etc/cern-config-keytab','/usr/bin/cern-config-srvtab');
   $aksrvutil='/usr/bin/aksrvutil';
}

if ($OSname=~ /Solaris/) {
   push(@arctools,'/opt/edg/bin/cern-config-keytab','/afs/usr/local/etc/cern-config-keytab','/opt/edg/bin/cern-config-srvtab');
   $aksrvutil='/usr/local/etc/aksrvutil';
}

my $mypath='/software/components/srvtab';

#***######################################################################
sub utils_OK {
  my ($self,$aksrvutil,@arctools)=@_;
  foreach my $tool (@arctools) {
   if( -x $tool) {
    $arctool=$tool;
    last;
  }
 }
 if( ! $arctool) {
  $self->error ("cannot find helper script, looked for ".join(',',@arctools));
  return 0;
 }

 unless (-x $aksrvutil) {
  $self->info ("cannot execute $aksrvutil, Kerberos4 srvtab creation might fail");
 }

  return 1;
}

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  my $verbose ='';

  return unless utils_OK($self,$aksrvutil,@arctools);

  unless ($config->elementExists($mypath."/server")) {
    $self->error("cannot get $mypath/server");
    return 0;
  }

  unless ($config->elementExists($mypath."/overwrite")) {
    $self->error("cannot get $mypath/overwrite");
    return 0;
  }

  my $arc_server=$config->getValue($mypath."/server");
  my $force=$config->getValue($mypath."/overwrite");

  if ($config->elementExists($mypath."/verbose")) {
    my $temp = $config->getValue($mypath."/overwrite");
    if ($temp && $temp !~ m/(false|0)/i) {
      $verbose = '-v';
    }
  }


  unless ($NoAction) {
    my $args = $verbose;
    $args .= " -f" if ($force eq "true");
    $args .= " -s $arc_server";
    my $out = `$arctool $args 2>&1`;
    my $retval = ($? >> 8);
    if ($retval) {
      $self->error("$arctool:\n$out");
    } else {
      $self->info("$arctool:\n$out");
      $self->OK("Configured Kerberos host principal");
    }

  }
  return 1;
}


##########################################################################
sub Unconfigure {
##########################################################################
  unless ($NoAction) {
   my ($self,$config)=@_;

    $self->OK("Unconfigured Kerberos host principal - nothing done");
  }
  return 1;
}

1; #required for Perl modules


### Local Variables: ///
### mode: perl ///
### End: ///
