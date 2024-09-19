declaration template components/network/types/network/backend/nmstate;

@{implement types specific for nmstate / nmstate.pm}

type structure_network_nmstate = {
    @{let NetworkManager manage the dns}
    "manage_dns" : boolean = false
    @{let ncm-network cleanup inactive connections}
    "clean_inactive_conn" : boolean = true
};

type structure_network_backend_specific = {
    "nmstate" : structure_network_nmstate
};
