@{
Profile for testing main aii-server optioins
@}
object template aii-options;

function pkg_repl = { null; };
include 'components/aiiserver/config';
'/software/components/aiiserver/dependencies' = null;

# Required for successful compilation as ncm-aiiserver
# is registered for changes to ncm-ccm configuration.
'/software/components/ccm' = dict();

prefix '/software/components/aiiserver/aii-shellfe';
'cachedir' = '/aii/cache/dir';
'ca_dir' = '/ca/dir';
'ca_file' = 'ca_file';
'cdburl' = 'https://aii.example.org/cdb';
'cert_file' = 'cert_file';
'grub2_efi_kernel_root' = '/quattor';
'grub2_efi_linux_cmd' = 'linux';
'key_file' = 'cert_key_file';
'lockdir' = '/aii/locks';
'logfile' = '/aii/aii.log';
'nbpdir' = '/osinstall/nbp';
'nbpdir_grub2' = '/osinstall/grub2';
'osinstalldir' = '/osinstall';
'profile_format' = 'json';
'use_fqdn' = true;

prefix '/software/components/aiiserver/aii-dhcp';
'dhcpconf' = '/my/dhcp/conf';
'restartcmd' = '/my/dhcp/restartcmd';
'norestart' = true;

