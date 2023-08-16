object template sched;

include 'components/opennebula/schema';

bind "/metaconfig/contents/sched" = opennebula_sched;

"/metaconfig/module" = "sched";

prefix "/metaconfig/contents/sched";
"log" = dict(
    "system", "file",
    "debug_level", 4,
);
"sched_interval" = 5;
"live_rescheds" = 1;
"cold_migrate_mode" = 1;
"max_vm" = 9000;
