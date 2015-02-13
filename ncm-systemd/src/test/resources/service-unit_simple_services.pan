unique template service-unit_simple_services;

prefix "/software/components/systemd/service";

"{test2_on}" = nlist("state", "on", "targets", list("rescue", "multi-user"), "startstop", true);
"{test2_add}" = nlist("state", "off", "targets", list("multi-user"), "startstop", true, "type", "target");
"{test2_on_rename}" = nlist("state", "on", "targets", list("multi-user"), "startstop", true, "name", "othername2");

# redefine old ones / these have the same name
"{test_off}" = nlist("state", "del","targets", list("rescue"), "startstop", true);
"{test_del}" = nlist("state", "on", "targets", list("rescue"), "startstop", false);

