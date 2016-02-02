object template default;

include 'metaconfig/lmod/config';

prefix "/software/components/metaconfig/services/{/etc/lmodrc.lua}/contents/prop";
"state/experimental" = dict(
    "short", list("E"),
    "long", list("E"),
    "color", "blue",
    "doc", "Experimental",
);
"state/testing" = dict(
    "short", list("T"),
    "long", list("T"),
    "color", "green",
    "doc", "Testing",
);
"state/obsolete" = dict(
    "short", list("O"),
    "long", list("O"),
    "color", "red",
    "doc", "Obsolete",
);
"lmod/sticky" = dict(
    "short", list("S"),
    "long", list("S"),
    "color", "red",
    "doc", "Module is Sticky, requires --force to unload or purge",
);
"arch/mic" = dict(
    "short", list("m"),
    "long", list("m"),
    "color", "blue",
    "doc", "built for host and native MIC",
);
"arch/offload" = dict(
    "short", list("o"),
    "long", list("o"),
    "color", "blue",
    "doc", "built for offload to the MIC only",
);
"arch/gpu" = dict(
    "short", list("g"),
    "long", list("g"),
    "color", "red",
    "doc", "built for GPU",
);
"arch/mo" = dict(
    "names", list("mic", "offload"),
    "short", list("*"),
    "long", list("m", "o"),
    "color", "blue",
    "doc", "built for host, native MIC and offload to the MIC",
);
"arch/gm" = dict(
    "names", list("gpu", "mic"),
    "short", list("g", "m"),
    "long", list("g", "m"),
    "color", "red",
    "doc", "built natively for MIC and GPU",
);
"arch/gmo" = dict(
    "names", list("gpu", "mic", "offload"),
    "short", list("@"),
    "long", list("g", "m", "o"),
    "color", "red",
    "doc", "built natively for MIC and GPU and offload to the MIC",
);
prefix "/software/components/metaconfig/services/{/etc/lmodrc.lua}/contents";
"scDescript/0" = dict(
    "timestamp", "/some/path0",
    "dir", "/some/dir0",
);
"scDescript/1" = dict(
    "timestamp", "/some/path1",
    "dir", "/some/dir1",
);
