FROM amazonlinux:2023

# Install development tools and dependencies
RUN cd /tmp \
    && dnf -y groupinstall "Development Tools" \
    && dnf -y install zlib-devel ncurses-devel gdbm-devel nss-devel openssl-devel readline-devel libffi-devel curl-devel bzip2-devel \
    && dnf -y install p7zip p7zip-plugins freetype-devel libpng-devel wget git unzip cmake

# Install geospatial libraries (not available in AL2023 repos, must build from source)
RUN cd /tmp \
    && wget https://download.osgeo.org/proj/proj-9.3.0.tar.gz \
    && tar -xzf proj-9.3.0.tar.gz \
    && cd proj-9.3.0 \
    && mkdir build && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. \
    && make -j$(nproc) && make install \
    && cd /tmp \
    && wget https://download.osgeo.org/geos/geos-3.12.0.tar.bz2 \
    && tar -xjf geos-3.12.0.tar.bz2 \
    && cd geos-3.12.0 \
    && mkdir build && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. \
    && make -j$(nproc) && make install \
    && cd /tmp \
    && wget https://github.com/libspatialindex/spatialindex/releases/download/1.9.3/spatialindex-src-1.9.3.tar.bz2 \
    && tar -xjf spatialindex-src-1.9.3.tar.bz2 \
    && cd spatialindex-src-1.9.3 \
    && ./configure --prefix=/usr \
    && make -j$(nproc) && make install \
    && rm -rf /tmp/proj-9.3.0* /tmp/geos-3.12.0* /tmp/spatialindex-src-1.9.3* \
    && ldconfig

RUN cd /tmp \
    && curl https://sqlite.org/2024/sqlite-autoconf-3450100.tar.gz | tar xzf - \
    && cd ./sqlite-autoconf-3450100 \
    && ./configure --prefix=/usr --libdir=/lib64 \
    && make \
    && make install \
    && rm -rf /tmp/sqlite-autoconf-3450100

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip  \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install Python 3.10
RUN cd /tmp \
    && curl https://www.python.org/ftp/python/3.10.11/Python-3.10.11.tgz | tar xzf - \
    && cd ./Python-3.10.11 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j8 \
    && make altinstall \
    && pip3.10 install pipenv virtualenv --upgrade \
    && rm -r /tmp/Python-3.10.11

# Install Python 3.11
RUN cd /tmp \
    && curl https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tgz | tar xzf - \
    && cd /tmp/Python-3.11.5 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j8 \
    && make altinstall \
    && rm -r /tmp/Python-3.11.5

# Install Node.js 18
RUN curl https://d3rnber7ry90et.cloudfront.net/linux-x86_64/node-v18.17.1.tar.gz | tar -zxf - --strip-components=1 -C /usr/local \
    && npm install --global yarn

# Install Packer versions
RUN cd /tmp \
    && dnf -y update \
    && wget https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -O /tmp/packer.zip \
    && mkdir ~/.bin \
    && unzip /tmp/packer.zip -d ~/.bin \
    && wget https://releases.hashicorp.com/packer/1.7.5/packer_1.7.5_linux_amd64.zip -O /tmp/packer.zip \
    && unzip -p /tmp/packer.zip > ~/.bin/packer-1.7.5 \
    && chmod +x ~/.bin/packer-1.7.5 \
    && rm -rf /var/cache/dnf /tmp/* /var/tmp/*

# Install GNU Make 4.4
RUN wget https://ftp.gnu.org/gnu/make/make-4.4.tar.gz -O - | tar -vzxf - -C /tmp \
    && cd /tmp/make-4.4 \
    && ./configure \
    && make install \
    && rm -rf /tmp/make-4.4

# Install Pants
RUN curl --proto '=https' --tlsv1.2 -fsSL https://static.pantsbuild.org/setup/get-pants.sh | bash
ENV PATH="${PATH}:/root/.local/bin"

# Install Poetry
RUN pip3.11 install poetry==1.8.5

# Set SSL certificate path
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt