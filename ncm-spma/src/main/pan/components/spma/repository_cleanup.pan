# ${license-info}
# ${developer-info}
# ${author-info}

#
# This template should be included as last statement in any node profile
#
################################################################################

template  components/spma/repository_cleanup;


"/software/packages" = resolve_pkg_rep(value("/software/repositories"));
"/software/repositories" = purge_rep_list(value("/software/packages"));


