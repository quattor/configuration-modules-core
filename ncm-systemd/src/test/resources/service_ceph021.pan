object template service_ceph021;

include 'service_services_ceph021';

prefix "/software/components/systemd/unit";
"{missing_masked.service}" = nlist("state", "masked", "targets", list("multi-user"), "startstop", true);
"{missing_disabled.service}" = nlist("state", "disabled", "targets", list("multi-user"), "startstop", true);

prefix "/software/components/chkconfig/service";
"{missing_disabled_chkconfig}" = nlist("off", "", "startstop", true);
