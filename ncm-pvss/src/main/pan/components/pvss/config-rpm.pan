# ${license-info}
# ${developer-info}
# ${author-info}



unique template components/pvss/config-rpm;
include {'components/pvss/schema'};

# Common settings
#"/software/components/pvss/dependencies/pre" = list("spma");
"/software/components/pvss/active" = true;
"/software/components/pvss/dispatch" ?= true;
