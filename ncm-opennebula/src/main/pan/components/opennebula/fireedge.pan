# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/fireedge;


@documentation{
Guacamole daemon.
}
type opennebula_fireedge_guacd = {
    "port" : type_port = 4822
    "host" : string = 'localhost'
} = dict();

@documentation{
Local zone in a Federation setup.
This attribute must point to the Zone ID of the local OpenNebula to which this FireEdge belongs to.
}
type opennebula_fireedge_zone = {
    "id" : long(0..) = 0
    "name" : string = 'OpenNebula'
    "endpoint" : type_absoluteURI = 'http://localhost:2633/RPC2'
} = dict();

@documentation{
Type that sets OpenNebula fireedge-server.conf file:
https://docs.opennebula.io/7.0/product/operation_references/opennebula_services_configuration/fireedge
}
type opennebula_fireedge = {
    @{System log (Morgan) prod or dev}
    "log" : string = 'prod' with match (SELF, '^(prod|dev)$')
    @{Enable CORS (cross-origin resource sharing)}
    "cors" : boolean = true
    @{IP on which the FireEdge server will listen}
    "host" : type_ipv4 = '127.0.0.1'
    @{Port on which the FireEdge server will listen}
    "port" : type_port = 2616
    @{OpenNebula: use it if you have oned and fireedge on different servers}
    "one_xmlrpc" : type_absoluteURI = 'http://localhost:2633/RPC2'
    @{Flow Server: use it if you have flow-server and fireedge on different servers}
    "oneflow_server" : type_absoluteURI = 'http://localhost:2474'
    @{JWT expiration time (minutes)}
    "session_expiration" : long(1..) = 180
    @{JWT expiration time when using remember check box (minutes)}
    "session_remember_expiration" : long(1..) = 3600
    @{Minimum time to reuse previously generated JWTs (minutes)}
    "minimum_opennebula_expiration" : long(1..) = 30
    @{Endpoint to subscribe for OpenNebula events must match those in oned.conf}
    "subscriber_endpoint" : string = 'tcp://localhost:2101'
    @{Log debug level: https://github.com/winstonjs/winston
    0 = ERROR, 1 = WARNING, 2 = INFO, 5 = DEBUG}
    "debug_level" : long(0..5) = 2
    @{Maximum length of log messages (chars).
    Messages exceeding this limit will be truncated.
    -1 => No limit}
    "truncate_max_length" : long(-1..) = 150
    @{This configuration option sets the maximum time (in milliseconds) that the application
    will wait for a response from the server before considering the request as timed out.
    If the server does not respond within this timeframe, the request will be aborted,
    and the connection will be closed.}
    "api_timeout" : string = '120_000'
    @{Authentication driver for incoming requests
    opennebula: the authentication will be done by the opennebula core using the
    driver defined for the user.
    remote: performs the login based on a Kerberos X-Auth-Username header
    provided by authentication backend.}
    "auth" : string = 'opennebula' with match (SELF, '^(opennebula|remote)$')
    "guacd" : opennebula_fireedge_guacd
    "default_zone" : opennebula_fireedge_zone
    @{This configuration is for the login button redirect. The available options are: "/", "." or a URL}
    "auth_redirect" ? string
};
