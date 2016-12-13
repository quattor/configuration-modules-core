unique template service-chkconfig_simple_services;

prefix "/software/components/chkconfig/service";

"{test_on}" = dict("on","123");
"{test_add}" = dict("add",true);

"{test_on_rename}" = dict("on","4","name","othername");

# the service has to exists and/or turned on
"{test_off}" = dict("off","45");
"{test_del}" = dict("del",true,);

