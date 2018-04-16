FROM node:9.10
 RUN cd /tmp \
   && wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz \
   && tar xvf Python-3.6.4.tgz \
   && cd /tmp/Python-3.6.4 \
   && ./configure --enable-optimizations \
   && make -j8 \
   && make altinstall \
   && pip3.6 install --upgrade pip \
   && pip3.6 install awscli virtualenv --upgrade \
   && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
