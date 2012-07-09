# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/srvtab/schema;

include {'quattor/schema'};


type component_srvtab_type = {
  include component_type

   "server"    : string 	# "arc server to contact"
   "overwrite" : boolean 	# "overwrite current rvtab/krb5.keytab
   "verbose"   : boolean 	# "tell the script creting the credentials to be verbose"
};

bind "/software/components/srvtab" = component_srvtab_type;
