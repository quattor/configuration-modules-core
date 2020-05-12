# Use an official centos image as a parent image
FROM centos:7

# Set the working directory to install dependencies to /quattor
WORKDIR /quattor

# install library core in /quattor, tests need it
ADD https://codeload.github.com/quattor/template-library-core/tar.gz/master /quattor/template-library-core-master.tar.gz
RUN tar xvfz template-library-core-master.tar.gz

# Install dependencies
RUN yum install -y maven epel-release
RUN rpm -U http://yum.quattor.org/devel/quattor-release-1-1.noarch.rpm

# The available version of perl-Test-Quattor is too old for mvnprove.pl to work, but
# this is a quick way of pulling in a lot of required dependencies.
# Surprisingly `which` is not installed by default and panc depends on it.
# libselinux-utils is required for /usr/sbin/selinuxenabled
RUN yum install -y perl-Test-Quattor which panc aii-ks ncm-lib-blockdevices ncm-ncd \
    git libselinux-utils sudo perl-JSON-Any perl-Set-Scalar perl-Text-Glob \
    perl-NetAddr-IP perl-Net-OpenNebula perl-REST-Client perl-Net-FreeIPA \
    perl-Crypt-OpenSSL-X509 perl-Date-Manip perl-Net-DNS

# point library core to where we downloaded it
ENV QUATTOR_TEST_TEMPLATE_LIBRARY_CORE /quattor/template-library-core-master

# set workdir to where we'll run the tests
COPY --chown=99 . /quattor_test
WORKDIR /quattor_test
# yum-cleanup-repos.t must be run as a non-root user. It must also resolve
# to a name (nobody) to avoid getpwuid($<) triggering a warning which fails
# the tests.
USER 99

# By default maven writes to $HOME which doesn't work for user=nobody
ENV MVN_ARGS -Dmaven.repo.local=/tmp/.m2
# when running the container, by default run the tests 
CMD . /usr/bin/mvn_test.sh && mvn_test
