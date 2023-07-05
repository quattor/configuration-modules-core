# ${license-info}
# ${developer-info}
# ${author-info}

@{
    See Intelligent Platform Management Interface Specification v2.0 rev. 1.1
    https://www.intel.co.uk/content/www/uk/en/products/docs/servers/ipmi/ipmi-second-gen-interface-spec-v2-rev1-1.html
}
declaration template components/ipmi/schema;

include 'quattor/schema';

type structure_users = {
    @{
        User Name String in ASCII (16 bytes)
        See IPMI Spec v2.0 rev 1.1 section 22.28 Set User Name Command

        Restricted to only printable ASCII characters
    }
    "login" : string_trimmed(1..16) with match(SELF, '^\p{Print}+$')

    @{
        Password String in ASCII (16/20 bytes)
        See IPMI Spec v2.0 rev 1.1 section 22.30 Set User Password Command

        Restricted to only printable ASCII characters
    }
    "password" : string_trimmed(0..20) with match(SELF, '^\p{Print}+$')

    @{
        Channel Privilege Level Limit (4 bits)
        See IPMI Spec v2.0 rev 1.1 section 22.26 Set User Access Command

        Standard Levels:
            0 = Reserved (not supported)
            1 = CALLBACK
            2 = USER
            3 = OPERATOR
            4 = ADMINISTRATOR
            5 = OEM Proprietary
            15 = No access
    }
    "priv" ? long(1..15) with SELF <= 5 || SELF == 15

    @{
        Numeric User ID (6 bits)

        Standard values:
            0 = Reserved (not supported)
            1 = The null user
    }
    "userid" ? long(1..63)
};

type component_ipmi_type = {
    include structure_component

    @{
        Channel Number (4 bits)
        See IPMI Spec v2.0 rev 1.1 section 6.3 Channel Numbers

        Standard Channels:
            0       Primary IPMB (not supported)
            1-11    Implementation-specific (normal range)
            12-13   Reserved (not supported)
            14      Reserved for identifying current channel (not supported)
            15      System Interface (not supported)
    }
    "channel" : long(1..11) = 1

    @{
        User Configuration

        List of structure_users type.
    }
    "users" : structure_users[]
};

bind "/software/components/ipmi" = component_ipmi_type;
