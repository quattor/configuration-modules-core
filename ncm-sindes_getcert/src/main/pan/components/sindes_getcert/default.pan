# ${license-info}
# ${developer-info}
# ${author-info}

template components/sindes_getcert/default;

variable SINDES_SERVER ?= QUATTOR_SERVER;
variable SINDES_SERVER_SHORT ?= {
	m = matches(SINDES_SERVER,"^(.+)(\\."+DEFAULT_DOMAIN+")$");
    if (length(m) == 3) {
        if (is_shorthostname(m[1])) {
            return(m[1]);
        } else {
            error("failed to extract SINDES_SERVER_SHORT: invalid hostname ("+m[1]+") from SINDES_SERVER "+SINDES_SERVER+" with domain "+DEFAULT_DOMAIN);
        };
    } else {
    	error("failed to extract SINDES_SERVER_SHORT from SINDES_SERVER "+SINDES_SERVER+" with domain "+DEFAULT_DOMAIN);
    };
    m[1];
};

## SINDES crt
## organisation name andunit
## MUST match the value in the sindes servers ca.config file
variable SINDES_SITE_CRT_O ?= undef;
variable SINDES_SITE_CRT_OU ?= "GRID";
## SINDES rpm name variables
variable SINDES_SITE_CA_RPM_NAME ?= "SINDES-ca-certificate-"+SINDES_SERVER_SHORT;
variable SINDES_SITE_CA_RPM_VERSION ?= undef;

variable SINDES_SITE_CA_CERT_NAME ?= "ca-" + SINDES_SERVER + ".crt";

## You need a direct route from node to SINDES_SERVER
## This is the gw to add##  route -add host SINDES_SERVER gw AII_SINDES_SERVER_DIRECT_GATEWAY
## this is only set here for aii, you also need to add it to your normal network setup.
##
variable AII_SINDES_SERVER_DIRECT_GATEWAY ?= null;

############################################################
############################################################


##
## include rpms
##
## SINDES-client rpm

"/software/packages"={
        SELF[escape("SINDES-client")] = nlist();
        SELF[escape(SINDES_SITE_CA_RPM_NAME)] = nlist();
        SELF;
};

#### Sindes get-cert.conf options:

prefix "/software/components/sindes_getcert";

## protocol, most probably https://
"protocol" = "https://";
## server, sindes-server with port
"server" = SINDES_SERVER;
"new_cert_port" = 444;
"renew_cert_port" = 445;
## domainname
## WARNING: for get-cert.conf, this value can be empty when using FQDN
## BUT then it will break file transfer when used elsewhere.
"domain_name" = "";
## organisation name, MUST match the value in the sindes servers ca.config file
"x509_O" = SINDES_SITE_CRT_O;
## organisation unit, MUST match the value in the sindes servers ca.config file
"x509_OU" = SINDES_SITE_CRT_OU;
## base directory for the certs and keys (can't be empty?)
"cert_dir" = "/etc/sindes/certs";
## private key name in pem
"client_key" = "client_key.pem";
## private cert name in pem
"client_cert" = "client_cert.pem";
## private cert + key name in pem (this one is used by curl)
"client_cert_key" = "client_cert_key.pem";
## CA crt name in crt
"ca_cert" = SINDES_SITE_CA_CERT_NAME;
"ca_cert_rpm" = SINDES_SITE_CA_RPM_NAME;


## make sure there's a direct link from client to server
"aii_gw" = AII_SINDES_SERVER_DIRECT_GATEWAY;

##
## add ccm values
##
prefix "/software/components/ccm";

"key_file" ?= value("/software/components/sindes_getcert/cert_dir") + "/" + value("/software/components/sindes_getcert/client_key");
"cert_file" ?= value("/software/components/sindes_getcert/cert_dir") + "/" + value("/software/components/sindes_getcert/client_cert");
"ca_file" ?= value("/software/components/sindes_getcert/cert_dir") + "/" + value("/software/components/sindes_getcert/ca_cert");
"ca_dir" ?= value("/software/components/sindes_getcert/cert_dir");
"world_readable" ?= 0;
