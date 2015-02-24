unique template service_services_ceph021;

prefix "/software/components/systemd/service";

"network" = nlist(
    "state", "enabled",
    "startstop", true,
    "targets", list("multi-user", "graphical"),
    );
"netconsole" = nlist(
    "state", "enabled",
    "startstop", true,
    "targets", list("multi-user"),
    );
"rbdmap" = nlist(
    "state", "enabled",
    "startstop", true,
    "targets", list("multi-user"),
    );
"cups" = nlist(
    "state", "disabled",
    "startstop", false,
    "targets", list("graphical"),
);
"dbus" = nlist(
    "state", "enabled",
    "startstop", true,
    "targets", list("multi-user"),
);
"messagebus" = nlist(
    "state", "disabled",
    "startstop", true,
    "targets", list("multi-user"),
);


