${componentschema}

include 'quattor/types/component';

type component_download_file = {
    @{A URL (either absolute, or relative) that describes the source of the
      file. The URL can be specified as relative by ommitting the server
      name and/or the protocol, in which case the component defaults will be
      used. Local files can be used as source, such as
      file://localhost/etc/foo.txt or even file:///etc/foo.txt.}
    "href"    : string
    @{Specify the command (no options allowed) to run
      whenever the file is updated.
      The filename is added as first and (only) argument.
      Note that if the update is
      optimised away by the download process (e.g. if the file is
      already up-to-date), the command will still be executed, so it
      is the responsibility of this command to determine what work
      needs to be done, if any.}
    "post"    ? string
    @{If false, then the proxy configuration will be ignored for
      this file. This has no effect when there are no proxy hosts defined.}
    "proxy"   : boolean = true
    @{If true, then curl/LWP will be invoked with GSSAPI Negotiate
      extension enabled, using the host keytab as the identity.}
    "gssapi"  ? boolean
    @{Sets the permissions of the file to the defined
      permissions (defined in octal, e.g. 0644).}
    "perm"    ? string
    @{Sets the ownership to given user (name or number).}
    "owner"   ? string
    @{Sets the group ownership to the given group (name or number).}
    "group"   ? string
    @{Don't consider the remote file to be new until it is this number of minutes old}
    "min_age" : long = 0
    "cacert" ? string
    "capath" ? string
    "cert" ? string
    "key" ? string
    @{seconds, overrides setting in component}
    "timeout" ? long
    @{allow older remote file}
    "allow_older" ? boolean
};

type download_component = extensible {
    include structure_component
    @{The default server hostname to use for any sources which
      do not specify the source.}
    "server" ? string
    @{The default protocol to use for any sources which do not
      specify the protocol.}
    "proto"  ? string with match(SELF, "^https?$")
    @{An dict of escaped filenames required for the destination file.}
    "files"  ? component_download_file{}
    @{List of hostnames (and possibly with ':port' suffix).
      When specified, a reverse proxy configuration is assumed
      for all of the file sources. Whenever a file is downloaded, each of the
      proxy hosts will be used first before attempting the original source URL. The
      first proxy host to respond will be used for all subsequent download attempts.}
    "proxyhosts" ? type_hostport[]
    @{seconds, timeout for HEAD requests which checks for changes}
    "head_timeout" ? long
    @{seconds, total timeout for fetch of file, can be overridden per file}
    "timeout" ? long
};
