# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/schema;

include 'quattor/types/component';

type ${project.artifactId}_skip = {
    "service" : boolean = false
};

# TODO: make this more finegrained, e.g. has to be existing unit; or check types
type ${project.artifactId}_valid_unit = string;

@documentation{
the [Unit] section
http://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BUnit%5D%20Section%20Options
}
type ${project.artifactId}_unitfile_config_unit = {
    'After' ? ${project.artifactId}_valid_unit[]
    @{start with empty string to reset previously defined paths}
    'AssertPathExists' ? string[]
    'Description' ? string
    'Requires' ? ${project.artifactId}_valid_unit[]
};

@documentation{
the [Install] section
http://www.freedesktop.org/software/systemd/man/systemd.unit.html#%5BInstall%5D%20Section%20Options
}
type ${project.artifactId}_unitfile_config_install = {
    'WantedBy' ? ${project.artifactId}_valid_unit[]
};

@documentation{
the [Service] section
http://www.freedesktop.org/software/systemd/man/systemd.service.html
}
type ${project.artifactId}_unitfile_config_service = {
    'ExecStart' ? string
    'Nice' ? long(-19..20)
    'PrivateTmp' ? boolean
    'Type' ? string
};

@documentation{
Unit configuration sections
    includes, unit and install are type agnostic
        unit and install are mandatory, but not enforced by schema (possible issues in case of config_force=true)
    the other attributes are only valid for a specific type
}
type ${project.artifactId}_unitfile_config = {
    @{list of existing/other units to base the configuration on
      (e.g. when creating a new service with a different name, based on an exsiting one)}
    'includes' ? string[]
    'install' ? ${project.artifactId}_unitfile_config_install
    'service' ? ${project.artifactId}_unitfile_config_service
    'unit' ? ${project.artifactId}_unitfile_config_unit
};

@documentation{
    Unit file configuration
}
type ${project.artifactId}_unitfile = {
    @{unitfile configuration data}
    "config" ? ${project.artifactId}_unitfile_config
    @{force unitfile configuration: if true, only the defined parameters will be used by the unit; anything else is ignored}
    "force" : boolean = false
    @{only use the unit parameters for unitfile configuration,
      ignore other defined here such as targets (but still allow e.g. values defined by legacy chkconfig)}
    "only" ? boolean
};

# legacy conversion
#   1 -> rescue
#   234 -> multi-user
#   5 -> graphical
# for now limit the targets
type ${project.artifactId}_target = string with match(SELF, "^(default|poweroff|rescue|multi-user|graphical|reboot)$");

type ${project.artifactId}_unit_type = {
    "name" ? string # shortnames are ok; fullnames require matching type
    "targets" : ${project.artifactId}_target[] = list("multi-user")
    "type" : string = 'service' with match(SELF, '^(service|target|sysv)$')
    "startstop" : boolean = true
    "state" : string = 'enabled' with match(SELF,"^(enabled|disabled|masked)$")
    @{unitfile configuration}
    "file" ? ${project.artifactId}_unitfile
};

type component_${project.artifactId} = {
    include structure_component
    "skip" : ${project.artifactId}_skip
    # TODO: only ignore implemented so far. To add : disabled and/or masked
    "unconfigured" : string = 'ignore' with match (SELF, '^(ignore)$') # harmless default
    # escaped full unitnames are allowed (or use shortnames and type)
    "unit" ? ${project.artifactId}_unit_type{}
};
