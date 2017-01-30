# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/nscd/schema;

include 'quattor/schema';

type componend_nscd_service_type = {
    "enable-cache" ? legacy_binary_affirmation_string
    "positive-time-to-live" ? long
    "negative-time-to-live" ? long
    "suggested-size" ? long
    "check-files" ? legacy_binary_affirmation_string
    "persistent" ? legacy_binary_affirmation_string
    "shared" ? legacy_binary_affirmation_string
    "max-db-size" ? long
    "auto-propagate" ? legacy_binary_affirmation_string
};

type component_nscd_type = {
    include structure_component

    "logfile" ? string
    "debug-level" ? string
    "threads" ? long
    "max-threads" ? long
    "server-user" ? string
    "stat-user" ? string
    "reload-count" ? string
    "paranoia" ? legacy_binary_affirmation_string
    "restart-interval" ? long

    "passwd" ? componend_nscd_service_type
    "group" ? componend_nscd_service_type
    "hosts" ? componend_nscd_service_type
};

bind "/software/components/nscd" = component_nscd_type;
