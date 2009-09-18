# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/spma/functions;

variable DEF = "";

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
        i = next(item_list,t,curr_item);
    };
    debug("Item " + name + " does not exist in " + ARGV[1]);
    return(false);
};



########################################################
#
# Automatically fill "repository" field for package list
#
# resolve_pkg_rep <repository list>
#
########################################################

function resolve_pkg_rep = {
    error=0;
    errorstr="";
    rep_list = ARGV[0];
    debug("Assigning repositories to packages...");

    foreach (name;pkg_list_name;SELF) {
      foreach (version;pkg_list_name_version;pkg_list_name) {
        foreach (a_list;pkg_list_name_version_arch;pkg_list_name_version["arch"]) {
          debug ("Processing package " + unescape(name) + " version " + unescape(version) + "arch " + pkg_list_name_version_arch);
          id = escape(unescape(name) + "-" + unescape(version) + "-" + pkg_list_name_version_arch);
          if (exists(pkg_list_name_version["repository"])) {
            rep_mask = pkg_list_name_version["repository"];
            pkg_list_name_version["repository"] = null;
          } else {
            rep_mask = "";
          };

          rep_not_found = first(rep_list,t,curr_rep);
          while (rep_not_found) {
            if(match(curr_rep["name"],rep_mask) && exists(curr_rep["contents"][id])) {
              debug("Package " + unescape(name) + " - assigned repository " + curr_rep["name"]);
              pkg_list_name_version["repository"] = curr_rep["name"];
              rep_not_found = false;
            } else {
              rep_not_found = next(rep_list,t,curr_rep);
            };
          };
          
          if( !exists(SELF[name][version]["repository"]) ) {
            errorstr = errorstr+"\n  name: "+unescape(name)+" version: "+unescape(version)+" arch: "+pkg_list_name_version_arch+"";
            error=error+1;
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
# pkg_repl <name> <new version> <arch> [options] [flags] [repository]
#
# In fact pkg_repl() is the real workhorse of pkg_add/pkg_del/pkg_repl/pkg_ronly.
# Other functions are just wrappers of pkg_repl(). 'options' argument
# is used to tailor this function behaviour for a particular purpose.
#
# 'options' allows to specify a specific version to replace and/or
# flags to modify pkg_repl behaviour. This argument can  be a string or
# a list of string if several options are specified together.
# Possible flags are :
#   - 'samearch' to indicate that a previous version is replaced only
#     if it is for the same architecture
#   - 'allarchs' to cancel 'samearch' behaviour
#   - 'delete' to delete an existing package without replacing it (in this
#     case name/version/arch arguments specify the package to delete and
#     version specified in options is ignored)
#   - 'ronly' : replace an existing package, else do nothing
#   - 'addonly' : add a new package but fail if the package already exists
#   - 'multi' : allow multiple version of a package when adding a package (addonly
#     option must be specified too).
#
# if options is not specified, all versions are replaced but only
# it they are for the same architecture (samearch).
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

    multiarch = true;
    deleteonly = false;
    mustexist = undef;        # 'mustexist' is a 3-state variable (undef, true, false)
    singleversion = true;     # 'mustexist' must be false (strict add) for singleversion=false to be used
    options  = undef;
    old_version = DEF;
    if( ARGC > 3 ) {
      if ( is_list(ARGV[3]) ) {
        options = ARGV[3];
      } else {
        options = list(ARGV[3]);
      };
    };
    if( is_defined(options) ) {
      foreach (i;option;options) {
        if ( option == "samearch" ) {
          multiarch = true;
        } else if ( option == "allarchs" ) {
          multiarch = false;
        } else if ( option == "delete" ) {
          deleteonly = true;
        } else if ( option == "ronly" ) {
          mustexist = true;
        } else if ( option == "addonly" ) {
          mustexist = false;
        } else if ( option == "multi" ) {
          singleversion = false;
        } else {
          old_version = option;
          debug ("    old version being replaced: "+old_version);
        };
      };

      # To simplify further processing, reset singleversion to true if
      # 'mustexist' option is not false (strict add). singleversion=false
      # is meaningful and allowed only if mustexist=false.
      if ( !singleversion && (!is_defined(mustexist) || mustexist) ) {
        debug ("   singleversion reset to false as mustexist is not false");
        singleversion = true;
      };
    };

    # Retrieve package version : it is mandatory except for delete
    if (ARGC > 1 && ARGV[1] != DEF) {
      version = ARGV[1];
    } else {
      if ( deleteonly ) {
        version = DEF;
      } else {
        if (exists(package_default[u_name][0])) {
          version = package_default[u_name][0];
        } else {
          error("no default package version defined for package: "+name);
        };
      };
    };
    e_version = escape(version);

    # If 'deleteonly' option is present, version to delete is the 2nd arg (package version)
    if ( deleteonly ) {
      old_version = version;
      debug ("   old version being deleted: '"+old_version+"'");
    };

    # Retrieve package architecture
    if (ARGC > 2 && ARGV[2] != DEF) {
      arch = ARGV[2];
    } else {
      if (exists(package_default[u_name][1])) {
        arch = package_default[u_name][1];
      } else {
        if ( !deleteonly || multiarch ) {
          error("no default package architecture defined for package: "+name);
        };
        # fix bug #19060
        arch = "";
      };
    };

    if(ARGC > 4) {
      flags = ARGV[4];
    } else {
      flags = DEF;
    };

    if(ARGC > 5) {
      rep = ARGV[5];
    } else {
      rep = DEF;
    };

    # Check if version to be added/replaced/deleted already exists
    debug("Checking if package " + name + " version '"+ old_version + "' arch '" + arch + "' exists");
    e_old_version = escape(old_version);
    pkg_found = nlist();            # Will track the version of the same package with the same arch already present
    pkg_found_identical = false;    # Will track if the same package version/arch is already present
    versions_to_delete = list();
    if ( exists(SELF[e_name]) && is_defined(SELF[e_name]) ) {
      debug('Package found. Checking arch and version...');
      foreach (current_version;current_pkg;SELF[e_name]) {
        cur_pkg_found = undef;
        cur_pkg_identical = false;
        if( (old_version == DEF) || (e_old_version == current_version) ) {
          # Process only arch matching the package passed as an argument
          if ( multiarch ) {
            if ( !is_defined(SELF[e_name][current_version]["arch"]) ) {
              error("arch missing for package "+name+" version "+unescape(current_version));
            };
            if ( !is_defined(arch) ) {
              error("Error deleting version "+unescape(current_version)+" : no arch specified");
            };
            newarchlist=list();
            foreach (j;current_arch;SELF[e_name][current_version]["arch"]) {
              if ( arch == current_arch ) {
                cur_pkg_found = current_version;
              } else {
                newarchlist[length(newarchlist)] = current_arch;
              };
            };
          # Process all archs: don't keep any arch if the version must be deleted
          } else {
            debug('Processing all archs for package '+name);
            newarchlist = list();
            cur_pkg_found = current_version;
          };
          
          # mustexist=true or undef
          # Existing version must be removed except if this is the same one as the
          # one to add/replace (deleteonly=false).
          # Do the appropriate action depending on other archs being present:
          # if yes, update the arch list for the package/version entry, else remove
          # the version entry.
          if ( !is_defined(mustexist) || mustexist  ) {
            if ( deleteonly || (is_defined(cur_pkg_found) && (cur_pkg_found!=e_version)) ) {
              if ( length(newarchlist) == 0 ) {
                versions_to_delete[length(versions_to_delete)] = current_version;
              } else {
                debug('Redefining list of installed arch for version '+unescape(current_version)+' ('+to_string(newarchlist)+')');
                SELF[e_name][current_version]["arch"] = newarchlist;
              };              
            }
          };
        };
        
        if ( is_defined(cur_pkg_found) ) {
          pkg_found[cur_pkg_found] = true;    # Value is meaningless
        };
      };
      
      if ( exists(pkg_found[e_version]) ) {
        pkg_found_identical = true;
      };
      
      if ( length(pkg_found) == 0 ) {
        debug("Package "+name+" version '"+old_version+"' arch '"+arch+"' not present in current configuration");
      } else {
        # mustexist=false (strict add) : if another version is already present and
        # 'multi' option has not been specified (singleversion=true), throw an error.
        # If the same version/arch (and only this one) is already present, just do nothing.
        if ( is_defined(mustexist) && !mustexist && singleversion ) {
          if ( pkg_found_identical && (length(pkg_found) == 1) ) {
            debug('Package '+name+' ('+version+','+arch+') already present in the profile with the same version/arch: nothing done.');
            return(SELF);
          } else {
            installed_vers = list();
            foreach (k;v;pkg_found) {
              installed_vers[length(installed_vers)] = unescape(k);
            };
            error ("Package "+name+" ("+arch+") already present in profile, without multi-version option (version requested="+
                                          version+",present="+to_string(installed_vers)+")");                
          };
        };
      };

      # Delete versions marked for deletion
      if ( length(versions_to_delete) > 0 ) {
        foreach (i;v;versions_to_delete) {
          debug('Deleting version '+unescape(v)+' (all archs)');
          SELF[e_name][v] = null;
        };
        if (!first(SELF[e_name], x_a, x_b)) {
          SELF[e_name] = null;
        };
      };
    };

    # If package is not yet present in the profile, check if strict
    # replace (no implicit add) has been requested.
    if ( is_defined(mustexist) && mustexist && (length(pkg_found) == 0) ) {
      debug('mustexist=true (ronly) but package not found in profile: nothing done.');
      return (SELF);
    };

    # Replace package except if 'delete' option as been specified.
    if ( !deleteonly ) {
      if ( pkg_found_identical ) {
        debug("Package "+name+" version "+version+" arch "+arch+" already present");
      } else {
        debug("Adding package " + name + " new version: "+ version + " arch " + arch);
        if ( multiarch ) {
          if ( !is_defined(SELF[e_name][e_version]["arch"]) ) {
            SELF[e_name][e_version]["arch"] = list();
          };
          SELF[e_name][e_version]["arch"][length(SELF[e_name][e_version]["arch"])]=arch;
        } else {
          SELF[e_name][e_version]["arch"] = list(arch);
        };
      };
      if(is_nlist(flags)) {
            SELF[e_name][e_version]["flags"] = flags;
      };
      if(rep != DEF) {
        SELF[e_name][e_version]["repository"] = rep;
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
