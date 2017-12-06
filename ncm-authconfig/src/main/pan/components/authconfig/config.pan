${componentconfig}

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
