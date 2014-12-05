### NAME

ldconf: NCM component to manage `/etc/ld.so`.conf file.

### DESCRIPTION

The _ldconf_ component manages the `/etc/ld.so`.conf file.  This
component can only ensure that listed directories exist in the
`/etc/ls.so`.conf file; it cannot remove entries previously added by
this component.

### RESOURCES

#### `/software/components/ldconf/conffile`

The configuration file to manage.  Should be set to `/etc/ld.so`.conf
unless your doing something unusual. 

#### `/software/components/ldconf/paths`

List of paths to ensure are in the ld.so.conf configuration file. 
