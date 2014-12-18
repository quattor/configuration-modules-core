object template forwarder;

include 'metaconfig/logstash/forwarder';

prefix "/software/components/metaconfig/services/{/etc/logstash-forwarder}/contents";

"network/servers/0" = nlist("host", "myhost", "port", 12345);
"network/servers/1" = nlist("host", "myhost2", "port", 12346);
"network/ssl_key" = "/my/key";
"network/ssl_certificate" = "/my/cert";
"network/ssl_ca" = "/my/ca";
"files/0/paths" = list("/path/0/0", "/path/0/1");
"files/0/fields" = nlist("type", "type0");
"files/1/paths" = list("/path/1/0", "/path/1/1");
"files/1/fields" = nlist("type", "type1");

