# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/dirperm/schema;

include quattor/schema;

function dirperm_permissions_valid = {
  if ( argc != 1 ) {
    error('dirperm_permissions_valid : missing argument');
  };

  perm_valid=true;

  if ( self['type'] == 'd' ) {
     if ( !match(self['perm'],'^[0-7]?[0-7]{3,3}$') ) {
       perm_valid=false;
       error('dirperm : invalid permissions ('+self['perm']+') for directory '+self['path']); 
     };
  } else {
     if ( !match(self['perm'],'^[02-6]?[0-7]{3,3}$') ) {
       perm_valid=false;
       error('dirperm : invalid permissions ('+self['perm']+') for file '+self['path']); 
     };
  };

  return(perm_valid);
};

type structure_dirperm_entry = {
    'path'    : string
    'perm'    : string with match(self,'[0-7]{3,4}') 
    'owner'   : string with match(self, '\w+(:\w+)?')
    'type'    : string with match(self, 'd|f')
    'initdir' ? string[] 
} with dirperm_permissions_valid(self);

type component_dirperm = {
    include structure_component
    'paths' ? structure_dirperm_entry[]
};

type '/software/components/dirperm' = component_dirperm;
