# Use an official Python runtime as a parent image
FROM centos:7

# Set the working directory to /app
WORKDIR /quattor

# Copy the current directory contents into the container at /app
ADD https://codeload.github.com/quattor/template-library-core/tar.gz/master /quattor/template-library-core-master.tar.gz
RUN tar xvfz template-library-core-master.tar.gz

RUN yum install maven epel-release -y
RUN rpm -U http://yum.quattor.org/devel/quattor-release-1-1.noarch.rpm
RUN yum install --nogpgcheck perl-Test-Quattor -y
RUN yum install panc -y
RUN yum install perl-JSON-Any -y
# these are not by default in centos7, but quattor tests assume they are
RUN touch /usr/sbin/selinuxenabled /sbin/restorecon
RUN chmod +x /usr/sbin/selinuxenabled /sbin/restorecon

# Define environment variable
ENV QUATTOR_TEST_TEMPLATE_LIBRARY_CORE /quattor/template-library-core-master

WORKDIR /quattor_test

CMD . /usr/bin/mvn_test.sh && mvn_test
