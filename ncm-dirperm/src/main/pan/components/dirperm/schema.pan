# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/dirperm/schema;

include { "quattor/schema" };

function dirperm_permissions_valid = {
  if ( ARGC != 1 ) {
    error('dirperm_permissions_valid : missing argument');
  };

  perm_valid=true;

  if ( SELF['type'] == 'd' ) {
     if ( !match(SELF['perm'],'^[0-7]?[0-7]{3,3}$') ) {
       perm_valid=false;
       error('dirperm : invalid permissions ('+SELF['perm']+') for directory '+SELF['path']);
     };
  } else {
     if ( !match(SELF['perm'],'^[02-6]?[0-7]{3,3}$') ) {
       perm_valid=false;
       error('dirperm : invalid permissions ('+SELF['perm']+') for file '+SELF['path']);
     };
  };

  return(perm_valid);
};

type structure_dirperm_entry = {
    'path'    : string with match(SELF, '^/')
    'perm'    : string with match(SELF,'[0-7]{3,4}')
    'owner'   : string with match(SELF, '\w+(:\w+)?')
    'type'    : string with match(SELF, 'd|f')
    'initdir' ? string[]
} with dirperm_permissions_valid(SELF);

type component_dirperm = {
    include structure_component
    'paths' ? structure_dirperm_entry[]
};

bind '/software/components/dirperm' = component_dirperm;
