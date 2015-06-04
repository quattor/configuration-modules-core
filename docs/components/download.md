### NAME

NCM::download - NCM download configuration component

### SYNOPSIS

- Configure()

    Returns
    error in case of failure.

- Unconfigure()

    not available.

### DESCRIPTION

Downloads files onto the local machine during the configuration, and
optionally post-processes the files. The download is achieved by
invoking "curl", so any URLs acceptable to curl (including local
URL's) are allowed.

### RESOURCES

- `/software/components/download/active` : boolean

    activates/deactivates the component.

- `/software/components/download/proto` : string

    The default protocol to use for any sources which do not
    specify the protocol.

- `/software/components/download/server` : string

    The default server hostname to use for any sources which
    do not specify the source.

- `/software/components/download/proxyhosts` : list

    A list of strings. Each string should be a hostname (and possibly with ':port'
    suffix). If this is specifed, then a reverse proxy configuration is assumed
    for all of the file source. Whenever a file is downloaded, each of the
    proxy hosts will be used first before attempting the original source URL. The
    first proxy host to respond will be used for all subsequent download attempts.

- `/software/components/download/files` : nlist

    An nlist keyed by the escaped filename that is required for the
    destination file. The value associated with each key should be an
    nlist containing the following values:

    - href

        A URL (either absolute, or relative) that describes the source of the
        file. The URL can be specified as relative by ommitting the server
        name and/or the protocol, in which case the component defaults will be
        used. Local files can be used as source, such as
        file://localhost/etc/foo.txt or even file:///etc/foo.txt.

    - post

        If specified, then the value will be used as a command to run
        whenever the file is updated. Note that if the update is
        optimised away by the download process (e.g. if the file is
        already up-to-date), the command will still be executed, so it
        is the responsibility of this command to determine what work
        needs to be done, if any.

    - gssapi

        If true, then curl will be invoked with GSSAPI Negotiate
        extension enabled, using the host keytab as the identity.

    - proxy

        If false, then the proxy configuration will be ignored for
        this file. This defaults to true. This has no effect when
        there are no proxy hosts defined.

    - perm

        If defined, sets the permissions of the file to the defined
        permissions (defined in octal, e.g. 0644).

    - owner

        If defined, sets the ownership to given user (name or number).

    - group

        If defined, sets the group ownership to the given group (name or number).

    - min\_age

        The minimum number of minutes old that the file must be to be considered valid for download (defaults to 0);

### FILES MODIFIED

The component download modifies only the files specified within
the configuration.

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

### EXAMPLES

    "/software/components/download/active" = true;
    "/software/components/download" = nlist(
          "server", "mydownloadserver.com",
          "proto",  "http",
    );
    "/software/components/download/files" = npush(
          escape("/etc/passwd"), nlist(
                   "href", "https://secure.my.domain",
                   "post", "/usr/local/mk_passwd"
                 ),
    );
    "/software/components/download/files" = npush(
          escape("/usr/local/foo.txt"), nlist(
                   "href", "file:///etc/foo.txt",
                   "owner", "john",
                   "perm", "0400"
                 )
    );

### BUGS

none known.

### SEE ALSO

ncm-ncd(1)
