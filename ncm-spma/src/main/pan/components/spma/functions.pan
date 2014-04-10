# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/spma/functions;

variable DEF ?= '';

############################################################
#
# Utility function to determine if a particular child element
# exists.  Used in the checking of the repositories.
#
###################################################################
function repository_exists = {
    name = ARGV[0];
    foreach (t;curr_item;value(ARGV[1])) {
        if(name == curr_item["name"]) return(true);
    };
    debug("Item " + name + " does not exist in " + ARGV[1]);
    return(false);
};



########################################################
#
# Automatically fill "repository" field for package list
#
# resolve_pkg_rep <repository list> [<pkg list>]
#
# When the second argument is specified, only the package
# specified are resolved, if they exist in the configuration.
#
########################################################

function resolve_pkg_rep = {
    error=0;
    errorstr="";
    function_name='resolve_pkg_rep2';
    if ( ARGC >= 1 ) {
      rep_list = ARGV[0];
    } else {
      error(function_name+': missing required first argument (repository list)');
    };
    if ( ARGC >= 2 ) {
      pkg_list = list();
      foreach (i;name;ARGV[1]) {
        pkg_list[length(pkg_list)] = escape(name);
      };
    } else {
      pkg_list = list();
      foreach (name;pkg_list_name;SELF) {
        pkg_list[length(pkg_list)] = name;
      };
    };
    debug("Assigning repositories to packages...");

    foreach (dummy;name;pkg_list) {
        # Ignore a non existent package: this happens when a list of package to resolve is
        # given explicitly. It is not a requirement that the package must exist.
        if ( is_defined(SELF[name]) ) {
          pkg_list_name = SELF[name];
          foreach (version;pkg_list_name_version;pkg_list_name) {
            if (exists(pkg_list_name_version['repository'])) {
                rep_mask = pkg_list_name_version['repository'];
                pkg_list_name_version['repository'] = undef;
            } else {
                rep_mask = '';
            };
            foreach (arch;i;pkg_list_name_version['arch']) {
                rep_mask = i;

                debug ("Processing package >>" + unescape(name) + "<< version >>" + unescape(version) + "<< arch >>" + arch + "<<");
                id = escape(unescape(name) + "-" + unescape(version) + "-" + arch);

                rep_found = false;
                in_list = first(rep_list,t,curr_rep);
                while ( in_list && ! rep_found) {
                    if(match(curr_rep["name"],rep_mask) && exists(curr_rep["contents"][id])) {
                        debug("Package " + unescape(name)+'-'+unescape(version)+'-'+arch + " - assigned repository " + curr_rep["name"]);
                        rep_found = true;
                        SELF[name][version]['arch'][arch] = curr_rep['name'];
                    } else {
                        debug("Package "+unescape(id)+" not found in repository "+curr_rep["name"]);
                        in_list = next(rep_list,t,curr_rep);
                    };
                };

                if( ! rep_found ) {
                    errorstr = format("%s\nname: %s version: %s arch: %s", errorstr, unescape(name), unescape(version), arch);
                    error=error+1;
                };
            };
          };
        };
    };

    if (error == 0) {
        SELF;
    } else {
        error ("cannot find any repository holding the following package(s): "+errorstr+"\n");
    };
};


########################################################
#
# Remove not needed repository information
#
# purge_rep_list <repository list>
#
#
############################

function purge_rep_list = {
    foreach (i;rep;SELF) {
        rep['contents'] = null;
    };
    SELF;
};


########################################################
#
# Remove package from list
#
# pkg_del <name> [version] [arch]
#
# If version is not specified (no argument provided),
# then ALL existing versions are removed from the profile.
#
# If arch is not specified (no argument provided),
# then ALL existing archs for the specified version are removed
# from the profile.
#
# pkg_del is a wrapper of pkg_repl() that is the real workhorse.
#
########################################

function pkg_del = {
    options = list("delete");
    debug("Removing package " + ARGV[0]);

    if(ARGC > 1 && ARGV[1] != DEF) {
        version = ARGV[1];
    } else {
        debug("    Version not specified, deleting all versions");
        version = DEF;
    };

    if(ARGC > 2 && ARGV[2] != DEF) {
        arch = ARGV[2];
    } else {
        debug("    Arch not specified, deleting all architectures");
        arch = DEF;
        options[length(options)] = "allarchs";
    };

    pkg_repl(ARGV[0], version, arch, options);
};

########################################################
#
# Add package to the package list
#
# pkg_add <name> [version] [arch] [options] [flags] [repository]
#
# examples:
#
# add emacs-19.34.i386 to the profile
# "/software/packages"=pkg_add("emacs","19.34","i386");
#
# add the default version of emacs to the profile
# "/software/packages"=pkg_add("emacs");
#
# add two kernel versions to the profile
# "/software/packages"=pkg_add("kernel","2.4.1","i386","multi");
# "/software/packages"=pkg_add("kernel","2.4.2","i386","multi");
#
# use repository "CERN_CC" for the package CERNLIB
# "/software/packages"=pkg_add("cernlib","3.0.1","i386",DEF,DEF,"CERN_CC")
#
#
# Only the <name> is mandatory.
#
# If [version] or [arch] are not defined, their value is deduced
# from the global variable package_default. (If no entry in
# package_default is found, an error is produced)
#
# the optional 'options' can be set to string 'multi' to indicate
# that this package version can live with other package versions
# in this profile (eg. when using multiple versions of a package,
# like the Linux Kernel RPMs or the ASIS gcc-alt RPMs).
# If the 'multi' option is not set, the pkg_add function will fail
# if a previous version is found in the profile.
#
# the flags and repository fields are optional.
#
# the repository field can be used to force the usage of a
# specific repository.
#
# the flag field will be used for future extensions.
#
# pkg_add() is a wrapper of pkg_repl() that is the real workhorse.
#
########################################
function pkg_add = {
    debug("Adding package " + ARGV[0]);

    options = list();
    if ( ARGC > 3 ) {
        if ( is_list(ARGV[3]) ) {
            options = ARGV[3];
        } else {
            if ( ARGV[3] != DEF ) {
                options[length(options)] = ARGV[3];
            };
        };
    };
    options[length(options)] = "addonly";

    if(ARGC > 1 && ARGV[1] != DEF) {
        version = ARGV[1];
    } else {
        version = DEF;
    };

    if(ARGC > 2 && ARGV[2] != DEF) {
        arch = ARGV[2];
    } else {
        arch = DEF;
    };

    if ( ARGC > 4 && is_nlist(ARGV[4]) ) {
        flags = ARGV[4];
    } else {
        flags = DEF;
    };

    if ( ARGC > 5 && ARGV[5] != DEF ) {
        rep = ARGV[5];
    } else {
        rep = DEF;
    };

    pkg_repl(ARGV[0], version, arch, options, flags, rep);
};

########################################################
#
# Replace package in the list
#
# pkg_repl <name> <new version> <arch>
#
# In fact pkg_repl() is the real workhorse of pkg_add/pkg_del/pkg_repl/pkg_ronly.
# Other functions are just wrappers of pkg_repl(). 'options' argument
# is used to tailor this function behaviour for a particular purpose.
#
# if no version existed in the profile, the new version
# is just added.
#
# See pkg_add for a detailed description of the other fields.
# As in pkg_add, the "new version" and "arch" are optional.
#
########################################

function pkg_repl = {
    # SELF handles the current list of packages
    name = ARGV[0];
    u_name = '_'+name;

    e_name = escape(name);

    if( ARGC > 3 ) {
      error('Usage: pkg_repl accepts 3 arguments');
    };

    version = undef;
    arch = undef;
        
    if ( (ARGC == 1) || ( (ARGC > 1) && (ARGV[1] == '') ) ) {
      if ( is_list(package_default[u_name]) ) {
        version = package_default[u_name][0];
        if ( exists(package_default[u_name][1]) ) {
          arch = package_default[u_name][1];
        };
    } else {
      version = ARGV[1];
      if ( (ARGC == 3) && (ARGV[2] != '') ) {
        arch = ARGV[2];
      };
    };

    if ( exists(SELF[escape(ARGV[0])]) ) {
      package_params = SELF[escape(ARGV[0])];
    } else {
      package_params = undef;
      SELF[escape(ARGV[0]) = nlist();
    };
    if ( is_defined(version) ) {
      # Check if the version is already part of the package and in this case, only add a new arch if needed.
      # Else reply existing version.
      # FIXME : should probably replace only a version/arch combination... but this could lead to different versions for 
      # different arch and will probably not work... Could also upgrade version for all archs already defined?
      version_e = escape(version);
      if ( is_defined(package_params[version_e]) ) {
        arch_params = package_params[version_e];
        # If arch is unspecified, remove any explicit arch
        if ( is_defined(arch) ) {
          if ( index(arch_params,arch) < 0 ) {
            arch_params[arch] = '';
          };
        } else {
          arch_params = nlist();
        };
      } else {
        if ( is_defined(arch) ) {
          arch_params=nlist('arch', nlist(arch,''));
        } else {
          arch_params=nlist();
        };
      };
      SELF[escape(ARGV[0])][version_e] = arch_params;
    } else {
      # Refuse to replace an explicit version by an undefined version
      if ( is_defined(package_params) ) {
        error(format('Attempt to unlock version of package %s (version %s'),ARGV[0],unescape(key(package_params,0))));
      };
    };
    
    SELF;
};


########################################################
#
# Replace package in the list ONLY if present
#
# pkg_ronly <name> <new version> <arch> [options] [flags] [repository]
#
# Same as pkg_repl() except that if no version existed in the profile,
# NO new version is added. See pkg_repl() for argument documentation.
#
# This function is a wrapper of pkg_repl().
#
########################################

function pkg_ronly = {
    debug("Replacing package " + ARGV[0] + " if currently present");

    options = list();
    if ( ARGC > 3 ) {
        if ( is_list(ARGV[3]) ) {
            options = ARGV[3];
        } else {
            if ( ARGV[3] != DEF ) {
                options[length(options)] = ARGV[3];
            };
        };
    };
    options[length(options)] = "ronly";

    if(ARGC > 1 && ARGV[1] != DEF) {
        version = ARGV[1];
    } else {
        debug("    Version not specified, replacing by default version");
        version = DEF;
    };

    if(ARGC > 2 && ARGV[2] != DEF) {
        arch = ARGV[2];
    } else {
        debug("    Arch not specified, replacing all architectures");
        arch = DEF;
        options[length(options)] = "allarchs";
    };

    if ( ARGC > 4 && is_nlist(ARGV[4]) ) {
        flags = ARGV[4];
    } else {
        flags = DEF;
    };

    if ( ARGC > 5 && ARGV[5] != DEF ) {
        rep = ARGV[5];
    } else {
        rep = DEF;
    };

    pkg_repl(ARGV[0], version, arch, options, flags, rep);
};
