FROM node:18.4.0
RUN cd /tmp \
   && apt-get update \
   && apt-get install -y libgeos-dev libspatialindex-dev zip unzip p7zip libfreetype6-dev libpng-dev \
   && wget https://www.python.org/ftp/python/3.8.13/Python-3.8.13.tgz \
   && tar xvf Python-3.8.13.tgz \
   && cd /tmp/Python-3.8.13 \
   && ./configure --enable-optimizations --with-ensurepip=install \
   && make -j8 \
   && make altinstall \
   && pip3.8 install pipenv awscli virtualenv --upgrade
 RUN cd /tmp \
   && apt-get update \
   && wget https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -O /tmp/packer.zip \
   && mkdir ~/.bin \
   && unzip /tmp/packer.zip -d ~/.bin \
   && wget https://releases.hashicorp.com/packer/1.7.5/packer_1.7.5_linux_amd64.zip -O /tmp/packer.zip \
   && unzip -p /tmp/packer.zip > ~/.bin/packer-1.7.5 \
   && chmod +x ~/.bin/packer-1.7.5 \
   && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
