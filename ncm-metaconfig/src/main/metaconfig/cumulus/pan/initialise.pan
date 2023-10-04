unique template metaconfig/cumulus/initialise;

include 'metaconfig/cumulus/schema';

bind "/software/components/metaconfig/services/{/home/cumulus/initialise.sh}/contents" = cumulus_initialise;

prefix "/software/components/metaconfig/services/{/home/cumulus/initialise.sh}";
"module" = "cumulus/initialise_sh";
