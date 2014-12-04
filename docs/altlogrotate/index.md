### NAME

ncm-altlogrotate: configuration module to control the log rotate configuration

### DESCRIPTION

The _altlogrotate_ component manages the log rotate configuration files.

It replaced the original _logrotate_ which is no longer available.

### RESOURCES

#### `/software/components/altlogrotate/entries/`

- `configFile : string`

    Logrotate configuration file location, defaults to `/etc/logrotate.conf`.

- `configDir : string`

    Logrotate entries directory path, defaults to `/etc/logrotate.d`,
    entries will be written to individual config files under this path.

#### `/software/components/altlogrotate/entries`

A named list containing logrotate structures.

Follows the logrotate config format, so see `man 8 logrotate` for a detailed explanation of all options.

- `pattern ? string`
- `global ? boolean`
- `overwrite ? boolean`
- `include ? string`
- `compress ? boolean`
- `copy ? boolean`
- `copytruncate ? boolean`
- `delaycompress ? boolean`
- `ifempty ? boolean`
- `missingok ? boolean`
- `sharedscripts ? boolean`
- `dateext ? boolean`
- `compresscmd ? string`
- `uncompresscmd ? string`
- `compressext ? string`
- `compressoptions ? string`
- `create ? boolean`
- `createparams ? structure_altlogrotate_create_params`

    `nlist` with the following structure:

    - `mode : string`

        Standard three character octal mode string.

    - `owner : string`

        Username of owner

    - `group : string`

        Group name of owner

- `extension ? string`
- `mail ? type_email`
- `nomail ? boolean`
- `mailselect ? string`
- `olddir ? string`
- `noolddir ? boolean`
- `rotate ? long(0..)`
- `start ? long(0..)`
- `size ? string`
- `taboo_replace ? boolean`
- `tabooext ? string[]`
- `frequency ? string`
- `scripts ? structure_altlogrotate_scripts`

    `nlist` with the following structure:

    - `prerotate ? string`
    - `postrotate ? string`
    - `firstaction ? string`
    - `lastaction ? string`
