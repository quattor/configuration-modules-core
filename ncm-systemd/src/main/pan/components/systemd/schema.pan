# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/schema;

include 'quattor/schema';

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
};

type component_${project.artifactId}_type = {
    include structure_component
    # TODO: only ignore implemented so far. To add : disabled and/or masked
    "unconfigured" : string = 'ignore' with match (SELF, '^(ignore)$') # harmless default
    # escaped full unitnames are allowed (or use shortnames and type)
    "unit" : ${project.artifactId}_unit_type{}
};
