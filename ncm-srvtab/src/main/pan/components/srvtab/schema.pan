# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/srvtab/schema;

include components/type;


type component_srvtab_type = {
  include component_type 
  
   "server"    : string 	# "arc server to contact"
   "overwrite" : boolean 	# "overwrite current rvtab/krb5.keytab
   "verbose"   : boolean 	# "tell the script creting the credentials to be verbose"
};

type "/software/components/srvtab" = component_srvtab_type;


