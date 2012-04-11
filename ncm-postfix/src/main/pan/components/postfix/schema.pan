# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/postfix/schema;

include { 'quattor/schema' };

type postfix_config = {
    'dummy' : string = 'OK'
} = nlist();

type postfix_component = {
    include structure_component
    'config' : postfix_config
};

bind '/software/components/postfix' = postfix_component;
