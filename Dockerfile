# Use an official RockyLinux image as a parent image
FROM rockylinux:8

# Set the working directory to install dependencies to /quattor
WORKDIR /quattor

# install library core in /quattor, tests need it
ADD https://codeload.github.com/quattor/template-library-core/tar.gz/master template-library-core-master.tar.gz
RUN tar -xzf template-library-core-master.tar.gz

# point library core to where we downloaded it
ENV QUATTOR_TEST_TEMPLATE_LIBRARY_CORE /quattor/template-library-core-master

# Prepare to install dependencies
RUN dnf -y install dnf-plugins-core && \
  dnf config-manager --set-enabled appstream && \
  dnf config-manager --set-enabled powertools && \
  dnf -y install epel-release http://yum.quattor.org/devel/quattor-yum-repo-2-1.noarch.rpm

# The available version of perl-Test-Quattor is too old for mvnprove.pl to
# work, but this is a quick way of pulling in a lot of required dependencies.
# Surprisingly `which` is not installed by default and panc depends on it.
# libselinux-utils is required for /usr/sbin/selinuxenabled
RUN dnf install -y maven which rpm-build panc ncm-lib-blockdevices \
  ncm-ncd git libselinux-utils sudo perl-Crypt-OpenSSL-X509 \
  perl-Data-Compare perl-Date-Manip perl-File-Touch perl-JSON-Any \
  perl-Net-DNS perl-Net-FreeIPA perl-Net-OpenNebula \
  perl-Net-OpenStack-Client perl-NetAddr-IP perl-REST-Client \
  perl-Set-Scalar perl-Text-Glob cpanminus gcc wget \
  perl-Git-Repository perl-Data-Structure-Util \
  http://yum.quattor.org/devel/perl-Test-Quattor-18.3.0-SNAPSHOT20180406083650.noarch.rpm \
  http://yum.quattor.org/devel/aii-ks-21.12.1-SNAPSHOT20230627130118.noarch.rpm

# set workdir to where we'll run the tests
COPY --chown=99 . /quattor_test
WORKDIR /quattor_test
# yum-cleanup-repos.t must be run as a non-root user. It must also resolve
# to a name (nobody) to avoid getpwuid($<) triggering a warning which fails
# the tests.
USER 99

# By default maven writes to $HOME which doesn't work for user=nobody
ENV MVN_ARGS -Dmaven.repo.local=/tmp/.m2
# Default action on running the container is to run all tests 
CMD . /usr/bin/mvn_test.sh && mvn_test
