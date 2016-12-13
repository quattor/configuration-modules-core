object template lookup_registration;

include 'metaconfig/perfsonar/lookup/registration/config';

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/ls_registration_daemon/etc/ls_registration_daemon.conf}/contents";
"ls_instance" = "http://localhost:9995/perfsonar_PS/services/hLS";
"site/0" = dict("site_name", "MYSITE",
    "site_location", "HERE",
    "address", "my.host.domain",
    "site_project", list("MYSITE"),
    "service", list(
        dict("type", "bwctl"),
        dict("type", "owamp")
    ));
