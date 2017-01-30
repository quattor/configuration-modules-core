declaration template metaconfig/moab/schema;

include 'pan/types';

@documentation{
    The moab_service_legacy type corresponds to the schema for the old ncm-moab,
    except for the include attribute, which is now a list of absolute filenames
    (and setting the content of the include files is not supported anymore)
}

@{moab fairshare configuration attributes}
type moab_fairshare_configuration = {
    'fsdecay' ? double
    'fsdepth' ? long
    'fsinterval' ? string
    'fspolicy' ? string with index(SELF, list('DEDICATEDPS', 'DEDICATEDPES', 'DEDICATEDPS%', 'UTILIZEDPS')) >= 0
    'fsuserweight' ? long
    'fsgroupweight' ? long
    'fsaccountweight' ? long
    'fsgaccountweight' ? long
};

@{moab priority configuration attributes}
type moab_priority_configuration = {
    'classweight' ? long
    'credweight' ? long
    'fsweight' ? long
    'queuetimeweight' ? long
    'userweight' ? long
    'xfactorweight' ? long
};

@{moab policy configuration attributes}
type moab_policy_configuration = {
    'enablenegjobpriority' ? boolean
    'backfillpolicy' ? string with match(SELF, '^(FIRSTFIT)$')
    'backfilldepth' ? long
    'nodeallocationpolicy' ? string with match(SELF, '^(PRIORITY)$')
    'reservationpolicy' ? string with match(SELF, '^(CURRENTHIGHEST)$')
};

type moab_service_legacy = {
    'sched' ? string[]{}
    'rm' ? string[]{}
    'am' ? string[]{}
    'id' ? string[]{}
    'user' ? string[]{}
    'group' ? string[]{}
    'node' ? string[]{}
    'account' ? string[]{}
    'class' ? string[]{}
    'qos' ? string[]{}
    'main' : string{}
    'priority' ? moab_priority_configuration
    'fairshare' ? moab_fairshare_configuration
    'policy' ? moab_policy_configuration
    'include' ? string[]
};
