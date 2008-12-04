# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# sysctl component
#
# generates the sysctl configuration file, /etc/sysctl.conf
#
#
# For license conditions see http://www.eu-datagrid.org/license.html
#
#######################################################################

package NCM::Component::sysctl;
#
# a few standard statements, mandatory for all components
#
use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element qw(unescape);

use NCM::Check;
use LC::Process qw(trun);

# For convenience
my $base = '/software/components/sysctl';


##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  # Load config into a hash
  my $sysctl_config = $config->getElement($base)->getTree();
  my $variables = $sysctl_config->{variables};

  my $configFile = $sysctl_config->{confFile};
  unless ( $configFile ) {
    $self->error('Sysctl configuration file not defined');
  }

  my $sysctl_exe = $sysctl_config->{command};
  unless ( $sysctl_exe ) {
    $self->error('Sysctl command not defined');
  }

  unless (-x $sysctl_exe) {
     $self->error ("$sysctl_exe not found");
     return;
  }

  unless (-e $configFile && -w $configFile) {
      $self->warn('Sysctl configuration file does not exist or is not writable ('.$configFile.')');
      return;
  }

  # In v1, component was schema-less and keys were at the top-level).
  # If compatibility enabled (not recommended), check the key is not already defined
  # in 'variables' hash, either escaped or unescaped.
  if ( $sysctl_config->{'compat-v1'} ) {
    for my $key (sort(keys(%{$sysctl_config}))) {
      unless ($key =~ /^(active|code|dependencies|dispatch|register_change|version|variables|confFile|command)$/) {
        $key =~ s/DOT/\./mg;
        $key =~ s/DASH/-/mg;
        my $key_e = $self->escape($key);
        if ( $variables->{$key} || $variables->{$key_e} ) {
          $self->warn("Variable $key defined in variables list. Ignoring v1 compatibility definition.");
        } else {
          # No need to escape old format keys
          $variables->{$key} = $sysctl_config->{$key};
        }
      }
    }
  }

  # Process variables

  my $changes = 0;
  for my $key_e (sort(keys(%{$variables}))) {
    my $key = $self->unescape($key_e);
    my $val = $variables->{$key_e};
    my $status = NCM::Check::lines($configFile,
                                   backup => ".old",
                                   linere =>'#?\s*' . $key . '\s*=.*',
                                   goodre => '\s*'. $key .'\s*=\s*'. $val,
                                   good   => "$key = $val",
                                   add => 'last'
                                  );
    if ( $status < 0 ) {
      $self->error("Failed to update sysctl variable $key (value=$val)");
    }
    $changes += $status;
  }

  #
  # execute /sbin/sysctl -p if any change made to sysctl configuration file
  #
  if ( $changes ) {
    unless (LC::Process::trun(300,"$sysctl_exe -p")) {
      $self->error('Failed to load sysctl settings from $configFile');
      return;
    }
  }
}


# Helper function to escape characters.
# Based on PAN compiler escape() function.

sub escape($) {
  my ($self,$str) = @_;
  my $newstr;

  for (my $i=0; $i<length($str); $i++) {
    my $c = substr($str,$i,1);
    my $digit = ord($c) - hex(36);
    if ( ($digit < 0) || (($digit <9) && ($i=0)) ) {
      $newstr .= '_' . sprintf("%01x",ord($c));
    } else {
      $newstr .= $c;
    }
  }

  return ($newstr);
};


1; # required for Perl modules
