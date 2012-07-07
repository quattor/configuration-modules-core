# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::sshkeys;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use EDG::WP4::CCM::Element;


local(*DTA);


##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;

    # Define paths for convenience. 
    my $base = "/software/components/sshkeys";

    # Get the configuration base path. 
    my $cfgpath = '/etc/ssh';
    if ($config->elementExists($base.'/configpath')) {
        $cfgpath = $config->getValue('$base/configpath');
    }

    # Files to modify.
    my %fnames = ('rsa1' => "$cfgpath/ssh_host_key", 
                 'rsa'  => "$cfgpath/ssh_host_rsa_key",
                 'dsa'  => "$cfgpath/ssh_host_dsa_key"); 

    # Fill each of the files and set the permissions appropriately. 
    foreach (('rsa1','rsa','dsa')) {
        my $public = $config->getValue("$base/$_/public");
        my $private = $config->getValue("$base/$_/private");

        # Private key.
        my $fname = $fnames{$_};
        open FH, ">$fname";
        print FH $private . "\n";
        close FH;
        chmod 0600, $fname;
        chown 0,0, $fname;

        # Public key. 
        $fname = "$fname.pub";
        open FH, ">$fname";
        print FH $public . "\n";
        close FH;
        chmod 0644, $fname;
        chown 0,0, $fname;
    }

    # Create the known hosts file. 
    my $contents = '';
    my $index = 0;
    my @hostlist;
    while ($config->elementExists("$base/knownhosts/$index")) {
        @hostlist = ();
        my $element = $config->getElement("$base/knownhosts/$index/hostnames");
        my @elements = $element->getList();
        foreach my $e (@elements) {
            push @hostlist, $e->getValue();
        }

        my $key = $config->getValue("$base/knownhosts/$index/key");

        $contents .= join(',',@hostlist) . " $key\n";

        $index++;
    }

    # The complete known hosts file. 
    my $fname = "$cfgpath/ssh_known_hosts";
    if ($contents ne '') {
        open FH, ">$fname";
        print FH $contents;
        close FH;
        chmod 0644, $fname;
        chown 0,0, $fname;
    } elsif (-e $fname) {
        unlink $fname;
    }


    $self->warn("error running sshkeysig") if $?;
    
    return 1;
}

1;      # Required for PERL modules
