# This should be included from quattor/schema

declaration template components/network/core-schema;

final variable QUATTOR_TYPES_NETWORK_LEGACY ?= false;

include if (QUATTOR_TYPES_NETWORK_LEGACY) 'components/network/core-schema-legacy'
    else 'components/network/types/network';
