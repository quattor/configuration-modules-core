declaration template metaconfig/lmod/schema;

include 'pan/types';

@{ generate single displayT entry, all keys or names are considered valid }
type lmod_prop = {
    "short" : string[]
    "long" : string[]
    "doc" : string
    "color" ? string with match(SELF, '^(black|red|green|yellow|blue|magenta|cyan|white)$')
    @{override the key with name joined using ':'}
    "names" ? string[]
};

type lmod_scdescript = {
    "timestamp" : string
    "dir" : string
};

type lmod_service = {
    "prop" : lmod_prop{}{}
    "scDescript" ? lmod_scdescript[]
};
