#${PMpre} NCM::Component::interactivelimits${PMpost}

use parent qw(NCM::Component);
use Readonly;
use Fcntl qw(:seek);

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

# interactivelimits config file
Readonly my $CONFIGFILE => '/etc/security/limits.conf';
Readonly my $VALUESPATH => '/software/components/interactivelimits/values';

sub Configure
{

    my ($self, $config) = @_;

    # Simple checking first
    unless ($config->elementExists($VALUESPATH)) {
        $self->error("cannot get $VALUESPATH");
        return;
    }

    my $limits_values_ref = $config->getElement($VALUESPATH) ;

    my $fh = CAF::FileEditor->new($CONFIGFILE, log => $self, backup => ".old");

    foreach my $all_limits_array ($limits_values_ref->getList()) {

        # See /etc/security/limits.conf for explanation of these
        # <domain> <type> <item> <value>
        my ($domain, $type, $item, $value) = (undef, undef, undef, undef);

        my @limits_line_array = $all_limits_array->getList();
        $domain = $limits_line_array[0]->getValue();
        $type   = $limits_line_array[1]->getValue();
        $item   = $limits_line_array[2]->getValue();
        $value  = $limits_line_array[3]->getValue();
        unless ((defined $domain)
                and (defined $type)
                and (defined $item)
                and (defined $value)
                and ($domain =~ /^\S+$/o)
                and ($type =~ /^\S+$/o)
                and ($item =~ /^\S+$/o)
                and ($value =~ /^\S+$/o)) {
            $self->error("one of the limits <domain> <type> <item> <value> is missing");
            return;
        }

        # Fix the strings so that they can be used for regex
        (my $domainre = $domain) =~ s/([\*\?])/\\$1/g;
        (my $typere   = $type)   =~ s/([\*\?])/\\$1/g;
        (my $itemre   = $item)   =~ s/([\*\?])/\\$1/g;
        (my $valuere  = $value)  =~ s/([\*\?])/\\$1/g;

        # add_or_replace_lines does a seek to begin first
        $fh->add_or_replace_lines(
            '#*\s*'.$domainre.'\s+'.$typere.'\s+'.$itemre.'\s+\S+',
            '^\s*'.$domainre.'\s+'.$typere.'\s+'.$itemre.'\s+'.$valuere,
            sprintf("%-20s %-10s %-15s %s\n", $domain, $type, $item, $value),
            SEEK_END, 0, # add at the end
            );
    }
    $fh->close();


    return;
}

1;
