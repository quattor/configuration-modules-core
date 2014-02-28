# ${license-info}
# ${developer-info}
# ${author-info}

#
# This template should be included as last statement in any node profile
#
################################################################################

template  components/spma/repository_cleanup;

variable AII_OSINTALL_RPM_PKGS = value('/system/aii/osinstall/ks/base_packages');
variable AII_OSINTALL_RPM_PKGS = {
  if ( is_defined(AII_OSINSTALL_EXTRAPKGS) ) {
    foreach (i;pkg;AII_OSINSTALL_EXTRAPKGS) {
      SELF[length(SELF)] = pkg;
    };
  };
  SELF;
};
"/software/packages" = resolve_pkg_rep(value("/software/repositories"),AII_OSINTALL_RPM_PKGS);
"/software/repositories" = purge_rep_list(value("/software/packages"));


