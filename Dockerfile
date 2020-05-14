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
# e2fsprogs is required for the chattr command
RUN yum install -y perl-Test-Quattor which panc aii-ks ncm-lib-blockdevices ncm-ncd \
    e2fsprogs git libselinux-utils sudo perl-JSON-Any perl-Set-Scalar perl-Text-Glob \
    perl-NetAddr-IP perl-Net-OpenNebula perl-REST-Client perl-Net-FreeIPA \
    perl-Crypt-OpenSSL-X509 perl-Date-Manip perl-Net-DNS

# these are not by default in centos7, but quattor tests assume they are
#RUN touch /usr/sbin/selinuxenabled /sbin/restorecon
#RUN chmod +x /usr/sbin/selinuxenabled /sbin/restorecon

# point library core to where we downloaded it
ENV QUATTOR_TEST_TEMPLATE_LIBRARY_CORE /quattor/template-library-core-master
COPY . /quattor_test

# set workdir to where we'll run the tests
# you need to provide the content of this directory when running this docker container:
# first build this container:
# docker build -t quattor_test .
WORKDIR /quattor_test

# when running the container, by default run the tests 
# you can run any command in the container from the cli.
# e.g. to test configuration-modules-core/ncm-metaconfig
# cd /path/to/configuration-modules-core
# docker run --mount type=bind,source="$PWD",target=/quattor_test/configuration-modules-core \
# quattor_test bash -c 'source /usr/bin/mvn_test.sh && \
# cd /quattor_test/configuration-modules-core/ncm-metaconfig && mvn_test service-mailrc'
CMD . /usr/bin/mvn_test.sh && mvn_test
