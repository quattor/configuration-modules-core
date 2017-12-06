object template names;

include 'components/ofed/schema';

bind '/' = component_ofed_opensm; # for the names validation
'/names/x0123456789abcdef' = 'a switch somewhere';
'/names/x0123456789abcdff' = 'another switch somewhere else';
