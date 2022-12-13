unique template metaconfig/jaas/schema;

type jaas_application = {
    'module': string
    'flag': choice("required")
    'options': dict()
};
