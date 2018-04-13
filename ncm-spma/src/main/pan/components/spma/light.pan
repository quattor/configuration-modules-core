# ${license-info}
# ${developer-info}
# ${author-info}

@{Include this template to enable spmalight configuration,
  after the spma (and accounts pre dependency) configuration.

  It will create a new spmalight component that uses the spma component module.

  This will result runninng:
    1. a filtered spma component run
    2. accounts component
    3. (full/regular) spma component run

  The use case is to run the accounts component before (full) spma,
  to make sure certain local users are created by
  ncm-accounts and not by the packages.
}
unique template components/spma/light;

include 'components/spma/config';
include 'components/accounts/config';

@{list of spmalight filters.
  the filter for the accounts and spma components is added.}
variable SPMALIGHT_FILTERS = append("^ncm-(accounts|spma)$");

"/software/components/spmalight" ?= value("/software/components/spma");
prefix "/software/components/spmalight";
"userpkgs" = null;
"filter" = format("(%s)", join("|", SPMALIGHT_FILTERS));
"ncm-module" = "spma";
"dependencies/post" = append('spma');

include format('components/spma/%s/light', SPMA_BACKEND);

# Need to do the following for each extra component
# We cannot use a variable to loop over,
# the 2nd part will fail on any final component path
"/software/components/spma/dependencies/pre" = append('accounts');
"/software/components/accounts/dependencies/pre" = {
    foreach(idx; dep; SELF) {
        if (dep == 'spma') {
            SELF[idx] = 'spmalight';
        };
    };
    SELF;
};
