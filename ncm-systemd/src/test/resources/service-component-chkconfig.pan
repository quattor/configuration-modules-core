object template service-component-chkconfig;

# Test the whole Config using this template

prefix "/software/components/systemd";
"default" = "ignore";
"skip/service" = false;
"skip/random" = false;

include 'service-chkconfig_simple_services';
