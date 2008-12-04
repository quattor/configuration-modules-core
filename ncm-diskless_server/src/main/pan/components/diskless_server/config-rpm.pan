# ${license-info}
# ${developer-info}
# ${author-info}



unique template components/diskless_server/config-rpm;
include components/diskless_server/schema;

# Common settings
#"/software/components/diskless_server/dependencies/pre" = list("spma");
"/software/components/diskless_server/active" = true;
"/software/components/diskless_server/dispatch" ?= true;
