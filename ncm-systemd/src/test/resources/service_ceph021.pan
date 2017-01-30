object template service_ceph021;

include 'service_services_ceph021';

prefix "/software/components/systemd/unit";
"{missing_masked.service}" = dict("state", "masked", "targets", list("multi-user"), "startstop", true);
"{missing_disabled.service}" = dict("state", "disabled", "targets", list("multi-user"), "startstop", true);

prefix "/software/components/chkconfig/service";
"{missing_disabled_chkconfig}" = dict("off", "", "startstop", true);
"{NetworkManager}" = dict("off", "", "startstop", true);
