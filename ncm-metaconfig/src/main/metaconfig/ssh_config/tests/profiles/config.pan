object template config;

include 'metaconfig/ssh_config/config';

prefix "/software/components/metaconfig/services/{/etc/ssh/ssh_config}/contents";

"main/AddressFamily" = "any";
"main/IdentityFile" = list("~/.ssh/identity", "~/.ssh/id_rsa", "~/.ssh/id_dsa");
"main/Ciphers" = list("aes128-ctr","aes192-ctr","aes256-ctr","arcfour256","arcfour128","aes128-cbc","3des-cbc");

'Host' =  append(
            dict(
                "hostnames", list("hostname.example.com", "hostname4.example.com"),
                "ProxyCommand", "ssh -q -W %h:%p gateway.example.com",
                "User", "testuser",
                )
        );


'Host' =  append(
            dict(
                "hostnames", list("hostname2.example.com"),
                "ProxyCommand", "ssh -q -W %h:%p gateway2.example.com",
                "User", "testuser",
                )
        );


'Host' =  append(
            dict(
                "hostnames", list("*"),
                "GSSAPIAuthentication", true,
                "ForwardX11Trusted", true,
                "SendEnv", list("LANG", "LC_CTYPE", "LC_NUMERIC", "LC_TIME", "LC_ALL", "LC_MESSAGES", "LANGUAGE","XMODIFIERS"),
                )
        );

