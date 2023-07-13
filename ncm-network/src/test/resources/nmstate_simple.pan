object template nmstate_simple;

include 'simple_base_profile';
# the next include is mainly to the profile, it is not used in the tests
#   (unless the component gets specific schema things)
include 'components/network/config-nmstate';
