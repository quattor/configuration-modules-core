# ${license-info}
# ${developer-info}
# ${author-info}

# NCM::diskless_server - NCM diskless server configuration component
#
################################################################################


package NCM::Component::diskless_server;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use NCM::Check;
use vars qw(@ISA $EC $this_app);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use LC::File qw(copy remove move);
use LC::Check;
use CAF::Process;
use CAF::FileEditor;

#few declarations
my @nodes;
#define path
my $base = "/software/components/diskless_server";
#
# FIXME: in a future release all aii related stuff should be removed
#
#command
my $aii_command = "/usr/sbin/aii-shellfe";

my %dhcpTag = (bootdevice => '',
    hardware => 'hardware ethernet',
    ipnumber => 'fixed-address' ,
    nextserver => 'next-server',
    filename => 'filename',
    rootpath => 'option root-path'
    );

sub Configure {
    my($self,$config) = @_;
    unless($config->elementExists($base)){
        return $self->error("diskless component is not defined");
    }
    #
    #Add subnet entries in dhcpd.conf
    #loop through dhcp subnets and add them in the config file
    #list of subnets,_subnet list in the path,options normal list.
    if($config->elementExists($base."/dhcp")){
        my @entries;
        my $method=$config->getElement($base."/dhcp");
        while ( $method->hasNextElement() ) {
            my $element=$method->getNextElement();
            my $path=($element->getPath())->toString();
            my $rt_str=$self->dhcpdGetSubnetInfo($config,$path);
            push @entries,$rt_str;
        }
        $self->dhcpdWrite($config,@entries);
    }
    #
    # get list of nodes
    #
    if($config->elementExists($base."/nodes")){
        my $element = $config->getElement($base."/nodes");
        my @ref_list = $element->getList();
        #still references get the values
        foreach(@ref_list){
            $_=$_->getValue();
            #don't keep it local
            push @nodes,$_;
        }
    }
    else{
        $self->error("No nodes defined");
        return 1;
    }
    # if we have a path /software/components/diskless_server/dhcp_clients, we have all
    # info we need in our profile (and dhcpdWrite took care of that), 
    # and we do not need to use aii any more...
    #
    if(!$config->elementExists($base."/dhcp_clients")){
        #AII populates dhcpd.conf
        #get cdb url and profile prefix
        my $cdburl=$config->getValue($base."/aii/cdb");
        my $prefix=$config->getValue($base."/aii/prefix");
        my $timeout;
        if ( $config->elementExists($base."/aii/timeout") ){
            $timeout = $config->getValue($base."/aii/timeout");
        }
        else{
            $timeout = 60;
        }
        #call aii
        $self->debug(2,"going to call aii_dhcp_config");
        $self->aii_dhcp_config($cdburl,$prefix,$timeout,@nodes);
    }
    # FIXME (or wait that TUV fixes pxeos error reporting?
    #check if NFS is running and our server is exported.
    #Also check if anaconda.busybox is installed
    #pxeos won't create the image otherwise and won't give an
    #error message
    #now do the pxeos and pxeboot for these nodes..
    if($config->elementExists($base."/do_pxeos") && $config->getValue($base."/do_pxeos") eq "true") {
        my $rtrn_val=$self->pxe_config($config,$base);
        $self->debug(2,"pxe_config returned : $rtrn_val");
        if($rtrn_val==-1){
            $self->error("pxeos failed, cannot continue with installation of nodes.");
            &cleanup;
            return 1;
        }
    }
    # update shared root filesystem
    if($config->elementExists($base."/protonode_profile")) {
        my $f_path=$config->getValue($base."/pxe/image");
        my $clientUrl = $config->getValue($base."/protonode_profile");
        my $sillyCheck = "$clientUrl";
        $sillyCheck =~ s/\$/\\\$/g;
        $self->debug(2,"$0: sillyCheck $sillyCheck");
        my $chroot_path = "$f_path/root";
        my $ccmConfFile = "$chroot_path/etc/ccm.conf";
        my $fh = CAF::FileEditor->open ($ccmConfFile, log => $self);
        my $ref_to_contents = $fh->string_ref;
        $$ref_to_contents =~ s/^(profiles\s*).*(\s*)/$1$clientUrl$2/;
        $fh->close();
#         if (! -e $ccmConfFile) {
#             $self->debug(4,"checking $ccmConfFile (clientUrl : $clientUrl)\n");
#             my $changes+=NCM::Check::lines($ccmConfFile,
#                 linere=>"profile .*",
#                 goodre=>"profile $sillyCheck",
#                 good  =>"profile $clientUrl"
#                 );
#         }
        my($stdout,$stderr);
        $self->info("$0: chrooting ccm-fetch on $chroot_path");
        CAF::Process->new(
            [ "/usr/sbin/chroot", $chroot_path, "/usr/sbin/ccm-fetch" ],
            timeout => 300,
            stdout => \$stdout,
            stderr => \$stderr,
            log => $self
            )->run();
        if ( $stdout ) {
            $self->debug(5, "ccm-fetch on $chroot_path command output produced:");
            $self->debug(5, $stdout);
        }
        if ( $stderr ) {
            $self->debug(5, "ccm-fetch on $chroot_path command ERROR produced:");
            $self->debug(5, $stderr);
        }
    
        $self->info("$0: chrooting ncm-ncd --co --all on $chroot_path");
        CAF::Process->new(
            [ "/usr/sbin/chroot", $chroot_path, "/usr/sbin/ncm-ncd", "--co", "--all" ],
            timeout => 300,
            stdout => \$stdout,
            stderr => \$stderr,
            log => $self
        )->run();
        if ( $stdout ) {
            $self->debug(5, "ncm-ncd --co --all on $chroot_path command output produced:");
            $self->debug(5, $stdout);
        }
        if ( $stderr ) {
            $self->debug(5, "ncm-ncd --co --all on $chroot_path command ERROR produced:");
            $self->debug(5, $stderr);
        }
    }

    #now create the pxe files
    $self->info("$0: going to call pxeboot_config");
    $self->pxeboot_config($config,$base,@nodes);
    
    # create file that contains the hostname of the diskless server
    $self->add_dlsnfile($config,$base);
    #create files.custom
    if($config->elementExists($base."/rwfiles")){
        $self->add_rwfiles($config,$base);
    }
    # correct profile URL in /etc/ccm.conf of clients
    if($config->elementExists($base."/client_profiles")){
        $self->setClientProfileUrl($config,$base);
    }
    # correct prompt in /root/.bashrc of clients ("chrooted" -> "root")
    $self->setClientRootPrompt($config,$base,@nodes);
    # correct hostname in /etc/sysconfig/network of clients
    $self->setClientHostname($config,$base,@nodes);
    #everything seems to have worked fine,restart the dhcp server
    &cleanup();
}

sub add_rwfiles{
    my($self,$config,$path)=@_;
    my $element=$config->getElement($path."/rwfiles");
    my @f_list=$element->getList();
    my ($entry, $f_values);
    #still references,get values.
    foreach $entry (@f_list){
        $f_values .= $entry->getValue()."\n";
    }
    #Get the directory of OS image
    my $f_path=$config->getValue($path."/pxe/image");
    #files.custom directory
    $f_path =~ s/\/\z//;
    $f_path .= "/snapshot";
    my $rwfile=$f_path."/files.custom";
    
    #add the lines
    $self->debug(2,"Entries for files.custom:\n$f_values");
    my $changes = LC::Check::file("$rwfile",
                    contents    => "$f_values",
                    destination => "$rwfile",
                    owner       => 0,
                    mode        => 0644
                    );
    if ( $changes ){
        $self->debug(2,"Changed $rwfile");
    }
}

sub add_dlsnfile{
    my($self,$config,$path)=@_;
    #Get the directory of the clone
    my $f_path=$config->getValue($path."/pxe/image");
    #files.custom directory
    $f_path =~ s/\/\z//;
    my $dlsn_path = $f_path;
    $f_path .= "/root/var";
    my $dlsnfile=$f_path."/diskless_server.name";
    $self->debug(2,"Will add hostname file at : $dlsnfile");
    my $hostname = $config->getValue("/system/network/hostname");
    
    #add the lines
    unless (-e $dlsnfile){
        `touch $dlsnfile`;
    };
    
    
    NCM::Check::lines($dlsnfile,
                    linere=>".*",
                    goodre=>"\^$hostname\$",
                    good=>"$hostname",
                    keep=>"last",
                    add=>"last");
}

sub pxe_config{
    my($self,$config,$path)=@_;
    my @pxeos_cmd=("/usr/sbin/pxeos", "-a");
    my $descro="";
    my $ret_val = 0;
    
    #add description,optional
    if($config->elementExists($path."/pxe/descro")){
        $descro=$config->getValue($path."/pxe/descro");
        push @pxeos_cmd, ("-i", "'$descro'");
    }
    #add protocol
    unless($config->elementExists($path."/pxe/protocol")){
        $self->error("A protocol must be specified");
        return -1;
    }
    my $proto=$config->getValue($path."/pxe/protocol");
    push @pxeos_cmd, ("-p", "$proto");
    
    #it's diskless by default so add -D 1
    push @pxeos_cmd, "-D", "1";
    
    # are we debugging ?
    *this_app = \$main::this_app;
    if ($this_app->option('debug')) {
        push @pxeos_cmd, "--debug";
    }
    
    #add server
    unless ($config->elementExists($path."/pxe/netdev")){
        $self->error("The active network device must be specified");
        return -1;
    }
    my $netdev = $config->getValue($path."/pxe/netdev");
    unless ($config->elementExists("/system/network/interfaces/$netdev/ip")){
        $self->error("There is no ip for device $netdev");
        return -1;
    }
    my $server;
    if ($config->elementExists($path."/pxe/nfs_server")) {
        $server=$config->getValue($path."/pxe/nfs_server");
    } else {
        $server=$config->getValue("/system/network/interfaces/$netdev/ip");
    }
    push @pxeos_cmd, "-s" ,"$server";
    
    #define kernel name
    unless ($config->elementExists($path."/pxe/kernel")){
        $self->error("A kernel name must be specified");
        return -1;
    }
    my $kernel = $config->getValue($path."/pxe/kernel");
    push @pxeos_cmd, "-k", "$kernel";
    
    #define the image directory
    unless($config->elementExists($path."/pxe/image")){
        $self->error("Undefined image directory");
        return -1;
    }
    my $image = $config->getValue($path."/pxe/image");
    push @pxeos_cmd, "-L", "$image";
    
    #specify OS name
    unless($config->elementExists($path."/pxe/name")){
        $self->error("Specify a name for this OS");
        return -1;
    }
    my $os_name=$config->getValue($path."/pxe/name");
    push @pxeos_cmd, "$os_name";
    
    $self->debug(2,"pxe_config: pxeos command would be @pxeos_cmd ");
    #before executing pxeos make sure things have changed..
    #/tftpboot is the standard location that pxe xml file resides
    #first time pxe is run,pxeos.xml doesn't exist
    unless (open(PXEOS_FILE,"/tftpboot/linux-install/pxelinux.cfg/pxeos.xml")){
        $self->debug(2,"pxe_config: no pxeos.xml, will run pxeos command and return");
        $ret_val=$self->run_pxeos(@pxeos_cmd);
        return $ret_val;
    }
    my $px_line="";
    while(<PXEOS_FILE>){
        chomp();
        $px_line.=$_;
    }
    #fix weird characters
        $kernel=~ s!(\.|\*|\+|\?|\|\"/)!\\$1!mg;
    
        if($px_line=~/>.*$kernel.*$image.*Name=\"$os_name\".*\/>/m){
            #same nothing to be done
        $self->info("OS already exists,not updating");
        return 0;
    
    }
    #has changed,remove old files and rerun
    elsif($px_line=~/<OperatingSystems>\s*<\/OperatingSystems>/){
        $self->debug(2,"pxe_config: config file exists,no OS defined, will run pxeos command and return");
        $ret_val=$self->run_pxeos(@pxeos_cmd);
        return $ret_val;
    }
    elsif($px_line=~/Name=\"$os_name\"/mg){
        unless($ret_val=$self->del_pxeos($os_name)){
            $self->warn("deletion of the $os_name OS failed.Will try to run pxeos to create a new");
        }
        $self->info("removing old OS and updating");
    
        $ret_val=$self->run_pxeos(@pxeos_cmd);
        return $ret_val;
    }
    else {
        $ret_val=$self->run_pxeos(@pxeos_cmd);
        return $ret_val;
    }
}
sub del_pxeos{
    my($self,$name)=@_;
    my($stdout,$stderr);
    my $ret_val=0;
    CAF::Process->new(
                [ "/usr/sbin/pxeos", "-d", $name ],
                timeout => 100,
                stdout => \$stdout,
                stderr => \$stderr,
                log => $self
                )->run();
    if ( $? >> 8) {
        $self->error("pxeos delete failed: $?");
        $ret_val=-1;
    }
    
    if ( $stdout ) {
        $self->info("pxeos delete command output produced:");
        $self->report($stdout);
    }
    if ( $stderr ) {
        $self->info("pxeos delete command ERROR produced:");
        $self->report($stderr);
    }
    
    return $ret_val;
}
sub run_pxeos{
    my($self,@cmd)=@_;
    my $ret_val=0;
    
    
    #run pxeos command
    my($stdout,$stderr);
    CAF::Process->new(
                [ @cmd ],
                timeout => 300,
                stdout => \$stdout,
                stderr => \$stderr,
                log => $self
                )->run();
    if ( $? >> 8) {
        $self->error("pxeos configure failed: $?");
        $ret_val=-1;
    }
    
    if ( $stdout ) {
        $self->info("pxeos configure command output produced:");
        $self->report($stdout);
    }
    if ( $stderr ) {
        $self->info("pxeos configure command ERROR produced:");
        $self->report($stderr);
    }
    return $ret_val;
}

sub pxeboot_config{
    my($self,$config,$path,@node_list)=@_;
    my ($ramdisk, $os_name, @pxeboot_cmd);
    my @pxeboot_base_cmd=("/usr/sbin/pxeboot", "-a");
    # for the extraction of the boot device from the node profile
    # !!!    will become obsolete soon, kept for compatibility      !!!
    my ( $cm, $cfg, $ele, %nic_list, $nic, $macpath, $mac);
    my $nicpath = '/hardware/cards/nic';
    #
    # Get ramdisk size and OS name from profile of server
    # Network device will be extracted from profile of individual clients
    #
    unless($config->elementExists($path."/pxe/ramdisk")){
        #ramdisk size? too big,slow creation,disk space
        #faster(?) nodes
        $self->info("Ramdisk size not defined using 40mb");
        $ramdisk="40000";
    }
    else{
        $ramdisk=$config->getValue($path."/pxe/ramdisk");
    }
    
    unless ($config->elementExists($path."/pxe/name")){
        return	$self->error("Specify an OS nane to be used");
    }
    $os_name=$config->getValue($path."/pxe/name");
    
    push @pxeboot_base_cmd, "-r", "$ramdisk", "-O", "$os_name";
    
    my $global_append;
    if ($config->elementExists($path."/pxe/append")) {
        my $global_append=$config->getValue($path."/pxe/append");
#         push @pxeboot_base_cmd, "-A", "$append";
    }
    
    #call pxeboot for every node
    my $node;
    my $bootDevice;
    my $nodename;
    foreach $node (@node_list){
        ($nodename) = (split(/\./,$node))[0];
        # determine boot device of the client
        $bootDevice = 0;
        if ( $config->elementExists($path."/dhcp_clients/".$nodename."/bootdevice") ){
            $bootDevice = $config->getValue($path."/dhcp_clients/".$nodename."/bootdevice");
        }
        else {
            # copied from aii-shellfe of aii-server 1.0.42-1
            # create new CacheManager (default cache will be used)
            $cm = EDG::WP4::CCM::CacheManager->new("/tmp/aii/$node");
            
            # get (locked) current configuration
            $cfg = $cm->getLockedConfiguration(0);
            # get list of NICs from profile
            if ($cfg->elementExists($nicpath)) {
                $ele = $cfg->getElement($nicpath);
                if (!$ele->isType(EDG::WP4::CCM::Element::NLIST)) {
                    $self->error("diskless_server: NIC list wrong format "
                            . "from CDB for $node");
                } else {
                    %nic_list = $ele->getHash();
                }
            } else {
                $self->error("diskless_server: unable to get NIC list "
                    . "from CDB for $node");
                next;
            }
            foreach $nic (values %nic_list) {                
                $macpath = $nic->getPath();
                $macpath = $macpath->down('hwaddr');
                
                # get MAC address from profile
                if ($cfg->elementExists($macpath)) {
                    next unless (($cfg->elementExists($nic->getPath()->down('boot'))) && ($cfg->getElement($nic->getPath()->down('boot'))->getValue() eq "true"));
                    $mac = $cfg->getElement($macpath);
                    $mac = $mac->getValue();
                    #
                    # the path looks like "/hardware/cards/nic/DEVICE/..."
                    #
                    $bootDevice = @{$macpath}[3];
                    $self->debug(2,"Will use bootdevice $bootDevice, matching MAC $mac for node $node.");
                } else {
                    $self->error("diskless_server: unable to get MAC address "
                            . "from CDB for $node");
                    next;
                }
            }
        } # end of aii part to find bootDevice...
        if ( !$bootDevice ) {
            $self->error("diskless_server:no boot device found for node $node, skip this node.");
            next;
        }
        
        my $append;
        if ($config->elementExists($path."/dhcp_clients/".$nodename."/pxe_append")) {
            $append=$config->getValue($path."/dhcp_clients/".$nodename."/pxe_append");
        }
        push @pxeboot_base_cmd, "-A", "'$global_append $append'";
        
        #
        # specify a snaphot name to avoid switching between using the snapshot "node" and "node.domain"
#         @pxeboot_cmd = @pxeboot_base_cmd;
#         push @pxeboot_cmd, "-e", "$bootDevice", "--snapshot", "$nodename", "$node";
#         $self->debug(2,"pxeboot command will be: @pxeboot_cmd");
        my($stdout,$stderr);
        my $proc = CAF::Process->new(
                [@pxeboot_base_cmd],
                timeout => 100,
                stdout => \$stdout,
                stderr => \$stderr,
                log => $self
                );
        $proc->pushargs ("-e", "$bootDevice", "--snapshot", "$nodename", "$node");
        $proc->run();
        if ( $? >> 8) {
            $self->error("pxeboot configure failed: $?");
        }
        
        if ( $stdout ) {
            $self->info("pxeboot configure command output produced:");
            $self->report($stdout);
        }
        if ( $stderr ) {
            $self->info("pxeboot configure command ERROR produced:");
            $self->report($stderr);
        }
    }
}

sub aii_dhcp_config{
    my($self,$cdb,$prefix,$timeout,@node_list)=@_;
    my $ret_val;
    #quick and dirty trick to make aii-shellfe work..It always looks for this file
    `/bin/touch /etc/aii-shellfe.conf`;
    #create nodes list file
    #aii restarts dhcpd if configured for every individual host,
    #it could create problems..200 restarts can't be the best..
    my $nodelist_file='/tmp/nodeslist';

    open FH,">$nodelist_file"||die "can't open $nodelist_file $!";

    foreach(@node_list){
        print FH $_."\n";
    }

    close FH;
    #execute aii,will read nodelist file and do the magic..
    my($stdout,$stderr);
    CAF::Process->new(
                [ $aii_command, "--cdburl", $cdb, "--profile_prefix", $prefix, "--configurelist", $nodelist_file, "--noosinstall", "--nonbp"],
                timeout => \$timeout,
                stdout => \$stdout,
                stderr => \$stderr,
                log => $self
                )->run();
    if ( $? >> 8) {
        $self->error("aii configure failed: $?");
        $ret_val=1
    }

    if ( $stdout ) {
        $self->info("aii configure command output produced:");
        $self->report($stdout);
    }
    if ( $stderr ) {
        $self->info("aii configure command ERROR produced:");
        $self->report($stderr);
    }
    # reload does start the service if it is not running already,
    # but the implicit 'stop' will give an error (that we happily ignore)
        # system ("/sbin/service","dhcpd", "restart" );
    return $ret_val;
}

sub dhcpdGetSubnetInfo{
    my ($self,$config,$base)=@_;
    my $entry="";

    unless($config->elementExists($base."/subnet") && $config->elementExists($base."/netmask")){
        $self->Warning("No subnet declared for dhcpd config.");
        return;
    }
    my $subnet = $config->getValue($base."/subnet");
    my $netmask = $config->getValue($base."/netmask");

        #TODO: Add option checking
        #put everything into order
    $entry = "subnet $subnet netmask $netmask {\n";
    if($config->elementExists($base."/options")){
        my $method = $config->getElement($base."/options");
        while($method->hasNextElement()){
            my $element=$method->getNextElement();
            my %tmp_options=$element->getHash();
            #dereference the hash
            foreach (keys %tmp_options){
                $entry .= "\toption $_ ".$tmp_options{$_}->getValue().";\n";
            }
        }
    }
    $entry .= "}\n\n";
#     print $entry;
    return $entry;

}

sub dhcpdWrite{
    my($self,$config,@to_file) = @_;

    #file declarations
    my $template = '/usr/lib/ncm/config/diskless_server//dhcpd.conf.template';
    my $temp_file = '/usr/lib/ncm/config/diskless_server//dhcpd.conf.template'.'.tmp';
    my $conf_file = '/etc/dhcpd.conf';
    #dhcpd.conf will always be rewritten
    # either from the 'template' file, or based on the profile settings
    if ( $config->elementExists($base."/dhcp_header") ){
        open FH,"+>> $temp_file"||die "cannot open $temp_file";
        $self->debug(4,"found dhcp_header path in profile, will use it");
        my $value = $config->getValue($base."/dhcp_header/ddns_update_style");
        print FH "ddns-update-style $value;\n";
        $value = $config->getValue($base."/dhcp_header/unknown_clients");
        print FH "$value unknown-clients;\n";
        $value = $config->getValue($base."/dhcp_header/use_host_decl_names");
        print FH "use-host-decl-names $value;\n";
        if ( $config->elementExists($base."/dhcp_header/search") ){
            print FH "option domain-name \"";
            my $search = $config->getElement($base."/dhcp_header/search");
            my @list=$search->getList();
            my ($entry, $value);
            #still references,get values.
            foreach $entry (@list){
                $value = $entry->getValue();
                print FH "$value ";
            }
            print FH "\";\n";
        } elsif ( $config->elementExists("/system/network/domainname") ){
            $value = $config->getValue("/system/network/domainname");
            print FH "option domain-name \"$value\";\n";
        }
        else{
            $self->error("Neither search list nor domain name found for diskless server.");
        }
        $value = $config->getValue($base."/dhcp_header/log_facility");
        print FH "log-facility $value;\n\n";
    }
    else{
        # no dhcp_header in profile? Use the template
        $self->debug(4,"no dhcp_header path in profile, use template");
        unless(copy($template,$temp_file)){
            $self->error("cannot copy $template to $temp_file");
            return;
        }
        open FH,"+>> $temp_file"||die "cannot open $temp_file";	
    }
    foreach (@to_file){
        print FH;
    }
    if ( $config->elementExists($base."/dhcp_clients")){
        $self->debug(4,"found dhcp_clients path in profile, will use it.");
        my $tag;
        my $clientData;
        my $client = $config->getElement($base."/dhcp_clients");
        my %clientHash = $client->getHash();
        my $clientName;
        my $domainname = "";
        if ( $config->elementExists("/system/network/domainname") ){
            $domainname = ".".$config->getValue("/system/network/domainname");
        }
        foreach $clientName (keys %clientHash){
            $self->debug(5,"extracting dhcp info for client $clientName");
            print FH "host $clientName$domainname {\n";
            my %clientValues = $clientHash{$clientName}->getHash();
            foreach $tag (keys %clientValues){
                my $value = $clientValues{$tag}->getValue();
                $self->debug(5,"found tag $tag with value $value");
                if ( "$tag" eq "filename" or "$tag" eq "rootpath" ){
                    print FH "\t$dhcpTag{$tag} \"$value\";\n";
                }
                elsif ( "$tag" eq "options" ){
                    print FH "\t$value;\n";
                }
                elsif ( "$tag" ne "bootdevice" ){
                    print FH "\t$dhcpTag{$tag} $value;\n";
                }
            }
            print FH "}\n\n";
        }
    }
    close FH || die "can't close $!";
    my $changes += LC::Check::file("$conf_file",
                    source      => "$temp_file",
                    destination => "$conf_file",
                    owner       => 0,
                    mode        => 0644
                    );
    if ( $changes ) {
        $self->debug (3, "dhcpd.conf changed, will restart dhcpd.");
        CAF::Process->new (["/sbin/service", "dhcpd", "restart"], log => $self)->run();
    }
    &cleanup;
    return;
}


sub setClientProfileUrl(){
    my ($self,$config,$base) = @_;
    my $client = $config->getElement($base."/client_profiles");
    my %clientHash = $client->getHash();
    my ($clientName, $ccmConfFile, $sillyCheck, $domainName);
    my $snapshotBaseDir = $config->getValue($base."/pxe/image") . "/snapshot";
    my $changes = 0;
    foreach $clientName (keys %clientHash){
        $self->debug(4,"extracting profile info for client $clientName");
        my $clientUrl = $clientHash{$clientName}->getValue();
        $self->debug(4,"found URL $clientUrl\n");
        $sillyCheck = "$clientUrl";
        $sillyCheck =~ s/\$/\\\$/g;
        $ccmConfFile = "$snapshotBaseDir/$clientName/etc/ccm.conf";
        if ( -e $ccmConfFile) {
            $self->debug(4,"checking $ccmConfFile\n");
            $changes+=NCM::Check::lines($ccmConfFile,
                linere=>"profile .*",
                goodre=>"profile $sillyCheck",
                good  =>"profile $clientUrl"
                );
        }
        ##
        ## FIXME: This should be obsolete, now that we use the --snapshot option with pxeboot
        ##
        # I can't imagine that someone would have the client in another domain...
        $domainName = $config->getValue("/system/network/domainname");
        $ccmConfFile = "$snapshotBaseDir/$clientName.$domainName/etc/ccm.conf";
        if ( -e $ccmConfFile) {
        $self->debug(4,"checking $ccmConfFile\n");
                $changes+=NCM::Check::lines($ccmConfFile,
                        linere=>"profile .*",
                        goodre=>"profile $sillyCheck",
                        good  =>"profile $clientUrl"
                        );
        }
    }
    $self->debug(4,"Changed $changes ccm.conf files");
}


sub setClientRootPrompt(){
    my ($self,$config,$base,@nodes) = @_;
    my $node;
    my ($clientName, $bashrcFile, $domainName);
    my $snapshotBaseDir = $config->getValue($base."/pxe/image") . "/snapshot";
    my $changes = 0;
    foreach $node (@nodes){
        ($clientName) = (split(/\./,$node))[0];
        $bashrcFile = "$snapshotBaseDir/$clientName/root/.bashrc";
        if ( -e $bashrcFile) {
            $self->debug(4,"checking $bashrcFile\n");
            $changes+=NCM::Check::lines($bashrcFile,
                linere=>"export PS1=.*",
                goodre=>"export PS1=\"\\[root\\@\\\\h \\\\W\\]\\\$ \\\"",
                good  =>"export PS1=\"\[root\@\\h \\W\]\$ \""
                );
        }
        ##
        ## FIXME: This should be obsolete, now that we use the --snapshot option with pxeboot
        ##
        # I can't imagine that someone would have the client in another domain...
        $domainName = $config->getValue("/system/network/domainname");
        $bashrcFile = "$snapshotBaseDir/$clientName.$domainName/root/.bashrc";
        if ( -e $bashrcFile) {
        $self->debug(4,"checking $bashrcFile\n");
                $changes+=NCM::Check::lines($bashrcFile,
                        linere=>"export PS1=.*",
            goodre=>"export PS1=\"\\[root\\@\\\\h \\\\W\\]\\\$ \\\"",
            good  =>"export PS1=\"\[root\@\\h \\W\]\$ \""
                        );
        }
    }
    $self->debug(4,"Changed $changes bashrc files");
}

sub setClientHostname(){
    my ($self,$config,$base,@nodes) = @_;
    my $node;
    my ($clientName, $bashrcFile, $domainName);
    my $snapshotBaseDir = $config->getValue($base."/pxe/image") . "/snapshot";
    my $changes = 0;
    foreach $node (@nodes){
        ($clientName) = (split(/\./,$node))[0];
        my $networkFile = "$snapshotBaseDir/$clientName/etc/sysconfig/network";
        if ( -e $networkFile) {
            $self->debug(4,"checking $networkFile\n");
            $changes+=NCM::Check::lines($networkFile,
                        linere=>"HOSTNAME=.*",
                        goodre=>"HOSTNAME=$clientName",
                        good  =>"HOSTNAME=$clientName",
                        add   =>"first"
                        );
        }
    }
    $self->debug(4,"Changed $changes sysconfig/network files");
}


sub cleanup{
    remove('/usr/lib/ncm/config/diskless_server//dhcpd.conf.template'.'.tmp');
    remove('/tmp/nodeslist');
}
