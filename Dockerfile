#-- Important : We use stretch-slim to match GLIBC 2.24 supplied on AWS Lambda
#   This is important because this image will run serverless-python-package
#   to package compiled python modules.  pip will pull the compiled wheel file
#   to match the host architecture and version, and that must also match the lambda
#   architecture and version. (abi3-manylinux_2_24_x86_64)

FROM debian:bullseye-slim

#-- install python 3.8
#   pipenv is pinned to ==2022.8.5 because of https://github.com/serverless/serverless-python-requirements/issues/716

RUN cd /tmp \
   && apt-get update \
   && apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev \
   && apt-get install -y libgeos-dev libspatialindex-dev zip unzip p7zip libfreetype6-dev libpq-dev libpng-dev wget git \
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

#-- install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get install apt-transport-https
RUN apt-get update \
   && apt-get install -y yarn

#-- install Node 16

RUN (curl -fsSL https://deb.nodesource.com/setup_16.x | bash -) \
   && apt-get install -y nodejs

#-- install packer 1.22 and packer 1.7.5

RUN cd /tmp \
   && apt-get update \
   && wget https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -O /tmp/packer.zip \
   && mkdir ~/.bin \
   && unzip /tmp/packer.zip -d ~/.bin \
   && wget https://releases.hashicorp.com/packer/1.7.5/packer_1.7.5_linux_amd64.zip -O /tmp/packer.zip \
   && unzip -p /tmp/packer.zip > ~/.bin/packer-1.7.5 \
   && chmod +x ~/.bin/packer-1.7.5 \
   && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
