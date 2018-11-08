FROM node:11
 RUN cd /tmp \
   && apt-get update \
   && apt-get install -y libgeos-dev libspatialindex-dev zip unzip p7zip libfreetype6-dev libpng-dev \
   && wget https://www.python.org/ftp/python/3.7.1/Python-3.7.1.tgz \
   && tar xvf Python-3.7.1.tgz \
   && cd /tmp/Python-3.7.1 \
   && ./configure --enable-optimizations \
   && make -j8 \
   && make altinstall \
   && pip3.7 install --upgrade pip \
   && pip3.7 install awscli virtualenv --upgrade \
   && wget https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -O /tmp/packer.zip \
   && mkdir ~/.bin \
   && unzip /tmp/packer.zip -d ~/.bin \
   && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
