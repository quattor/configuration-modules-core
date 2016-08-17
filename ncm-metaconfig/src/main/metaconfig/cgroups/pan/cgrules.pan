unique template metaconfig/cgroups/cgrules;

@{cgrules are applied via cgred service}
variable CGROUPS_CGRULESENGD ?= true;

include 'metaconfig/cgroups/schema';

# Can only pass a dict as CCM.contents
bind "/software/components/metaconfig/services/{/etc/cgrules.conf}/contents/rules" = cgroups_cgrule[];

prefix  "/software/components/metaconfig/services/{/etc/cgrules.conf}";
"mode" = 0644;
"module" = "cgroups/cgrules";
# rules can also be used by pam module, in which case the cgrulesengd shouldn't be used
"daemons" = {
    if (CGROUPS_CGRULESENGD) {
        SELF["cgred"] = "restart";
    };
    SELF;
};
