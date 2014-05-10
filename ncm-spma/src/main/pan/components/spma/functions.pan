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
# If the package is not part of the configuration, silently exit:
# this is not considered as an error.
#
########################################

function pkg_del = {
    debug(format('%s: removing package %s',OBJECT,ARGV[0]));

    # SELF handles the current list of packages
    name = ARGV[0];
    u_name = '_'+name;
    e_name = escape(name);

    if( (ARGC == 0) || (ARGC > 3) ) {
        error('Usage: pkg_del requires 1 argument and accepts up to 3 arguments');
    };

    version = undef;
    arch = undef;
        
    if ( (ARGC == 1) || ( (ARGC > 1) && (ARGV[1] == '') ) ) {
        if ( is_list(package_default[u_name]) ) {
            version = package_default[u_name][0];
            if ( exists(package_default[u_name][1]) ) {
                arch = package_default[u_name][1];
            };
        };
    } else {
        version = ARGV[1];
        if ( (ARGC == 3) && (ARGV[2] != '') ) {
            arch = ARGV[2];
        };
    };

    if ( exists(SELF[e_name]) ) {
        if ( is_defined(version) ) {
            e_version = escape(version);
            if ( is_defined(SELF[e_name][e_version]) ) {
                if ( is_defined(arch) ) {
                    if ( is_defined(SELF[e_name][e_version]['arch'][arch]) ) {
                        if ( length(SELF[e_name][e_version]['arch'][arch]) == 1 ) {
                            debug(format('%s: deleting package %s version %s arch %s is the only arch, deleting version',OBJECT,ARGV[0],version,arch));
                            if ( length(SELF[e_name][e_version]) == 1 ) {
                                SELF[e_name] = null;
                            } else {
                                SELF[e_name][e_version] = null;
                            };
                        } else {
                            SELF[e_name][e_version]['arch'][arch] = null;
                        };
                    } else {
                        debug(format('%s: package %s version %s arch %s not part of the configuration, nothing done',OBJECT,ARGV[0],version,arch));
                    };
                } else {
                    debug(format('%s: deleting package %s version %s (all archs)',OBJECT,ARGV[0],version));
                    if ( length(SELF[e_name][e_version]) == 1 ) {
                        SELF[e_name] = null;
                    } else {
                        SELF[e_name][e_version] = null;
                    };
                };
            } else {
                debug(format('%s: package %s version %s not part of the configuration, nothing done',OBJECT,ARGV[0],version));
            };
        } else {
            debug(format('%s: deleting package %s (all versions)',OBJECT,ARGV[0]));
            SELF[e_name] = null;
        };
    } else {
        debug(format('%s: package %s not part of the configuration, nothing done',OBJECT,ARGV[0]));
    };

    SELF;
};

########################################################
#
# Add package to the package list
#
# pkg_add <name> [version] [arch]
#
# examples:
#
# add emacs-19.34.i386 to the profile
# "/software/packages"=pkg_add("emacs","19.34","i386");
#
# add the most recent of emacs to the profile
# "/software/packages"=pkg_add("emacs");
#
# Only the <name> is mandatory.
#
# If [version] or [arch] are not defined, YUM will determine what is
# appropriate.
#
# pkg_add() is a wrapper of pkg_repl() that is the real workhorse.
#
########################################
function pkg_add = {
    debug(format('%s: adding package %s',OBJECT,ARGV[0]));

    version = undef;
    arch = undef;
    if( (ARGC == 0) || (ARGC > 3) ) {
        error('Usage: pkg_add requires 1 argument and accepts up to 3 arguments');
    };

    if( ARGC > 1 ) {
        version = ARGV[1];
    };

    if( ARGC > 2 ) {
        arch = ARGV[2];
    };

    pkg_repl(ARGV[0], version, arch, list('addonly'));
};

########################################################
#
# Replace package in the list
#
# pkg_repl <name> <new version> <arch> [<options>]
#
# In fact pkg_repl() is the real workhorse of pkg_add/pkg_del/pkg_repl/pkg_ronly.
# Other functions are just wrappers of pkg_repl(). 'options' argument
# is used to tailor this function behaviour for a particular purpose
# and is normally used only by other pkg_xxx functions.
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

    if( (ARGC == 0) || (ARGC > 4) ) {
        error('Usage: pkg_add requires 1 argument and accepts up to 4 arguments');
    };

    version = undef;
    arch = undef;
        
    if ( (ARGC == 1) || ( (ARGC > 1) && (ARGV[1] == '') ) ) {
        if ( is_list(package_default[u_name]) ) {
            version = package_default[u_name][0];
            if ( exists(package_default[u_name][1]) ) {
                arch = package_default[u_name][1];
            };
        };
    } else {
        version = ARGV[1];
        if ( (ARGC == 3) && (ARGV[2] != '') ) {
          arch = ARGV[2];
        };
    };

    if ( ARGC == 4 ) {
        options = ARGV[3];
    } else {
        options = list();
    };
    
    if ( exists(SELF[e_name]) ) {
        # addonly option means the package must not be part of the configuration to be added (pkg_add).
        # It is considered an error if the package is already part of the configuration.
        if ( index('addonly',options) < 0 ) {
            package_params = SELF[e_name];
        } else {
            error(format('Package %s is already part of the profile',ARGV[0]));
        };
    } else {
        # mustexist option means the package must be replaced only if it is already part of the configuration (pkg_ronly).
        # If it is not part of the configuration, do nothing (but don't raise an error).
        if ( index('mustexist',options) < 0 ) {
            debug(format('%s: package %s not part of the configuration, not replacing it',OBJECT,ARGV[0]));
            return(SELF);
        };
        package_params = undef;
        SELF[e_name] = nlist();
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
        SELF[e_name][version_e] = arch_params;
    } else {
        # Refuse to replace an explicit version by an undefined version
        if ( is_defined(package_params) ) {
            error(format('Attempt to unlock version of package %s (version %s)',ARGV[0],unescape(key(package_params,0))));
        };
    };
    
    SELF;
};


########################################################
#
# Replace package in the list ONLY if present
#
# pkg_ronly <name> <new version> <arch>
#
# Same as pkg_repl() except that if no version existed in the profile,
# NO new version is added. See pkg_repl() for argument documentation.
#
# This function is a wrapper of pkg_repl().
#
########################################

function pkg_ronly = {
    debug(format('%s: replacing package %s if currently present',OBJECT,ARGV[0]));

    version = undef;
    arch = undef;
    if( (ARGC == 0) || (ARGC > 3) ) {
        error('Usage: pkg_ronly requires 1 argument and accepts up to 3 arguments');
    };

    if( ARGC > 1 ) {
        version = ARGV[1];
    };

    if( ARGC > 2 ) {
        arch = ARGV[2];
    };

    pkg_repl(ARGV[0], version, arch, list('mustexist'));
};
