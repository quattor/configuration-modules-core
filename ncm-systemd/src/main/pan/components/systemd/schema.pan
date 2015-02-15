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

type ${project.artifactId}_service_type = {
    "name" ? string
    "state" : string = 'enabled' with match(SELF,"^(enabled|disabled|masked)$")
    "targets" : ${project.artifactId}_target[] = list("multi-user") 
    "startstop" : boolean = true
    "type" : string = 'service' with match(SELF, '^(service|target|sysv)$')
};

type component_${project.artifactId}_type = {
    include structure_component
    "service" : ${project.artifactId}_service_type{}
    # TODO: only ignore implemented so far. To add : disabled and/or masked
    "unconfigured" : string = 'ignore' with match (SELF, '^(ignore)$') # harmless default
};
