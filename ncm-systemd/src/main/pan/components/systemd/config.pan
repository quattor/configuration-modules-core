${componentconfig}

include 'components/${project.artifactId}/functions';

# Ensure that unit property does not remain undefined
'/software/components/${project.artifactId}/unit' ?= dict();
