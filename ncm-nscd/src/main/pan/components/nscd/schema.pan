# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/nscd/schema;

include {'quattor/schema'};

type componend_nscd_service_type = {
     "enable-cache"           ? string with match (self, '(yes|no)')
     "positive-time-to-live"  ? long
     "negative-time-to-live"  ? long
     "suggested-size"         ? long
     "check-files"            ? string with match (self, '(yes|no)')
     "persistent"             ? string with match (self, '(yes|no)')
     "shared"                 ? string with match (self, '(yes|no)')
     "max-db-size"            ? long
     "auto-propagate"         ? string with match (self, '(yes|no)')
};

type component_nscd_type = {
    include structure_component

    "logfile"          ? string
    "debug-level"      ? string
    "threads"          ? long
    "max-threads"      ? long
    "server-user"      ? string
    "stat-user"        ? string
    "reload-count"     ? string
    "paranoia"         ? string with match (self, '(yes|no)')
    "restart-interval" ? long

    "passwd" ? componend_nscd_service_type
    "group"  ? componend_nscd_service_type
    "hosts"  ? componend_nscd_service_type
};

type "/software/components/nscd" = component_nscd_type;

