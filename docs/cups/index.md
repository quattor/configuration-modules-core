---
layout: documentation
title: cups
category: documentation
subcategory: components
menu: 'components.md'
---
Be sure to put a blank line before and after every formatting command

### NAME

cups : CUPS configuration component

### DESCRIPTION

NCM component allowing to configure CUPS service and declare printers.

### RESOURCES

#### `/software/components/cups/defaultprinter` : string (optional)

Define the printer specified as the default printer. Printer must be listed in the printers list to be defined as 
the default printer.

#### `/software/components/cups/nodetype` : string (optional)

Possible values are "client" and "server". "server" must be specified to start cupsd daemon. 
When "client" is specified and cupsd is running, it is stopped.

Default : "server" on machine defined in "options/ServerName" or if this option is not defined (server assumed 
to be localhost), "client" on other machines.

#### `/software/components/cups/options`/... : nlist (optional)

This ressource is a list of properties corresponding to option keywords supported by CUPS configuration 
files (cupsd.conf and client.conf). See the configuration files provided by CUPS for the documentation about 
each possible option. It is a nlist where the key is the option name and the value the option value.

An empty value is interpreted as "undefine the option". If present, the matching configuration line is 
commented out. To define an option with an empty value, you need to specify a value made of spaces.

Generally, options apply either to server configuration or to client configuration. There is 
one exception, ServerName, which applies to both.

Note : not all the options are currently implemented. If you get a message 'unsupported option' when 
running this component, look at the comments at the beginning of component Perl source about how to add 
support for a new option.

#### `/software/components/cups/options/ServerName` : string

This option is a special case. It is used by both client and server. In the server configuration, if not defined 
or defined as local host, it is converted to the local host name. In client configuration file, if ServerName 
points to the current host, it is converted to "127.0.0.1" (CUPS default).

D: localhost (CUPS default)

Scope : client and server

#### `/software/components/cups/printers`/... : nlist (optional)

List of printers to configure if the current node is the server node. This resource is a nlist where the key is 
the printer name. In addition to standard CUPS printer options (look at lpadmin 
documentation), the following printer properties are defined :

##### delete : boolean

Allow to delete a printer previously defined. Deleting a non existent printer is not considered an error.

If a node configuration contains both definition and deletion for the same printer, the printer is deleted. 
This allows for a common configuration with some printers defined and a node specific configuration where 
some printers are not defined.

If delete is true, all other options are ignored.

Default : no

##### enable : boolean

If this property is false, allow to disable a printer (without deleting it).

If a node configuration both enable and disable printer, the printer is enabled. This allows for a common 
configuration where printers are created disabled and enable on a per node basis.

Default : yes

##### printer : string

Define the printer/queue name on the server associated with this printer. For LPD, need to match a printcap entry.

Use to build the printer URI.

##### protocol : string

Define the protocol part of the printerr URI (CUPS backend).

Use to build the printer URI.

##### server : string

Define the server part of the printer URI.

Use to build the printer URI.

### DEPENDENCIES

None.

### BUGS

None known.

Michel Jouvin <jouvin@lal.in2p3.fr>

Luis Fernando Muñoz Mejías <>

### VERSION

2.0.0

### SEE ALSO

ncm-ncd(1), cupsd(8), lpadmin(8)
