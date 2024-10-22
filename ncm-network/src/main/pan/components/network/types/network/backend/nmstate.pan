declaration template components/network/types/network/backend/nmstate;

@{implement types specific for nmstate / nmstate.pm}

type structure_network_backend_specific = {
    @{let NetworkManager manage the dns}
    "manage_dns" : boolean = false
    @{let ncm-network cleanup inactive connections}
    "clean_inactive_conn" : boolean = true
};
