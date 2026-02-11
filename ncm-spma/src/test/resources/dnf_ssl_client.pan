object template dnf_ssl_client;

include 'dnf_base_config';

prefix "/software/repositories/0";
"name" = "ssl_client_repo";
"owner" = "test@example.com";
"protocols/0/name" = "https";
"protocols/0/url" = "https://secure.example.com/repo";
"protocols/0/clientcert" = "/etc/pki/client/cert.pem";
"protocols/0/clientkey" = "/etc/pki/client/key.pem";
