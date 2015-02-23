#!/bin/sh


#Clean up old nginx builds
rm -rf ~/rpmbuild/RPMS/*/nginx-*.rpm

#Install required packages for building
yum install -y \
    rpm-build \
    rpmdevtools \
    yum-utils \
    git \
    openssl-devel \
    wget

yum groupinstall "Development Tools"

#Install source RPM for Nginx
pushd ~
echo """[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/6/SRPMS/
gpgcheck=0
enabled=1""" >> nginx.repo
cp nginx.repo /etc/yum.repos.d/
yumdownloader --source nginx
rpm -ihv nginx*.src.rpm
popd


#Get various add-on modules for Nginx
pushd ~/rpmbuild/SOURCES

#Headers More module
wget https://github.com/openresty/headers-more-nginx-module/archive/v0.25.zip
unzip v0.25.zip

#LDAP authentication module
git clone https://github.com/kvspb/nginx-auth-ldap.git

#Last OpenSSL version
wget https://www.openssl.org/source/openssl-1.0.2.tar.gz
tar xvzf openssl-1.0.2.tar.gz

popd

#Prep and patch the Nginx specfile for the RPMs
#Note: expects to have the repository contents located in ~/rpmbuild/SPECS/
#      or located at /vagrant 
pushd ~/rpmbuild/SPECS

patch -p1 < nginx-eresearch.patch
spectool -g -R nginx.spec
yum-builddep -y nginx.spec
rpmbuild -ba nginx.spec

#Test installation and check output
yum remove -y nginx nginx-devel
yum install -y ~/rpmbuild/RPMS/*/nginx-*.rpm
nginx -V