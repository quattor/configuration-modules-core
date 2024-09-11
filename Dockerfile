FROM ghcr.io/quattor/quattor-test-container:latest

# Set the working directory to install dependencies to /quattor
WORKDIR /quattor

# set workdir to where we'll run the tests
COPY --chown=quattortest . /quattor_test
WORKDIR /quattor_test

# Default action on running the container is to run all tests
CMD runuser --shell /bin/bash --preserve-environment --command 'source /usr/bin/mvn_test.sh && mvn_run "dependency:resolve-plugins dependency:go-offline $MVN_ARGS" && mvn_test' quattortest
