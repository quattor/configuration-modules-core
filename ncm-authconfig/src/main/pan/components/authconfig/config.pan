# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';

'/software/packages'=pkg_repl('ncm-${project.artifactId}','${no-snapshot-version}-${RELEASE}','noarch');

prefix '/software/components/${project.artifactId}';
'dependencies/pre' ?= list ('spma');
'active' ?= true;
'dispatch' ?= true;

"safemode" ?= false;

"useshadow" ?= true;
"usecache" ?= true;

"usemd5" ?= true;
"passalgorithm" ?= {
    if (value("/software/components/${project.artifactId}/usemd5")) {
        "md5";
    } else {
	    # Fall back to the most stupid option you can even imagine.
	    # But it is portable. Huh.
	    "descrypt";
    };
};


