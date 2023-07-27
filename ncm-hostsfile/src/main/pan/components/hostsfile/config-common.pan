# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config-common;

include 'components/${project.artifactId}/schema';

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

'version' = '${no-snapshot-version}';
'active' ?= false;
'dispatch' ?= false;

# Provide variables which can be used to provide dual stack entries for localhost.
# Specifying aliases for both stacks allows localhost to resolve for both protocols
# while still avoiding duplicate entries.

final variable HOSTSFILE_LOCALHOST4 = dict(
    'localhost', dict(
        'ipaddr', '127.0.0.1',
        'aliases', 'localhost.localdomain localhost4 localhost4.localdomain4',
    ),
);

final variable HOSTSFILE_LOCALHOST6 = dict(
    'localhost6', dict(
        'ipaddr', '::1',
        'aliases', 'localhost localhost.localdomain localhost6.localdomain6',
    ),
);
