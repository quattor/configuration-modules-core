declaration template metaconfig/opennebula/schema;

include 'pan/types';

@documentation{
aii/opennebula.conf sections.
url: OpenNebula RPC endpoint type absoluteURI as example:
     "url" = "https://localhost:2366/RPC2"
pattern: a valid regular expression to match a VM fqdn.
If the VM fqdn match the pattern the aii will use this section
instead of [VM_DOMAIN].
The search proceeds through patterns from start to end,
stopping at the first match found, if not [VM_DOMAIN] is used instead.
And finally if [VM_DOMAIN] does not exist the aii will use [rpc] default section.
}
type aii_section = {
    "password" : string
    "user" ? string
    "pattern" ? string
    "url" ? type_absoluteURI with match (SELF, "^http.+/RPC2$")
    @{set CA certificate location for SSL connections}
    "ca" ? string
} = dict();

@documentation{
aii/opennebula.conf sections
This is a dictionary (to generate a section per rpc endpoint)
of dictionaries (to include the endpoint options)
}
type aii_opennebula_conf = aii_section{};
