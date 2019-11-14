unique template service-unit_simple_services;

prefix "/software/components/systemd/unit";

"{test2_on}" = dict("state", "enabled", "targets", list("rescue", "multi-user"), "startstop", true);
"{test2_add}" = dict("state", "disabled", "targets", list("multi-user"), "startstop", true, "type", "target");
"{test2_on_rename}" = dict(
    "state", "enabled", "targets", list("multi-user"), "startstop", true, "name", "othername2",
    "file", dict("only", false, "replace", true, "custom", dict("a1", "b1"), "config", dict("service", dict("some1", "data1"))),
    );

# redefine old ones / these have the same name
"{test_off}" = dict("state", "masked", "targets", list("rescue"), "startstop", true);
"{test_del}" = dict("state", "enabled", "targets", list("rescue"), "startstop", false);

"{test3_only}" = dict(
    "state", "enabled", "targets", list("multi-user"), "startstop", true,
    "file", dict("only", true, "replace", false, "custom", dict("a", "b"), "config", dict("service", dict("some", "data"))),
    );
"{test4_no_restart}" = dict(
    "state", "enabled", "targets", list("multi-user"), "startstop", true, "name", "test_4_no_restart",
    "file", dict("only", false, "replace", true, "custom", dict("a1", "b1"), "config", dict("service", dict("some1", "data1"), "unit", dict("RefuseManualStart", true))),
    );
