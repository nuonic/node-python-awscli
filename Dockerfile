FROM node:14.8.0
 RUN cd /tmp \
   && apt-get update \
   && apt-get install -y libgeos-dev libspatialindex-dev zip unzip p7zip libfreetype6-dev libpng-dev \
   && wget https://www.python.org/ftp/python/3.8.11/Python-3.8.11.tgz \
   && tar xvf Python-3.8.11.tgz \
   && cd /tmp/Python-3.8.11 \
   && ./configure --enable-optimizations \
   && make -j8 \
   && make altinstall \
   && pip3.8 install --upgrade pip \
   && pip3.8 install awscli virtualenv --upgrade \
   && apt-get install pipenv \
   && wget https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -O /tmp/packer.zip \
   && mkdir ~/.bin \
   && unzip /tmp/packer.zip -d ~/.bin \
   && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
