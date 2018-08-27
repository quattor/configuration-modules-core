# ${license-info}
# ${developer-info}
# ${author-info}

@{gather identity data from other services (possibly on other hosts)}
unique template components/openstack/identity/gather;

@{Given dict as first argument, get nested data
  (or add structure of dicts), one level per argument
  The first argument is updated in place if needed.}
function openstack_vivify = {
    data = ARGV[0];
    if (!is_dict(data)) {
        error("%s: first argument must be a dict, got %s", FUNCTION, data);
    };
    current = data;
    foreach (idx; arg; ARGV) {
        if (idx > 0) {
            if (exists(current[arg])) {
                value = current[arg];
                if (!is_dict(value)) {
                    error("%s: existing key %s found, but is not a dict (%s)",
                            FUNCTION, arg, value);
                };
            } else {
                current[arg] = dict();
            };
            current = current[arg];
        };
    };
    current;
};

@{set dict key/value pairs from dict value (3rd arg) to dict data (1st arg) with key (2nd arg)
  an error is raised when already existing key does not have expected value;
  4th arg msg is part of the error message}
function openstack_merge = {
    data = ARGV[0];
    key = ARGV[1];
    values = ARGV[2];
    msg = ARGV[3];

    if (exists(data[key])) {
        foreach (k; v; values) {
            if (data[key][k] != v) {
                error("%s: %s %s has different existing value %s (expected %s) (whole section %s)",
                        FUNCTION, msg, key, data[key][k], v, data[key]);
            };
        };
    } else {
        data[key] = values;
    };

    data;
};

@{recursive find for (assumed unique) dict named keystone_authtoken.
  Returns undef if nothing is found.}
function openstack_identity_gather_find_authtoken = {
    data = ARGV[0];

    foreach (k; v; data) {
        res = undef;
        if (k == 'keystone_authtoken') {
            res = v;
        } else if (is_dict(v)) {
            res = openstack_identity_gather_find_authtoken(v);
        };
        if (is_defined(res)) {
            return(res);
        };
    };
    return(undef);
};

@{update the OS identity data (1st arg) for a service name (2nd arg)
  with service and endpoint data.
  3rd arg is a service data, 4th arg is the endpoint default and 5th argument is host identifier}
function openstack_identity_gather_service_add = {
    data = ARGV[0];
    name = ARGV[1];
    srvdata = ARGV[2];
    edef = ARGV[3];
    msg = ARGV[4];

    sdescr = format("OS %s service %s", srvdata['type'], name);
    data_s = openstack_vivify(data, 'service');
    openstack_merge(
        data_s,
        name,
        dict('type', srvdata['type'], 'description', sdescr),
        msg,
        );

    # internal first, to make the default for the others
    foreach (idx; intf; list('internal', 'public', 'admin')) {
        ep = clone(edef);
        if (exists(srvdata[intf])) {
            foreach (k; v; srvdata[intf]) {
                ep[k] = v;
            };
        };

        if (!exists(ep['proto'])) {
            error("%s anme %s ep %s edef %s srvdata %s", msg, name, ep, edef, srvdata);
        };
        url = format("%s://%s:%s/%s", ep['proto'], ep['host'], ep['port'], ep['suffix']);

        data_e = openstack_vivify(data, 'endpoint', name, intf);
        data_e['url'] = append(data_e['url'], url);
        if (exists(ep['region'])) {
            data_e['region'] = ep['region'];
        };

        if (intf == 'internal') {
            edef = ep;
        };
    };

    data;
};

@{update the OS identity data (1st arg) for a single service/flavour dict (2nd arg)
  3rd arg is a openstack service, 4th arg is the flavour and 5th argument is host identifier}
function openstack_identity_gather_service = {
    data = ARGV[0];
    srv = ARGV[1];
    service = ARGV[2];
    flavour = ARGV[3];
    host = ARGV[4];

    descr = format("service %s flavour %s", service, flavour);
    msg = format("host %s", host);

    # user/passwd data
    #   get user/password from a keystone_authtoken section
    #   section can be nested
    authtoken = openstack_identity_gather_find_authtoken(srv);
    if (is_defined(authtoken)) {
        if (!exists(authtoken['username']) || !exists(authtoken['password'])) {
            error("%s: authtoken section has no user and/or password %s %s", FUNCTION, descr, msg);
        };
        user = authtoken['username'];
        pwd = authtoken['password'];
        udescr = format("quattor %s user", descr);
        domain = 'default';

        data_u = openstack_vivify(data, 'user');
        openstack_merge(
            data_u,
            user,
            dict('password', pwd, 'domain_id', domain, 'description', udescr),
            format("host %s service %s", host, service)
            );

        data_r = openstack_vivify(data, 'rolemap', 'project', 'service', 'user');
        data_r[user] = append(data_r[user], 'admin');
    };

    # quattor section
    if (exists(srv['quattor'])) {
        qt = srv['quattor'];
        if (exists(qt['service'])) {
            srvmsg = format("host %s service/flavour %s/%s", host, service, flavour);
            qsrv = qt['service'];
            qsrv['type'] = service;
            openstack_identity_gather_service_add(
                data,
                flavour,
                qsrv,
                dict(), # no defaults
                srvmsg,
                );
            if (exists(qt['services'])) {
                foreach (name; srvdata; qt['services']) {
                    openstack_identity_gather_service_add(
                        data,
                        name,
                        srvdata,
                        qsrv['internal'],
                        format("%s extra %s", srvmsg, name)
                        );
                };
            };
        };
    };

    data;
};

@{update and return data (1st arg) with the identity data
  from the openstack configuration of the current host.

  Data to update is typically the value of the identity client configuration,
  so users, services, ... etc can be added.

  If more than one argument is passed, it is treated as external profiles
  whose openstack configuratiom will also be used to update that identity data.
  (If short hostname(s) are passed, and the variable OPENSTACK_IDENTITY_GATHER_DOMAIN
  exists, its value will be suffixed as a domain (no leading '.' required)).
  If no openstack configuration is found, host is skipped.
}
function openstack_identity_gather = {
    data = ARGV[0];

    os_component = '/software/components/openstack';
    os_services = list('identity', 'network', 'compute', 'storage', 'volume', 'share');

    hosts = list(list(OBJECT, ''));
    if (ARGC > 1) {
        for (idx = 1; idx < ARGC; idx = idx + 1) {
            host = ARGV[idx];
            if (!match('\.', host) && exists(OPENSTACK_IDENTITY_GATHER_DOMAIN)) {
                host = format('%s.%s', host, OPENSTACK_IDENTITY_GATHER_DOMAIN);
            };
            hosts = append(hosts, list(host, "//" + host));
        };
    };

    foreach (idx; host; hosts) {
        os = value(format("%s%s", host[1], os_component), null);
        if (is_null(os)) {
            debug("%s: no openstack configuration data found for host %s.", FUNCTION, host[0]);
        } else {
            foreach (idx; srv; os_services) {
                if (exists(os[srv])) {
                    # pass the service flavour data
                    # should only be one flavour
                    # ignore the client section
                    flavour = 0;
                    foreach (fl; fldata; os[srv]) {
                        if (fl != 'client') {
                            flavour = flavour + 1;
                            data = openstack_identity_gather_service(data, fldata, srv, fl, host[0]);
                        };
                    };
                    if (flavour > 1) {
                        error("%s: more than one flavour found for %s on host %s", FUNCTION, srv, host[0]);
                    };
                };
            };
        };
    };

    data;
};
