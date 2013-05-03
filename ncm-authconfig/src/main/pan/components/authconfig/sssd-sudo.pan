# ${license-info}
# ${developer-info}
# ${author-info}

@{
    Contains the data structure describing the sudo configurations in
    the LDAP SSSD provider.

    Fields in these data types match the ldap_sudorule_* and/or the
    ldap_sudo_* fields of the sssd-ldap man page.
}

declaration template components/authconfig/sssd-sudo;

type sssd_sudorule = {
    "object_class" : string = "sudoRole"
    "name" : string = "cn"
    "command" : string = "sudoCommand"
    "host" : string = "sudoHost"
    "user" : string = "sudoUser"
    "option" : string = "sudoOption"
    "runasuser" : string = "sudoRunAsUser"
    "runasgroup" : string = "sudoRunAsGroup"
    "notbefore" : string = "sudoNotBefore"
    "notafter" : string = "sudoNotAfter"
    "order" : string = "sudoOrder"
};

type sssd_sudo = {
    "rules" : sssd_sudorule = nlist()
    "full_refresh_interval" : long = 21600
    "smart_refresh_interval" : long = 900
    "use_host_filter" : boolean = true
    "hostnames" ? string
    "ip" ? string
    "include_netgroups" : boolean = true
    "include_regexp" : boolean = true
    "search_base" ? string
};
