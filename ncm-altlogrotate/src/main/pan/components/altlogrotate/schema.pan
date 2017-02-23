${componentschema}

include 'quattor/types/component';
include 'pan/types';

type structure_altlogrotate_scripts = {
    'prerotate' ? string
    'postrotate' ? string
    'firstaction' ? string
    'lastaction' ? string
};

type structure_altlogrotate_create_params = {
    'mode' : string with match(SELF, '^0[0-7]{3,3}$')
    'owner' : string
    'group' : string
};

type structure_altlogrotate_logrot = {
    'pattern' ? string
    @{part of global configuration file, requires an entry called 'global'.
      The 'global' entry does not require the global flag.}
    'global' ? boolean
    @{Create and overwrite configfile with the entry as filename,
      if it previously existed (only non-global files).
      (If such file does not exist, use the ncm-altlogrotate suffix as usual)}
    'overwrite' ? boolean

    'include' ? string

    'compress' ? boolean
    'copy' ? boolean
    'copytruncate' ? boolean
    'delaycompress' ? boolean
    'ifempty' ? boolean
    'missingok' ? boolean
    'sharedscripts' ? boolean
    'dateext' ? boolean

    'compresscmd' ? string
    'uncompresscmd' ? string
    'compressext' ? string
    'compressoptions' ? string

    'create' ? boolean
    'createparams' ? structure_altlogrotate_create_params

    'extension' ? string

    'mail' ? type_email
    'nomail' ? boolean
    'mailselect' ? string with match(SELF, '^(first|last)$')

    'olddir' ? string
    'noolddir' ? boolean

    'rotate' ? long(0..)
    'start' ? long(0..)

    'size' ? string with match(SELF, '^\d+[kM]?$')

    'taboo_replace' ? boolean
    'tabooext' ? string[]

    'frequency' ? string with match(SELF, '^(daily|weekly|monthly)$')

    'scripts' ? structure_altlogrotate_scripts
} with {
    if (exists(SELF['pattern']) && exists(SELF['include'])) {
        error('altlogrotate entry: pattern and include are mutually exclusive');
    };
    true;
};

type altlogrotate_component = {
    include structure_component
    @{Logrotate configuration file location, defaults to /etc/logrotate.conf.}
    'configFile' : string = '/etc/logrotate.conf'
    @{Logrotate entries directory path, defaults to /etc/logrotate.d,
      entries will be written to individual config files under this path.}
    'configDir' : string = '/etc/logrotate.d'
    @{A named list containing logrotate structures.
      Follows the logrotate config format, so see 'man 8 logrotate'
      for a detailed explanation of all options.
      The 'global' entry (if exists) is put at the beginning of the main configuration.}
    'entries' : structure_altlogrotate_logrot{}
} with {
    if(!exists(SELF['entries']['global'])) {
        foreach(name; entry; SELF['entries']) {
            if(exists(entry['global']) && entry['global']) {
                error(format("Cannot have altlogrotate entry %s (with global=true) without 'global' entry", name));
            };
        };
    };
    true;
};
