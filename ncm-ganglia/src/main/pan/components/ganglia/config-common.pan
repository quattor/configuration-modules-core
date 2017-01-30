# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/ganglia/config-common;

include 'components/ganglia/schema';

# Set prefix to root of component configuration.
prefix '/software/components/ganglia';

#'version' = '${no-snapshot-version}-${RELEASE}';
'package' = 'NCM::Component';

'active' ?= true;
'dispatch' ?= true;
