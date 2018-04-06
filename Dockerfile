FROM node:9.10
 RUN apt-get update \
   && apt-get install -y python3 python3-pip \
   && cd /tmp \
   && wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tgz \
   && tar xvf Python-3.6.4.tgz \
   && cd Python-3.6.4 \
   && ./configure --enable-optimizations \
   && make -j8 \
   && sudo make altinstall \
   && pip install awscli --upgrade \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
