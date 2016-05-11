# ${license-info}
# ${developer-info}
# ${author-info}

@{
    This template should be included as last statement in any node profile
}
unique template components/spma/repository_cleanup;

# Remove contents attached to repository (useless after version resolution, not part of the schema)
"/software/repositories" = purge_rep_list(value("/software/packages"));


