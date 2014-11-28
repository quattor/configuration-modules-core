# ${license-info}
# ${developer-info}
# ${author-info}

#
# interactivelimits - NCM interactive limits configuration component
#
# generates the interactivelimits configuration file /etc/security/limits.conf
#
################################################################################

package NCM::Component::interactivelimits;
#
# a few standard statements, mandatory for all components
#
use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

use NCM::Check;

# interactivelimits config file
my $ConfigFile = '/etc/security/limits.conf';
my $ValuesPath = '/software/components/interactivelimits/values';

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  # Simple checking first
  unless ($config->elementExists($ValuesPath)) {
    $self->error("cannot get $ValuesPath");
    return;
  }

  my $limits_values_ref = $config->getElement($ValuesPath) ;

  foreach my $all_limits_array ($limits_values_ref->getList()) {

    # See /etc/security/limits.conf for explanation of these
    # <domain> <type> <item> <value>
    my ($domain, $type, $item, $value) = (undef, undef, undef, undef);

    my @limits_line_array = $all_limits_array->getList();
    $domain = $limits_line_array[0]->getStringValue();
    $type   = $limits_line_array[1]->getStringValue();
    $item   = $limits_line_array[2]->getStringValue();
    $value  = $limits_line_array[3]->getStringValue();
    unless ((defined $domain) and (defined $type) and (defined $item) and (defined $value) and ($domain =~ /^\S+$/o) and ($type =~ /^\S+$/o) and ($item =~ /^\S+$/o) and ($value =~ /^\S+$/o)) {
      $self->error("one of the limits <domain> <type> <item> <value> is missing");
      return;
    }

    # Fix the strings so that they can be used for regex
    (my $domainre = $domain) =~ s/([\*\?])/\\$1/g;
    (my $typere   = $type)   =~ s/([\*\?])/\\$1/g;
    (my $itemre   = $item)   =~ s/([\*\?])/\\$1/g;
    (my $valuere  = $value)  =~ s/([\*\?])/\\$1/g;

    NCM::Check::lines($ConfigFile,
            backup => ".old",
            linere => '#*\s*'.$domainre.'\s+'.$typere.'\s+'.$itemre.'\s+\S+',
            goodre => '\s*'.$domainre.'\s+'.$typere.'\s+'.$itemre.'\s+'.$valuere,
            good   => sprintf("%-20s %-10s %-15s %s",$domain,$type,$item,$value),
            add    => 'last'
    );

  }

  return;
}

1; # required for Perl modules
