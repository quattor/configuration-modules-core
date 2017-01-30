unique template service_services_ceph021;

prefix "/software/components/systemd/unit";

"network" = dict(
    "state", "enabled",
    "startstop", true,
    "targets", list("multi-user", "graphical"),
    );
"netconsole" = dict(
    "state", "enabled",
    "startstop", true,
    "targets", list("multi-user"),
    );
"rbdmap" = dict(
    "state", "enabled",
    "startstop", true,
    "targets", list("multi-user"),
    );
"cups" = dict(
    "state", "disabled",
    "startstop", false,
    "targets", list("graphical"),
);
"dbus" = dict(
    "state", "enabled",
    "startstop", true,
    "targets", list("multi-user"),
);
"messagebus" = dict(
    "state", "disabled",
    "startstop", true,
    "targets", list("multi-user"),
);


