# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/ips/config;

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

#
# Configure SPMA appropriately for Solaris 11
#
'packager' = 'ips';

'pkgpaths' = list(
    '/software/catalogues',
    '/software/requests',
);

'uninstpaths' = list(
    '/software/uninstall',
);

'whitepaths' = list(
    '/software/whitelist',
);

'register_change' = list(
    '/software/catalogues',
    '/software/requests',
    '/software/whitelist',
    '/software/uninstall',
);

'flagfile' = '/var/tmp/spma-run-flag';
