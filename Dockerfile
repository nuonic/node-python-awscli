FROM amazonlinux:2

#-- install python 3.8
#   pipenv is pinned to ==2022.8.5 because of https://github.com/serverless/serverless-python-requirements/issues/716

RUN cd /tmp \
    && amazon-linux-extras install epel -y \
    && yum -y groupinstall "Development Tools" \
    && yum -y install zlib-devel ncurses-devel gdbm-devel nss-devel openssl11 openssl11-devel sqlite-devel readline-devel libffi-devel curl-devel bzip2-devel \
    && yum -y install proj-devel geos geos-devel spatialindex-devel p7zip p7zip-plugins freetype-devel libpng-devel wget git \
    && wget https://www.python.org/ftp/python/3.8.13/Python-3.8.13.tgz \
    && tar xvf Python-3.8.13.tgz \
    && cd /tmp/Python-3.8.13 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j8 \
    && make altinstall \
    && pip3.8 install pipenv==2022.8.5 awscli virtualenv --upgrade


RUN cd /tmp \
   && wget https://www.python.org/ftp/python/3.9.15/Python-3.9.15.tgz \
   && tar xvf Python-3.9.15.tgz \
   && cd /tmp/Python-3.9.15 \
   && ./configure --enable-optimizations --with-ensurepip=install \
   && make -j8 \
   && make altinstall

RUN cd /tmp \
   && wget https://www.python.org/ftp/python/3.10.11/Python-3.10.11.tgz \
   && tar xvf Python-3.10.11.tgz \
   && cd /tmp/Python-3.10.11 \
   && ./configure --enable-optimizations --with-ensurepip=install \
   && make -j8 \
   && make altinstall

RUN curl --silent --location https://rpm.nodesource.com/setup_16.x | bash -
RUN curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
RUN yum -y install epel-release \
    && yum -y update \
    && yum -y install yarn nodejs

#-- install packer 1.22 and packer 1.7.5

RUN cd /tmp \
    && yum -y update \
    && wget https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -O /tmp/packer.zip \
    && mkdir ~/.bin \
    && unzip /tmp/packer.zip -d ~/.bin \
    && wget https://releases.hashicorp.com/packer/1.7.5/packer_1.7.5_linux_amd64.zip -O /tmp/packer.zip \
    && unzip -p /tmp/packer.zip > ~/.bin/packer-1.7.5 \
    && chmod +x ~/.bin/packer-1.7.5 \
    && rm -rf /var/cache/yum /tmp/* /var/tmp/*
