# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::modprobe - ncm modprobe configuration component
#
################################################################################

package NCM::Component::modprobe;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use EDG::WP4::CCM::Configuration;
use LC::Process qw(run);
use LC::File qw(copy file_contents);

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  my @file_stat;
  my %mod_conf_file=();
  my $conf_file;
  my $rebuild=0;
  my @moduleslist;
  my %alias=();
  my %options=();
  my %install=();
  my %remove=();
  my @boot_contents;
  my $boot_ref;
  my @kernel_release=();

  unless (($boot_ref = LC::File::directory_contents("/boot"))) {
        $self->error( "error reading contents of /boot" );
        return;
  }

  @boot_contents=@{$boot_ref};

  foreach my $kernel (0..$#boot_contents) {
    if ($boot_contents[$kernel]=~/^System\.map\-(2\.4\.\d+.*)$/) {
      push(@kernel_release, $1);
      $mod_conf_file{"24"}="/etc/modules.conf";
    } elsif ($boot_contents[$kernel]=~/^System\.map\-(2\.6\.\d+.*)$/) {
      push(@kernel_release, $1);
      $mod_conf_file{"26"}="/etc/modprobe.conf";
    }
  }

  foreach my $kernel (keys %mod_conf_file) {
          $conf_file = $mod_conf_file{$kernel};
          if ((-f $conf_file) and (my @file_stat=stat($conf_file))) {
            $file_stat[2] = 0600;              # mode
            $file_stat[4] = $file_stat[5] = 0; # uid/gid
            unless (LC::File::change_stat( $conf_file, @file_stat)) {
                  $self->error('changing mode/uid/gid of $conf_file file');
                  return;
            }
          } elsif (!(-f $conf_file)) {
                 unless (open(FILE,">$conf_file")) {
                       $self->error('creating $conf_file file');
                       return;
                 }
                 @file_stat=stat($conf_file);
                 $file_stat[2] = 0600;              # mode
                 $file_stat[4] = $file_stat[5] = 0; # uid/gid
                 unless (LC::File::change_stat( $conf_file, @file_stat)) {
                       $self->error('changing mode/uid/gid of $conf_file file');
                       return;
                 }
          }
   }

  # is there any modules configuration information
  if (!$config->elementExists('/software/components/modprobe/modules')) {
    $self->error('no modules configuration information defined');
    return;
  }

  # how many modules I have
  @moduleslist = $config->getElement('/software/components/modprobe/modules')->getList();

  foreach my $i (0 .. $#moduleslist) {
          my $module_name= $config->getElement('/software/components/modprobe/modules/'.$i.'/name') ->getValue();

          if ($config->elementExists('/software/components/modprobe/modules/'.$i.'/alias')) {
            my $module_alias=$config->getElement('/software/components/modprobe/modules/'.$i.'/alias')->getValue();
            push @{$alias{$module_name }}, $module_alias;
            $rebuild=1;
          }

          if ($config->elementExists('/software/components/modprobe/modules/'.$i.'/options')) {
            my $module_options=$config->getElement('/software/components/modprobe/modules/'.$i.'/options')->getValue();
            $options{$module_name}=$module_options;
            $rebuild=1;
          }

          if ($config->elementExists('/software/components/modprobe/modules/'.$i.'/install')) {
            my $module_install=$config->getElement('/software/components/modprobe/modules/'.$i.'/install')->getValue();
            $install{$module_name}=$module_install;
            $rebuild=1;
          }

          if ($config->elementExists('/software/components/modprobe/modules/'.$i.'/remove')) {
            my $module_remove=$config->getElement('/software/components/modprobe/modules/'.$i.'/remove')->getValue();
            $remove{$module_name}=$module_remove;
            $rebuild=1;
         }
   }

  my $changes = 0;
  foreach my $kernel (keys %mod_conf_file) {
          $conf_file = $mod_conf_file{$kernel};
          foreach my $name (keys %alias) {
                  foreach my $i ( 0 .. $#{ $alias{$name} } ) {
                          $changes += NCM::Check::lines( $conf_file,
                               linere => '^\s*alias\s+'.$alias{$name}[$i].'\s+.*',
                               goodre => 'alias '.$alias{$name}[$i].' '.$name,
                               good   => 'alias '.$alias{$name}[$i].' '.$name,
# I find the lines above illogical because if one needs to disable a module (e.g. IPv6)
# one has to specify this: nlist("name", "off", "alias", "net-pf-10"));
# However, other people say that it should be like that and that my modification
# from 2006 (release 1.0.3) is actually a bug. So - reverting back.
# 
# Vladimir Bahyl - 5/2007
#                               linere => '^\s*alias\s+'.$name.'\s+.*',
#                               goodre => 'alias '.$name.' '.$alias{$name}[$i],
#                               good   => 'alias '.$name.' '.$alias{$name}[$i],
                               keep   => 'first',
                               add    => 'last',
                               backup => '.old'
                           );
                  }
          }

          foreach my $name (keys %options) {
                  $changes += NCM::Check::lines( $conf_file,
                       linere => '^\s*options\s+'.$name.'\s+.*',
                       goodre => 'options '.$name.' '.$options{$name},
                       good   => 'options '.$name.' '.$options{$name},
                       keep   => 'first',
                       add    => 'last',
                       backup => '.old'
                  );
          }

          foreach my $name (keys %install) {
                  $changes += NCM::Check::lines( $conf_file,
                       linere => '^\s*install\s+'.$name.'\s+'.$install{$name},
                       goodre => 'install '.$name.' '.$install{$name},
                       good   => 'install '.$name.' '.$install{$name},
                       keep   => 'first',
                       add    => 'last',
                       backup => '.old'
                  );
          }

          foreach my $name (keys %remove) {
                  $changes += NCM::Check::lines( $conf_file,
                       linere => '^\s*remove\s+'.$name.'\s+'.$remove{$name},
                       goodre => 'remove '.$name.' '.$remove{$name},
                       good   => 'remove '.$name.' '.$remove{$name},
                       keep   => 'first',
                       add    => 'last',
                       backup => '.old'
                  );
          }
    }

  if (not $changes){
      $self->info("No changes to \"$conf_file\",so no need to re-run \"mkinitrd\"!");
  }else{
    if ($rebuild) {
      foreach my $kernel (0 .. $#kernel_release) {
            # Rebuild the initial ram disk image so that the modules are loaded on boot
            my $command = "/sbin/mkinitrd -f /boot/initrd-$kernel_release[$kernel].img $kernel_release[$kernel]";
            $self->info("running $command");
            unless (LC::Process::run($command)) {
                  $self->warn('problem with "$command" command');
                  return;
            }
      }
    }
  }

  return;
}

##########################################################################
sub Unconfigure {
##########################################################################
  my ($self,$config)=@_;
  my $rebuild=0;
  my %mod_conf_file=();
  my @boot_contents;
  my $boot_ref;
  my @kernel_release=();

  unless (($boot_ref = LC::File::directory_contents("/boot"))) {
        $self->error( "error reading contents of /boot" );
        return;
  }

  @boot_contents=@{$boot_ref};

  foreach my $kernel (0..$#boot_contents) {
    if ($boot_contents[$kernel]=~/^System\.map\-(2\.4\.\d+\-\d+.*)$/) {
      push(@kernel_release, $1);
      $mod_conf_file{"24"}="/etc/modules.conf";
    } elsif ($boot_contents[$kernel]=~/^System\.map\-(2\.6\.\d+\-\d+.*)$/) {
      push(@kernel_release, $1);
      $mod_conf_file{"26"}="/etc/modprobe.conf";
    }
  }

  foreach my $kernel (keys %mod_conf_file) {
          my $conf_file = $mod_conf_file{$kernel};
          my $conf_file_contents;

          unless (LC::File::copy( $conf_file, "$conf_file.old", preserve => 1)) {
                $self->error("error copying $conf_file to $conf_file.old");
                return;
          }

          unless (( $conf_file_contents = LC::File::file_contents( $conf_file ))) {
                $self->error( "error reading $conf_file contents" );
                return;
          }

         # how many modules I have
         my @moduleslist = $config->getElement('/software/components/modprobe/modules')->getList();

         foreach my $i (0 .. $#moduleslist) {
                 my $module_name= $config->getElement('/software/components/modprobe/modules/'.$i.'/name') ->getValue();
                 if ($config->elementExists('/software/components/modprobe/modules/'.$i.'/alias')) {
                   my $module_alias=$config->getElement('/software/components/modprobe/modules/'.$i.'/alias')->getValue();
                   if ($conf_file_contents =~ s/\s*alias\s+$module_alias\s+$module_name\s*//){
                     $rebuild=1;
                   }
                 }

                 if ($config->elementExists('/software/components/modprobe/modules/'.$i.'/options')) {
                   my $module_options=$config->getElement('/software/components/modprobe/modules/'.$i.'/options')->getValue();
                   $conf_file_contents =~ s/\s*options\s+$module_name\s+$module_options\s*//;
                   $rebuild=1;
                 }

                 if ($config->elementExists('/software/components/modprobe/modules/'.$i.'/install')) {
                   my $module_install=$config->getElement('/software/components/modprobe/modules/'.$i.'/install')->getValue();
                   $conf_file_contents =~ s/\s*install\s+$module_name\s+$module_install\s*//;
                   $rebuild=1;
                 }

                 if ($config->elementExists('/software/components/modprobe/modules/'.$i.'/remove')) {
                   my $module_remove=$config->getElement('/software/components/modprobe/modules/'.$i.'/remove')->getValue();
                   $conf_file_contents =~ s/\s*remove\s+$module_name\s+$module_remove\s*//;
                   $rebuild=1;
                 }
         }

         # copying contents back to the config file
         unless (( $conf_file_contents = LC::File::file_contents( $conf_file, $conf_file_contents ))) {
                $self->error( "error copying contents to $conf_file" );
                return;
         }
  }

  if ($rebuild) {
    foreach my $kernel (0 .. $#kernel_release) {
            # Rebuild the initial ram disk image so that the modules are loaded on boot
            my $command = "/sbin/mkinitrd -f /boot/initrd-$kernel_release[$kernel].img $kernel_release[$kernel]";
            $self->info("running $command");
            unless (LC::Process::run($command)) {
                  $self->warn('problem with "$command" command');
                  return;
            }
    }
  }

  return;
}

1; #required for Perl modules
