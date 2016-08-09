# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/download/schema;

include { "quattor/schema" };

type component_download_file = {
    "href"    : string
    "post"    ? string
    "proxy"   : boolean = true
    "gssapi"  ? boolean
    "perm"    ? string
    "owner"   ? string
    "group"   ? string
    "min_age" : long = 0     # Don't consider the remote file to be new until it is this number of minutes old
    "cacert"  ? string
    "capath"  ? string
    "cert" ? string
    "key" ? string
    "timeout" ? long # seconds, overrides setting in component
};

type component_download_type = extensible {
    include structure_component
    "server" ? string
    "proto"  ? string with match(SELF, "https?")
    "files"  ? component_download_file{}
    "proxyhosts" ? string[]
    "head_timeout" ? long # seconds, timeout for HEAD requests which checks for changes
    "timeout" ? long # seconds, total timeout for fetch of file, can be overridden per file
};

bind "/software/components/download" = component_download_type;

