object template server_config;

include 'metaconfig/ssh/server_config';

prefix "/software/components/metaconfig/services/{/etc/ssh/sshd_config}/contents";

"main/AddressFamily" = "any";
"main/Ciphers" = list("aes128-ctr", "aes192-ctr", "aes256-ctr");
"main/PasswordAuthentication" = false;
"main/Subsystem" = dict("sftp", "internal-sftp");

'Match' = append(
                dict(
                    "matches", list("User testuser2", "Address 192.168.0.0/16"),
                    "PasswordAuthentication", true,
                )
        );
