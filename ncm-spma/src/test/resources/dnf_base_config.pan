unique template dnf_base_config;

include 'components/spma/dnf/schema';

#"/software/groups" = dict();
"/software/modules" = dict();
"/software/groups/default" = true;
"/software/groups/mandatory" = true;
"/software/groups/optional" = false;
"/software/groups/names" = list();

prefix "/software/packages";
"ConsoleKit/_2e4_2e1_2d3_2eel6/arch/x86_64" = "sl620_x86_64";
"ncm-spma/_2e1_2e0_2d1/arch/noarch" = "sl620_x86_64";

prefix "/software/repositories/0";
"name" = "sl620_x86_64";
"owner" = "me@example.com";
"protocols/0/name" = "http";
"protocols/0/url" = "http://www.example.com";

prefix "/software/components/spma";
"run" = false;
"active" = true;
"dispatch" = true;
"excludes" = list();
"dnfconf" = "[main]\ngpgcheck=1\ninstallonly_limit=3\nclean_requirements_on_remove=True\nbest=True\n";
