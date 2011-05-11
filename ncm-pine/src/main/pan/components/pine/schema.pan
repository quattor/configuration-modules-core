# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/pine/schema;

include {'quattor/schema'};


type component_pine_type = {
  include structure_component 
  
	'userdomain' ? string 	# "User Domain in From: field"
	'smtpserver' ? string 	# "SMTP server used for posting"
	'nntpserver' ? string 	# "NNTP server"
	'inboxpath' ? string 	# "path to the INBOX folder"
	'foldercollection' ? string 	# "path to additional folders"
	'ldapservers' ? string 	# "LDAP server and parameters for directory lookups"
	'ldapnameattr'  ? string 	# "which LDAP attribute to map to name"
	'disableauth'  ? string 	# "authentication methods to disable"
};

bind "/software/components/pine" = component_pine_type;


