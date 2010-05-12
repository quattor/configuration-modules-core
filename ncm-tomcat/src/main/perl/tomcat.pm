# ${license-info}
# ${developer-info}
# ${author-info}

###############################################################################
# This is 'tomcat.pm', a ncm-tomcat's file
###############################################################################
#
#
###############################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
###############################################################################
#
# Example NCM Component with NVA API config access
#
###############################################################################

package NCM::Component::tomcat;
#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;


use EDG::WP4::CCM::Element;
use EDG::WP4::CCM::Resource;
use XML::Parser;
use Data::Dumper;
use File::Copy;
use CAF::Process;
use LC::Find;

# my $mainconf = "/etc/httpd/conf/httpd.conf";
my $confdir = "/etc/tomcat5";
my $mainconffile = "$confdir/tomcat5.conf";
my $serverxml = "$confdir/server.xml";
my $usersxml = "$confdir/tomcat-users.xml";
my $appconfdir = "$confdir/Catalina/localhost";

my $cdbpath = "/software/components/tomcat/conf";
my $serviceOptPath = "/software/components/tomcat/serviceopt";
# my @sectiondirs = ('VirtualHost', 'Directory', 'Location', 'Files');
# my $sectdirstr = join ('#', "", @sectiondirs, "");

my @ltr = (localtime())[0..5];
my @lt = reverse(@ltr);
$lt[0] += 1900;
$lt[1] += 1;
my $timestamp = join("-", @lt[0..2]) . " " . join(':', @lt[3..5]);


my $header = "<?xml version='1.0' encoding='utf-8'>\n";
 


sub conf_tomcat_xml {

    my $self = shift;
    my $element = shift;
    my $spaces = shift;
    local (*OF) = shift;
    my $prevname = shift;
    my $i;

    my $name = $element->getName();
    my $printname = $name;
    if ($name =~ /^\d+$/ && defined($prevname)) {
        $printname = $prevname;
        $spaces =~ s/    //;
    }
    $self->debug(1, "Element: $name");

    if ($element->isResource()) {

        if ($element->isType(EDG::WP4::CCM::Element::NLIST) ) {

            print OF "$spaces<$printname";
            my %itemhash = $element->getHash();
            my $iter = 0;
            if (exists($itemhash{'attrs'})) {

                my $attrstr = "";
                while ($itemhash{'attrs'}->hasNextElement()) {

                    my $attrelem = $itemhash{'attrs'}->getNextElement();
                    my $attrname = $attrelem->getName();
                    my $attrval = $attrelem->getValue();
                    print OF $iter ? "\n$spaces    "  : " ";
                    $iter++;
                    print OF "$attrname=\"$attrval\"";
                    $self->debug(1, "Attr: $attrname $attrval");
                }
            }
            if (exists($itemhash{'nested'})) {
                my $iter2 = 0;
                while ($itemhash{'nested'}->hasNextElement()) {
                    print OF ">\n" unless $iter2;
                    $iter2++;
                    my $nextelem = $itemhash{'nested'}->getNextElement();
                    $self->conf_tomcat_xml($nextelem, $spaces . "    ", *OF );
                }
                print OF "$spaces" if $iter2;
                print OF "</$printname>\n";
            } else {
                print OF "\n$spaces" if $iter > 1;
                print OF "/>\n";
            }

        } else {
            while ($element->hasNextElement()) {
                my $nextelem = $element->getNextElement();
                $self->conf_tomcat_xml($nextelem, $spaces . "    ", *OF, $name);
            }
        }

    } else {
        my $val = $element->getValue();
        print OF "$spaces<$name>$val</$name>\n";
        $self->debug(1, "Value: $name  $val \n");
    }

    
}


sub conf_tomcat_conf {

    my $self = shift;
    my $element = shift;
    local (*OF) = shift;

    while ($element->hasNextElement()) {
        
        my $confelem = $element->getNextElement();
        my $name = $confelem->getName();        

        unless ($confelem->isProperty()) {
            $self->error("$name is not expected here") && next;
        }

        print OF "$name=", $confelem->getValue(), "\n";
    
    }


}



sub save_config {

    my ($self, $conffile) = @_;

    if ( -e $conffile && ! -e $conffile. ".orig") {
        move($conffile, $conffile . ".orig")
    } else {
        move($conffile, $conffile . ".ncm_save")
    }

}

sub adjust_ownerships
{
    my ($self) = @_;

    my ($usr, $grp) = (getpwnam('tomcat'))[2,3];

    my $fnd = LC::Find->new();

    $fnd->callback(sub {
		       chown($usr, $grp, $LC::Find::Path);
		   });
    $fnd->find(qw(/usr/share/tomcat5/webapps
		  /etc/tomcat5/Catalina/localhost));
    chmod (0775, '/usr/share/tomcat5/webapps/');
}



sub Configure {

    my ($self,$config)=@_;
    my ($ifRestart);
    $ifRestart = 1;

    $self->error("$cdbpath doesn\'t exist ") && return
        unless $config->elementExists($cdbpath);

    my $element = $config->getElement($cdbpath);

    my $spaces = "";
    while ($element->hasNextElement()) {
        my $confelem = $element->getNextElement();
        my $confname = $confelem->getName();

        my $conffile;
        if ( $confname eq 'mainconf' ) {

            $self->save_config($mainconffile);
            unless (open (OF, ">$mainconffile")) {
                $self->error("Cannot open config file $mainconffile: $!");
                exit;
            }
            # print OF $header;
            $self->conf_tomcat_conf($confelem, *OF); 
            close(OF);

        } elsif ($confname eq 'webapps' ) {
            while ($confelem->hasNextElement()) {

                my $appconfelem = $confelem->getNextElement();
                my $appconfname = $appconfelem->getName();

                $conffile = "$appconfdir/" . lc($appconfname) . ".xml";

                $self->save_config($conffile);
                unless (open (OF, ">$conffile")) {
                    $self->error("Cannot open config file $conffile: $!");
		    exit;
                }
                # print OF $header;
                while ($appconfelem->hasNextElement()) {
                    $self->conf_tomcat_xml($appconfelem->getNextElement(), $spaces, *OF );
                }
                close(OF);

            }
        } else {
            $conffile = "$confdir/" . lc($confname) . ".xml";

            $self->save_config($conffile);
            unless (open (OF, ">$conffile")) {
                $self->error("Cannot open config file $conffile: $!");
                exit;
            }
            # print OF $header;
            $self->conf_tomcat_xml($confelem, $spaces, *OF );
            close(OF);

        }

    }
    if ($config->elementExists($serviceOptPath)) {
        $element = $config->getElement($serviceOptPath);
        while ($element->hasNextElement()) {
            my $elem = $element->getNextElement();
            my $name = $elem->getName();
            if ($name eq 'RestartTomcat') {
                if ($elem->getValue() eq 'true') {
                    $ifRestart = 1;
                } else {
                    $ifRestart = 0;
                }
            }
        }
    }


    # Generating keystore file
    if ( -f '/etc/grid-security/hostkey.pem' || -d '/etc/grid-security/certificates/') {
        my $tomcat_user = `ls /home/ | grep tomcat`;
        $tomcat_user =~  s/\s*//g;
        my $keystore_file = "/home/$tomcat_user/.keystore";
        my $keystore_comm = `openssl pkcs12 -export -in  /etc/grid-security/hostcert.pem -inkey /etc/grid-security/hostkey.pem  -out $keystore_file -name tomcat  -CApath /etc/grid-security/certificates/  -caname root -chain -passout pass:changeit`
	    unless -f $keystore_file;
    }

    $self->adjust_ownserships();

    if ($ifRestart) {
	CAF::Process->new([qw(/etc/init.d/tomcat5 stop)],
			  log => $self)->run();
	CAF::Process->new([qw(/etc/init.d/tomcat5 start)],
			  log => $self)->run();
    }

    return 1;
}

1;				# Perl module requirement.

