object template dnf_ssl_none;

include 'dnf_base_config';

prefix "/software/repositories/0";
"name" = "test_repo";
"owner" = "test@example.com";
"protocols/0/name" = "http";
"protocols/0/url" = "http://mirror.example.com/repo";
