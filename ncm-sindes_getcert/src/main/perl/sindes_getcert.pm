# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# sindes_getcert component
#
# SINDES getcert config file
#
#
# For license conditions see http://www.eu-datagrid.org/license.html
#
#######################################################################

package NCM::Component::sindes_getcert;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
use LC::File qw(copy file_contents);

##########################################################################
sub Configure {
##########################################################################
    my ($self,$config)=@_;
    
    my $base = "/software/components/sindes_getcert";
    my $th = $config->getElement("$base")->getTree();
    
    my $destfile = "/etc/sindes/get-cert.conf";
    
    ## This should be equal to the sindes hook for AII
    ## simple overwriting of file
    my $txt = <<EOF;
# Https server
HTTP_SEL="$th->{protocol}"
HTTPS_SERVER="$th->{server}"
    
RENEW_CERT_PORT=$th->{renew_cert_port}
NEW_CERT_PORT=$th->{new_cert_port}

#domain name, to be removed from the hostname if it's a FQDN
DOMAIN_NAME="$th->{domain_name}"
    
#login/passwd for first certificate request.
# /!\ beware of chicken & egg problem here.
USER=
PASSWD=
USE_PASSWD=0


# Organisation and Unit:
CRT_O="$th->{x509_O}"
CRT_OU="$th->{x509_OU}"
    
# RSA or DSA ?
USE_RSA=1
KEY_LENGTH=1024
    
# usefull for program that needs to key+crt in a single pem file, eg curl
CREATE_PEM=1
    
URL_NEW_SUFFIX="/newcert/"
URL_RENEW_SUFFIX="/renewcert/"
    
OPENSSL=openssl
CURL=curl
##CA_CERT_FILE="$th->{cert_dir}/$th->{ca_cert}"
CA_CERT_DIR="$th->{cert_dir}"
    
# if USE_TMP_FILES != "" then 5 following var will
TMP_DIR=/var/tmp/get-crt-XXXXXX
    
CRT_FILE="client.crt"
PEM_FILE="client_test.pem"
TMP_CONFIG="client.ssl.config"
KEY_FILE="client.key"
CSR_FILE="client.csr"
    
# do we install the resulting certificate?
# if so, where? (=-1 indicates we don't want to install this one)
INSTALL_DIR=$th->{cert_dir}
CLIENT_CERTIFICATE_PEM=$th->{cert_dir}/$th->{client_cert}
CLIENT_PRIVATE_KEY_PEM=$th->{cert_dir}/$th->{client_key}
CLIENT_CERTIFICATE_KEY_PEM=$th->{cert_dir}/$th->{client_cert_key}
    
# this one should not be set as ca is _constant_, it should come from an RPM
CA_CERTIFICATE_PEM=-1
    
# if true, will try to overwrite already existing files /!\ dangerous!
INSTALL_OVERWRITE=0
    
    
EOF
    my $changes = LC::Check::file(
                                $destfile,
                                backup   => ".old",
                                contents => $txt
    );
    ## See filecopy how to deal with changes properly!! 

    return;
}

##########################################################################
sub Unconfigure {
##########################################################################
}


1; #required for Perl modules
