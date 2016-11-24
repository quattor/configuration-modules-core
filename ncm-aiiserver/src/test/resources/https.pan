@{ Template for testing https configuration with ncm-aiiserver }

object template https;

function pkg_repl = { null; };

include 'components/aiiserver/config';

'/software/components/aiiserver/dependencies' = null;


prefix '/software/components/aiiserver/aii-dhcp';
'dhcpconf' = '/dhcp/conf/quattor/dhcpd.conf.aii';
'restartcmd' = '/dhcp/scripts/dhcp_rebuild_db';

prefix '/software/components/aiiserver/aii-shellfe';
'cdburl' = 'http://quattor.web.lal.in2p3.fr/profiles';
'nbpdir' = '/tftpboot/quattor/pxelinux.cfg';
'osinstalldir' = '/www/quattor/ks';
'profile_format' = 'json';
'use_fqdn' = true;
'ca_dir' = '/etc/aii/iwin';


prefix '/software/components/ccm';
'ca_dir' = '/etc/grid-security/certificates';
'cert_file' = 'my-host-cern.pem';
'key_file' = 'my-host-key.pem';
