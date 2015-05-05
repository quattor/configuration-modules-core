object template component;

# Test the whole Config using this template

prefix "/software/components/systemd";
"default" = "ignore";
"skip/service" = false;

include 'service-chkconfig_simple_services';
