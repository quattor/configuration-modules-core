# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

# Template adding ncm-opennebula rpm to the configuration

unique template quattor/aii/opennebula/rpms;

"/software/packages" = pkg_repl("ncm-opennebula", "${no-snapshot-version}-${rpm.release}", "noarch");
