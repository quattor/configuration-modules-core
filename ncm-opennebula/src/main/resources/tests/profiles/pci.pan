object template pci;

include 'components/opennebula/schema';

bind "/metaconfig/contents/pci" = opennebula_pci;

"/metaconfig/module" = "pci";

prefix "/metaconfig/contents/pci";
"filter" = list('*:*');
