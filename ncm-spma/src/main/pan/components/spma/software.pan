# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/spma/software;

include 'pan/types';
include 'components/spma/functions';

type software_repository_url = string with match(SELF, '^(file|https?|ftp)://');

type SOFTWARE_PACKAGE_REP = string with repository_exists(SELF, "/software/repositories");

type SOFTWARE_PACKAGE = {
    "arch" ? string{} # architectures
};

type SOFTWARE_REPOSITORY_PACKAGE = {
    "arch" : string  # "Package architecture"
    "name" : string  # "Package name"
    "version" : string  # "Package version"
};

type SOFTWARE_REPOSITORY_PROTOCOL = {
    "name" : string  # "Protocol name"
    "url" : software_repository_url  # "URL for the given protocol"
    "cacert" ? string  # Path to CA certificate
    "clientcert" ? string # Path to client certificate
    "clientkey" ? string # Path to client key
    "verify" ? boolean # Whether to verify the SSL certificate
};

type SOFTWARE_REPOSITORY = {
    "enabled" : boolean = true
    "gpgcheck" : boolean = false
    "repo_gpgcheck" ? boolean
    "gpgkey" ? software_repository_url[]
    "gpgcakey" ? software_repository_url
    "excludepkgs" ? string[]
    "includepkgs" ? string[]
    "name" ? string with match(SELF, '^[\w-.]+$') # "Repository name"
    "owner" ? string  # "Contact person (email)"
    "priority" ? long(1..99)
    "protocols" ? SOFTWARE_REPOSITORY_PROTOCOL []
    "proxy" ? string with SELF == '' || is_absoluteURI(SELF)
    "skip_if_unavailable" : boolean = false
};
