FROM amazonlinux:2023

WORKDIR /tmp

RUN dnf -y update \
    && dnf -y groupinstall "Development Tools" \
    && dnf -y install zlib-devel ncurses-devel gdbm-devel nss-devel openssl openssl-devel readline-devel libffi-devel \
                      curl-devel bzip2-devel p7zip p7zip-plugins freetype-devel libpng-devel wget git \
                      unzip cmake libtiff-devel sqlite-devel pkgconfig glibc-langpack-en

# Set UTF-8 locale environment variables to ensure proper character encoding and avoid setlocale warnings
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install geos from source (not in dnf)
RUN curl -O https://download.osgeo.org/geos/geos-3.13.1.tar.bz2 \
    && tar xvfj geos-3.13.1.tar.bz2 \
    && cd geos-3.13.1 \
    && mkdir _build \
    && cd _build \
    && cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        .. \
    && make \
    && ctest \
    && make install

# Install libspatialindex from source (not in dnf)
RUN wget https://github.com/libspatialindex/libspatialindex/releases/download/2.1.0/spatialindex-src-2.1.0.tar.bz2 \
    && tar xvfj spatialindex-src-2.1.0.tar.bz2 \
    && cd spatialindex-src-2.1.0 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && make install \
    && ldconfig

# Install proj (not in dnf)
RUN wget https://download.osgeo.org/proj/proj-9.6.2.tar.gz \
    && tar xzf proj-9.6.2.tar.gz \
    && cd proj-9.6.2 \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && cmake --build . \
    && ctest \
    && cmake --build . --target install \
    && ldconfig

RUN curl https://sqlite.org/2024/sqlite-autoconf-3450100.tar.gz | tar xzf - \
    && cd ./sqlite-autoconf-3450100 \
    && ./configure --prefix=/usr --libdir=/lib64 \
    && make \
    && make install

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip  \
    && ./aws/install

# Install Python 3.10
RUN curl https://www.python.org/ftp/python/3.10.11/Python-3.10.11.tgz | tar xzf - \
    && cd ./Python-3.10.11 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j8 \
    && make altinstall \
    && pip3.10 install pipenv virtualenv --upgrade

# Install Python 3.11
RUN curl https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tgz | tar xzf - \
    && cd ./Python-3.11.5 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j8 \
    && make altinstall

# Install Python 3.12
RUN curl https://www.python.org/ftp/python/3.12.11/Python-3.12.11.tgz | tar xzf - \
    && cd ./Python-3.12.11 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j8 \
    && make altinstall \
    && pip3.12 install pipenv virtualenv --upgrade

# Install Node.js 22
RUN curl https://d3rnber7ry90et.cloudfront.net/linux-x86_64/node-v22.16.0.tar.gz | tar -zxf - --strip-components=1 -C /usr/local

# Install yarn
RUN npm install --global yarn

# Install Packer versions
RUN wget https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -O /tmp/packer.zip \
    && mkdir ~/.bin \
    && unzip /tmp/packer.zip -d ~/.bin \
    && wget https://releases.hashicorp.com/packer/1.7.5/packer_1.7.5_linux_amd64.zip -O /tmp/packer.zip \
    && unzip -p /tmp/packer.zip > ~/.bin/packer-1.7.5 \
    && chmod +x ~/.bin/packer-1.7.5

# Install GNU Make 4.4
RUN wget https://ftp.gnu.org/gnu/make/make-4.4.tar.gz -O - | tar -vzxf - -C /tmp \
    && cd /tmp/make-4.4 \
    && ./configure \
    && make install

# Install Pants
RUN curl --proto '=https' --tlsv1.2 -fsSL https://static.pantsbuild.org/setup/get-pants.sh | bash
ENV PATH="${PATH}:/root/.local/bin"

# Install Poetry
RUN pip3.11 install poetry==1.8.5

# Set SSL certificate path
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt

# Cleanup
RUN rm -rf /var/cache/dnf /tmp/* /var/tmp/*
