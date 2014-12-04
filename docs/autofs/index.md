---
layout: documentation
title: autofs
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

ncm-autofs: NCM component to manage autofs configuration. 

### DESCRIPTION

The _autofs_ component manages autofs master map and generated maps. It allows
both exclusive management by the component or preservation of local changes.

### RESOURCES

#### `/software/components/autofs/preserveMaster` : boolean

This flag indicated if local changes to master map must be preserved (true) or
not (false).

Default : true.

#### `/software/components/autofs/maps` : nlist

This resource contains one entry per autofs map to manage. The nlist key is
mainly an internal name but it will be used to build the default map name.

#### `/software/components/autofs/maps/XXX/enabled` : boolean

If false, ignore entries for this map (no change made).

Default : true.

#### `/software/components/autofs/maps/XXX/entries` : nlist

One entry by filesystem to mount. The key is used to build the mount point. The actual
mount point depends on map type.

Default : none.

#### `/software/components/autofs/maps/XXX/mapname` : string

Map name. If not defined, a default name is build (/etc/auto suffixed
by map entry name.

#### `/software/components/autofs/maps/XXX/mountpoint` : string

Mount point associated with this map.

Default : none.

#### `/software/components/autofs/maps/XXX/mpaliases` : string

Mount point aliases. Deprecated feature.

#### `/software/components/autofs/maps/XXX/options` : string

Mount options to be used with this map.

Default : none.

#### `/software/components/autofs/maps/XXX/preserve` : boolean

This flag indicated if local changes to the map must be preserved (true) or
not (false).

Default : true.

#### `/software/components/autofs/maps/XXX/type` : string

Map type. Supported types are : direct, file, program, yp, nisplus,hesiod, userdir, ldap.
Only direct, file and program map contents can be managed by this component.

Required. Default none.

#### `/software/components/autofs/maps/XXX/entries/YYY/location` : string

NFS server name/path associated with this entry.

Required, no default.

#### `/software/components/autofs/maps/XXX/entries/YYY/options` : string

Specific mount options to be used with this entry.

Default : none

### DEPENDENCIES

None.

### BUGS

None known.

David Groep <davidg@nikhef.nl>

David Groep <davidg@nikhef.nl>, Michel Jouvin <>

### VERSION

2.0.4

### SEE ALSO

ncm-ncd(1)


