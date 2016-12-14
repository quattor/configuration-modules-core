# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/hostsaccess/schema;

include 'quattor/schema';

type structure_hostsaccess_entry = {
    'daemon' ? string
    'host' ? string
};

type component_hostsaccess = {
    include structure_component
    'allow' ? structure_hostsaccess_entry[]
    'deny' ? structure_hostsaccess_entry[]
};

bind '/software/components/hostsaccess' = component_hostsaccess;
