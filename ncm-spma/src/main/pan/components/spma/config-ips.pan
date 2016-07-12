# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config-ips;

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

'register_change' = list(
    '/software/catalogues',
    '/software/requests',
    '/software/uninstall',
);

'flagfile' = '/var/tmp/spma-run-flag';
