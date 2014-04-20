@{ Template for testing https configuration with ncm-aiiserver }

object template https;

prefix '/software/components/aiiserver';
'active' = true;
'aii-dhcp/dhcpconf' = '/dhcp/conf/quattor/dhcpd.conf.aii';
'aii-dhcp/restartcmd' = '/dhcp/scripts/dhcp_rebuild_db';
'aii-shellfe/cdburl' = 'http://quattor.web.lal.in2p3.fr/profiles';
'aii-shellfe/nbpdir' = '/tftpboot/quattor/pxelinux.cfg';
'aii-shellfe/osinstalldir' = '/www/quattor/ks';
'aii-shellfe/profile_format' = 'json';
'aii-shellfe/use_fqdn' = true;
'dependencies/pre/0' = 'spma';
'dispatch' = true;

prefix '/software/components/ccm';
'ca_dir' = '/etc/grid-security/certificates';
'ca_file' = 'CERN-TCA.pem';
'cert_file' = 'my-host-cern.pem';
'key_file' = 'my-host-key.pem';
