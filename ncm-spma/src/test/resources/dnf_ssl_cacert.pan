object template dnf_ssl_cacert;

include 'dnf_base_config';

prefix "/software/repositories/0";
"name" = "ssl_cacert_repo";
"owner" = "test@example.com";
"protocols/0/name" = "https";
"protocols/0/url" = "https://secure.example.com/repo";
"protocols/0/cacert" = "/etc/pki/CA/cert.pem";
