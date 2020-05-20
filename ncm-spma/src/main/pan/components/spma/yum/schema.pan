# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/spma/yum/schema;

include 'components/spma/schema';
include 'components/spma/schema-common-yum';

type SOFTWARE_GROUP = {
    "default" : boolean = true
    "mandatory" : boolean = true
    "optional" : boolean = false
};

@documentation{
    Main configuration options for yum.conf.
    The cleanup_on_remove, obsoletes, reposdir and pluginpath are set internally.
}
type spma_yum_main_options = {
    "exclude" ? string[]
    "installonly_limit" ? long(0..) = 3
    "keepcache" ? boolean
    "retries" ? long(0..) = 10
    "timeout" ? long(0..) = 30
};

type component_spma_yum = {
    include structure_component
    include component_spma_common
    include component_spma_common_yum
    "fullsearch" : boolean = false
    "main_options" ? spma_yum_main_options
    "plugins" ? spma_yum_plugins
    "process_obsoletes" : boolean = false
    "proxytype" ? string with match (SELF, '^(forward|reverse)$') # select proxy type, forward or reverse
    "run" ? legacy_binary_affirmation_string # Run the SPMA after configuring it
    "userpkgs_retry" : boolean = true
    "userpkgs" ? legacy_binary_affirmation_string # Allow user packages
    @{ List of external repo dirs to be included in addition to the one managed by this component. }
    "reposdirs" ? absolute_file_path[]
    @{regexp pattern to install only matching (unescaped) package names.
      This is an advanced setting, and typically only used in a 2-stage software
      install like spmalight.
      When userpkgs is not defined, it runs as if userpkgs is true.
      When repository_cleanup is not defined, it runs as if repository_cleanup is true.
      (Caution: is userpkgs is false, it will very likely remove
      all non-matching packages. It is advised to remove the userpkgs attribute).
      Versionlocking is not affected by the filter (i.e. all packages are considered
      for version locking, not only the filtered ones).
    }
    "filter" ? string
    @{Cleanup repository configuration (even when running in userpkgs mode).
      By default, repositories will not be cleaned up when running in userpkgs mode.}
    "repository_cleanup" ? boolean
};

bind "/software/components/spma" = component_spma_yum;
bind "/software/groups" = SOFTWARE_GROUP{} with {
    if (length(SELF) > 0) deprecated(0, 'Support for YUM groups will be removed in a future release.');
    true;
};
