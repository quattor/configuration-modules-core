object template simple_services;

prefix "/software/components/chkconfig/service";

"{test_on}" = nlist("on","123");
"{test_add}" = nlist("add",true);

"{test_on_rename}" = nlist("on","4","name","othername");

# the service has to exists and/or turned on
"{test_off}" = nlist("off","45");
"{test_del}" = nlist("del",true,);

