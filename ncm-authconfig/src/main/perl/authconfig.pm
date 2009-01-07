# ${license-info}
# ${developer-info}
# ${author-info}

#
# authconfig - authconfig NCM component
#
################################################################################

package NCM::Component::authconfig;

use strict;
use NCM::Component;
use LC::Process;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use File::Path;

use EDG::WP4::CCM::Element;

# prevent authconfig from trying to launch in X11 mode
delete($ENV{"DISPLAY"});

local(*DTA);

##########################################################################
sub getValueDefault() {
##########################################################################
    my ($config, $pathname, $default) = @_;

    if ($config->elementExists($pathname)) {
        return $config->getValue($pathname);
    } else {
      return $default;
    }
}


##########################################################################
sub build_pam_systemauth($$@) {
##########################################################################

    my ($self, $config, $base) = @_;

    # in the /etc/pam.d/system_auth file, some additional stuff can be 
    # set to allow fine-grained access control

    my $conf = &getValueDefault($config,$base."/conffile","/etc/pam.d/system_auth");
    my $changes=0;

    LC::File::copy($conf,$conf."$$",preserve => 1 );
    
    my $section = $config->getValue($base."/section");

    my $method_elmt=$config->getElement("$base/lines");

    while ( $method_elmt->hasNextElement() ) {
        my $m_elmt=$method_elmt->getNextElement();

        my $m_name=$m_elmt->getName();
        my $m_path=($m_elmt->getPath())->toString();
        my $m_value=$config->getValue($m_path."/entry");
        my $m_order=$config->getValue($m_path."/order");
        
       (my $rem_value=$m_value)=~s/\//\\\//g;
        $rem_value=~s/\$/\\\$/g;
        $rem_value=~s/\s+/\\s+/g;
        $rem_value=~s/\[/\\[/g;
       
	# WARNING: this will result in each .so module only to be used once
        # and argument changes to be considered insignificant to functionality
        #.....not anymore...
		
        (my $linere_value=$m_value)=~/(\S*.so)(.*)/ig;
        $linere_value = $1;
        $linere_value=~s/\$/\\\$/g;
        $linere_value=~s/\//\\\//g;
			
        my $newline=sprintf("%-12s%s",$section,$m_value);

        $changes+= NCM::Check::lines($conf,
            linere => "^#?\\s*$section(.*?)$linere_value.*",
            goodre => "^$section\\s+${rem_value}\\s*",
            good   => "$newline",
            keep   => $m_order,
            add    => $m_order
            );
    }

    if ( $changes ) {
        unlink($conf.".old");
        LC::File::move($conf."$$",$conf.".old");
    } else {
        unlink($conf."$$");
    }

    $self->info("Modified $conf in $changes places");
}

##########################################################################
sub change_cfig_val($$@$$$$){
##########################################################################

    my ($self, $config, $base, $tplelement, $fileconfname, $defaultconfVal, $changeback) = @_;
    my $changes = 0;
    #This could be passed in as a parameter, but this would make the call string even longer
    my $conf = &getValueDefault($config,$base."/conffile","/etc/ldap.conf");

    if ( $config->elementExists($base . $tplelement) ) {
        my $elementVal = $config->getValue($base . $tplelement);
        my $elementValre = quotemeta($elementVal);
        $changes+= NCM::Check::lines($conf,
            linere => "^#?\\s*$fileconfname\\s+.*",
            goodre => "^$fileconfname\\s+$elementValre\\s*",
            good   => "$fileconfname $elementVal",
            keep   => "first",
            add    => "last"
            );
    }

    if ($changeback == 1 &&  ! $config->elementExists($base . $tplelement) ) {
        $changes+= NCM::Check::lines($conf,
            linere => "^#*\\s*$fileconfname\\s.*",
            goodre => "#$fileconfname\\s.*",
            good   => "#$fileconfname $defaultconfVal",
            keep   => "first",
            add    => "last"
            );
    }

    return $changes; # 0 or 1 otherwise we have an error that is not cached

}
                                                                     
##########################################################################
sub build_ldap_config($$@) {
##########################################################################

    my ($self, $config, $base) = @_;


    # from the ldap.conf file, some values are set correctly
    # by the authconfig command. These attributes are
    # "host", "base", "ssl", and "pam_password crypt"

    my $conf = &getValueDefault($config,$base."/conffile","/etc/ldap.conf");
    my $changes=0;
    
    # Make a backup of the file
    LC::File::copy($conf,$conf."$$",preserve => 1 );

    # The distinguished name to bind to the server with.
    $changes +=  change_cfig_val($self, $config, $base, "/binddn", "binddn", "NA", 0);

    # The credentials to bind with.
    $changes +=  change_cfig_val($self, $config, $base, "/bindpw", "bindpw", "NA", 0);

    # The distinguished name to bind to the server with
    # if the effective user ID is root.
    $changes +=  change_cfig_val($self, $config, $base, "/rootbinddn", "rootbinddn", "NA", 0);

    # The port
    $changes +=  change_cfig_val($self, $config, $base, "/port", "port", "NA", 0);

    # Idle timelimit; client will close connections
    # (nss_ldap only) if the server has not been contacted
    # for the number of seconds specified below.
    $changes +=  change_cfig_val($self, $config, $base, "/timeouts/idle", "idle_timelimit", "NA", 0);

    # Bind/connect timelimit
    $changes +=  change_cfig_val($self, $config, $base, "/timeouts/bind", "bind_timelimit", "NA", 0);

    # Search timelimit
    $changes +=  change_cfig_val($self, $config, $base, "/timeouts/search", "timelimit", "NA", 0);

    # Filter to AND with uid=%s
    $changes +=  change_cfig_val($self, $config, $base, "/pam_filter", "pam_filter", "objectclass=posixAccount", 1);

    # Require and verify server certificate (yes/no)
    $changes +=  change_cfig_val($self, $config, $base, "/tls/peercheck", "tls_checkpeer", "no", 1);

    # CA certificates for server certificate verification
    $changes +=  change_cfig_val($self, $config, $base, "/tls/cacertfile", "tls_cacertfile", "/etc/ssl/ca.cert", 1);

    # CA certificates for server certificate verification
    $changes +=  change_cfig_val($self, $config, $base, "/tls/cacertdir", "tls_cacertdir", "/etc/ssl/certs", 1);

    # SSL cipher suite
    # See man ciphers for syntax
    $changes +=  change_cfig_val($self, $config, $base, "/tls/ciphers", "tls_ciphers", "TLSv1", 1);

    # Where to look for the users
    $changes +=  change_cfig_val($self, $config, $base, "/nss_base_passwd", "nss_base_passwd", "", 1);

    # Where to look for groups
    $changes +=  change_cfig_val($self, $config, $base, "/nss_base_group", "nss_base_group", "", 1);

    # Reconnect policy: hard (default) will retry connecting to
    # the software with exponential backoff, soft will fail
    # immediately.
    $changes +=  change_cfig_val($self, $config, $base, "/bind_policy", "bind_policy", "", 1);
    
    # Mappings
    $changes +=  change_cfig_val($self, $config, $base, "/nss_map_objectclass/posixAccount", "nss_map_objectclass posixAccount", "user", 1);
    $changes +=  change_cfig_val($self, $config, $base, "/nss_map_objectclass/shadowAccount", "nss_map_objectclass shadowAccount", "user", 1);
    $changes +=  change_cfig_val($self, $config, $base, "/nss_map_objectclass/posixGroup", "nss_map_objectclass posixGroup", "group", 1);
    $changes +=  change_cfig_val($self, $config, $base, "/nss_map_attribute/uid", "nss_map_attribute uid", "sAMAccountName", 1);
    $changes +=  change_cfig_val($self, $config, $base, "/nss_map_attribute/homeDirectory", "nss_map_attribute homeDirectory", "unixHomeDirectory", 1);
    $changes +=  change_cfig_val($self, $config, $base, "/nss_map_attribute/uniqueMember", "nss_map_attribute uniqueMember", "member", 1);

    # nss_override_attribute_value
    $changes +=  change_cfig_val($self, $config, $base, "/nss_override_attribute_value/unixHomeDirectory", "nss_override_attribute_value unixHomeDirectory", "", 1);
    $changes +=  change_cfig_val($self, $config, $base, "/nss_override_attribute_value/loginShell",        "nss_override_attribute_value loginShell",        "", 1);
    $changes +=  change_cfig_val($self, $config, $base, "/nss_override_attribute_value/gecos",             "nss_override_attribute_value gecos",             "", 1);

    # nss_initgroups_ignoreusers
    $changes +=  change_cfig_val($self, $config, $base, "/nss_initgroups_ignoreusers", "nss_initgroups_ignoreusers", "", 1);

    # The user ID attribute (defaults to uid)
    $changes +=  change_cfig_val($self, $config, $base, "/pam_login_attribute", "pam_login_attribute", "sAMAccountName", 1);
    
    # Netscape SDK SSL options
    if ( $config->elementExists($base . "/ssl")   or
         ( ! $config->elementExists($base . "/tls") and
           ! $config->elementExists($base . "/ssl") ) ) {
      $changes +=  change_cfig_val($self, $config, $base, "/ssl", "ssl", "start_tls", 1);
    }

    # Group to enforce membership of
    $changes +=  change_cfig_val($self, $config, $base, "/pam_groupdn","pam_groupdn","cn=PAM,ou=Groups,dc=example,dc=com",1);

    # Group member attribute
    $changes +=  change_cfig_val($self, $config, $base, "/pam_member_attribute","pam_member_attribute","uniquemember",1);

    # pam_check_service_attr uses ldapns.schema authorizedServiceObject class
    $changes +=  change_cfig_val($self, $config, $base, "/pam_check_service_attr","pam_check_service_attr","no",1);

    # pam_check_host_attr uses account objectclass host attribute
    $changes +=  change_cfig_val($self, $config, $base, "/pam_check_host_attr","pam_check_host_attr","no",1);


    if ( $changes ) {
        unlink($conf.".old");
        LC::File::move($conf."$$",$conf.".old");
    } else {
        unlink($conf."$$");
    }

    $self->info("Modified $conf in $changes places");

    return $changes;
}

##########################################################################
sub build_authconfig_command($$@) {
##########################################################################

    my ($self, $config, $base) = @_;

    my $cmd="authconfig --kickstart";

    if ( &getValueDefault($config,$base."/useshadow","true") eq "true" ) {
      $cmd.=" --enableshadow";
    } else {
      $cmd.=" --disableshadow";
    }

    if ( &getValueDefault($config,$base."/usemd5","false") eq "true" ) {
      $cmd.=" --enablemd5";
    } else {
      $cmd.=" --disablemd5";
    }

    if ( &getValueDefault($config,$base."/usecache","false") eq "true" ) {
      $cmd.=" --enablecache";
    } else {
      $cmd.=" --disablecache";
    }


    # loop over all methods in the configuration and try to
    # recognise them

    my $method_elmt=$config->getElement("$base/method");

    while ( $method_elmt->hasNextElement() ) {
        my $m_elmt=$method_elmt->getNextElement();

        my $m_name=$m_elmt->getName();
        my $m_path=($m_elmt->getPath())->toString();

        if ( $config->getValue($m_path."/enable") ne "true" ) {
            $self->debug(1,"authentication method $m_name set to disabled");
            foreach ( $m_name ) {
#            /afs/   and $cmd.=" --disableafs"; # Removed see email from 11/22/2007
            /ldap/  and $cmd.=" --disableldap --disableldapauth";
            /krb5/  and $cmd.=" --disablekrb5";
            /hesiod/ and $cmd.=" --disablehesiod";
            /smb/   and $cmd.=" --disablesmbauth";
            /nis/   and $cmd.=" --disablenis";
            /files/ and $self->warn("Cannot disable file-based auth");
            }
            next;
        }

        # these methods are now to be enabled

        foreach ( $m_name ) {
        /files/ and do {
        };
#         /afs/ and do {
#             my $afscell=$config->getValue($m_path."/cell");
#             $cmd.=" --enableafs --afscell $afscell";
#         };
        /nis/ and do {
            my $domain=$config->getValue($m_path."/domain");
            my $servers="";
            my $nissrv_elmt=$config->getElement($m_path."/servers");
            while ( $nissrv_elmt->hasNextElement() ) {
                $servers and $servers.=",";
                $servers.=($nissrv_elmt->getNextElement())->getValue();
            }
            $cmd.=" --enablenis --nisdomain $domain --nisserver $servers";
        };
        /krb5/ and do {
            my $realm=$config->getValue($m_path."/realm");
            my $kdcs="";
            my $krbsrv_elmt=$config->getElement($m_path."/kdcs");
            while ( $krbsrv_elmt->hasNextElement() ) {
                $kdcs and $kdcs.=",";
                $kdcs.=($krbsrv_elmt->getNextElement())->getValue();
            }
            my $adminservers="";
            $krbsrv_elmt=$config->getElement($m_path."/adminserver");
            while ( $krbsrv_elmt->hasNextElement() ) {
                $adminservers and $adminservers.=",";
                $adminservers.=($krbsrv_elmt->getNextElement())->getValue();
            }

            $cmd.=" --enablekrb5 --krb5realm $realm --krb5kdc $kdcs";
            $cmd.=" --krb5adminserver $adminservers";
        };
        /smb/ and do {
            my $wg=$config->getValue($m_path."/workgroup");
            my $servers="";
            my $srv_elmt=$config->getElement($m_path."/servers");
            while ( $srv_elmt->hasNextElement() ) {
                $servers and $servers.=",";
                $servers.=($srv_elmt->getNextElement())->getValue();
            }
            $cmd.=" --enablesmbauth --smbworkgroup $wg --smbservers $servers";
        };
        /hesiod/ and do {
            my $rhs=$config->getValue($m_path."/rhs");
            my $lhs=$config->getValue($m_path."/lhs");
            $cmd.=" --enablehesiod --hesiodlhs $lhs --hesiodrhs $rhs";
        };
        /ldap/ and do {
            my $nssonly = "false";
            if ( $config->elementExists($m_path."/nssonly")) {
                $nssonly = $config->getValue($m_path."/nssonly");
            }
            if ( $nssonly eq "false" ) { 
                $cmd.=" --enableldapauth --enableldap";
            } else {
                $cmd.=" --disableldapauth --enableldap";
            }

            my $servers="";
            my $srv_elmt=$config->getElement($m_path."/servers");
            while ( $srv_elmt->hasNextElement() ) {
                $servers and $servers.=",";
                $servers.=($srv_elmt->getNextElement())->getValue();
            }
            $cmd.=" --ldapserver \"$servers\"";

            $cmd.=" --ldapbasedn ".$config->getValue($m_path."/basedn");

            my $usetls=&getValueDefault($config,$m_path."/tls/enable","false");
            if ( $usetls eq "true" ) {
                $cmd.=" --enableldaptls";
            }
        };

        } # foreach ( $m_name )

    } # while ( method )

    return $cmd;
}



##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;

    # Define paths for convenience. 
    my $base = "/software/components/authconfig";

    my $safemode=&getValueDefault($config,$base."/safemode","false");

    # authconfig basic configuration
    my $authconfig_cmd=$self->build_authconfig_command($config,$base);

    $self->debug(1,"Executing authconfig command with safemode=".$safemode);
    $self->debug(2,"Command = $authconfig_cmd");
	print "$authconfig_cmd\n";
    if ( $safemode eq "false" ) { # execute the authconfig command 

        my ($stdout,$stderr);

        my $execute_status = LC::Process::execute( 
                [ $authconfig_cmd ],
                timeout => 60,
                stdout => \$stdout,
                stderr => \$stderr
            );

        if ( $? >> 8) {
            $self->error("authconfig command failed: $?\n$authconfig_cmd");
        }

        if ( $stdout ) {
            $self->info("authconfig command output produced:");
            $self->report($stdout);
        }
        if ( $stderr ) {
            $self->info("authconfig command ERROR produced:");
            $self->report($stderr);
        }

    }

    # the LDAP method has additional configuration in /etc/ldap.conf
    if ( &getValueDefault($config,
            $base."/method/ldap/enable","false") eq "true" ) {

        my $nchanges = $self->build_ldap_config($config,$base."/method/ldap");
        if ( $nchanges and 
             ( &getValueDefault($config,$base."/usecache","false") eq "true" ) ) {

          $self->debug(1,"LDAP configuration changed and usecache enabled: restarting nscd");
          my ($stdout,$stderr);
          
          # This is due to nscd failing when nscd restart is called in a short period of time
          sleep 1;
          
          my $execute_status = LC::Process::execute( 
                  [ "service nscd reload" ],
                  timeout => 30,
                  stdout => \$stdout,
                  stderr => \$stderr
              );
  
          if ( $? >> 8) {
              $self->error("authconfig nscd restart failed: $?");
          }
  
          if ( $stdout ) {
              $self->info("authconfig nscd restart command output produced:");
              $self->report($stdout);
          }
          if ( $stderr ) {
              $self->info("authconfig nscd restart command ERROR produced:");
              $self->report($stderr);
          }
        }

    }
    if ( $config->elementExists($base."/pamadditions") ) {
      my $method_elmt=$config->getElement("$base/pamadditions");
      while ( $method_elmt->hasNextElement() ) {
        my $m_elmt=$method_elmt->getNextElement();
        my $m_path=($m_elmt->getPath())->toString();
        $self->build_pam_systemauth($config,$m_path);
      }
    }
      


    return 1;
}

1;      # Required for PERL modules

