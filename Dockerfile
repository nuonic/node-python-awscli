FROM amazonlinux:2023
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG BUILD_JOBS=8
WORKDIR /tmp
# Clean package metadata in the layer that downloads it.
RUN dnf -y update \
    && dnf -y groupinstall "Development Tools" \
    && dnf -y install zlib-devel ncurses-devel gdbm-devel nss-devel openssl openssl-devel readline-devel libffi-devel \
                     curl-devel bzip2-devel p7zip p7zip-plugins freetype-devel libpng-devel wget git \
                     unzip cmake libtiff-devel sqlite-devel pkgconfig glibc-langpack-en \
    && dnf clean all \
    && rm -rf /var/cache/dnf
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8
# Remove each source tree and archive before its layer is committed.
RUN curl -fsSL https://download.osgeo.org/geos/geos-3.13.1.tar.bz2 -o geos-3.13.1.tar.bz2 \
    && tar xjf geos-3.13.1.tar.bz2 \
    && cd geos-3.13.1 \
    && mkdir _build \
    && cd _build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j"${BUILD_JOBS}" \
    && ctest \
    && make install \
    && cd /tmp \
    && rm -rf geos-3.13.1 geos-3.13.1.tar.bz2
RUN curl -fsSL https://github.com/libspatialindex/libspatialindex/releases/download/2.1.0/spatialindex-src-2.1.0.tar.bz2 -o spatialindex-src-2.1.0.tar.bz2 \
    && tar xjf spatialindex-src-2.1.0.tar.bz2 \
    && cd spatialindex-src-2.1.0 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j"${BUILD_JOBS}" \
    && make install \
    && ldconfig \
    && cd /tmp \
    && rm -rf spatialindex-src-2.1.0 spatialindex-src-2.1.0.tar.bz2
RUN curl -fsSL https://download.osgeo.org/proj/proj-9.6.2.tar.gz -o proj-9.6.2.tar.gz \
    && tar xzf proj-9.6.2.tar.gz \
    && cd proj-9.6.2 \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && cmake --build . --parallel "${BUILD_JOBS}" \
    && ctest \
    && cmake --build . --target install \
    && ldconfig \
    && cd /tmp \
    && rm -rf proj-9.6.2 proj-9.6.2.tar.gz
RUN curl -fsSL https://sqlite.org/2024/sqlite-autoconf-3450100.tar.gz | tar xzf - \
    && cd sqlite-autoconf-3450100 \
    && ./configure --prefix=/usr --libdir=/lib64 \
    && make -j"${BUILD_JOBS}" \
    && make install \
    && cd /tmp \
    && rm -rf sqlite-autoconf-3450100
RUN curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip
RUN curl -fsSL https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tgz | tar xzf - \
    && cd Python-3.11.5 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j"${BUILD_JOBS}" \
    && make altinstall \
    && python3.11 -m pip install --no-cache-dir --upgrade pip \
    && cd /tmp \
    && rm -rf Python-3.11.5
RUN curl -fsSL https://www.python.org/ftp/python/3.12.11/Python-3.12.11.tgz | tar xzf - \
    && cd Python-3.12.11 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j"${BUILD_JOBS}" \
    && make altinstall \
    && python3.12 -m pip install --no-cache-dir --upgrade pip \
    && python3.12 -m pip install --no-cache-dir --upgrade pipenv virtualenv \
    && cd /tmp \
    && rm -rf Python-3.12.11
RUN curl -fsSL https://d3rnber7ry90et.cloudfront.net/linux-x86_64/node-v22.16.0.tar.gz \
    | tar -zxf - --strip-components=1 -C /usr/local \
    && node --version \
    && npm install --global yarn \
    && npm cache clean --force
RUN curl -fsSL https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -o packer.zip \
    && mkdir -p /root/.bin \
    && unzip -q packer.zip -d /root/.bin \
    && curl -fsSL https://releases.hashicorp.com/packer/1.7.5/packer_1.7.5_linux_amd64.zip -o packer.zip \
    && unzip -p packer.zip packer > /root/.bin/packer-1.7.5 \
    && chmod +x /root/.bin/packer-1.7.5 \
    && rm -f /tmp/packer.zip
RUN curl -fsSL https://ftp.gnu.org/gnu/make/make-4.4.tar.gz | tar xzf - \
    && cd make-4.4 \
    && ./configure \
    && make -j"${BUILD_JOBS}" \
    && make install \
    && cd /tmp \
    && rm -rf make-4.4
RUN curl --proto '=https' --tlsv1.2 -fsSL https://static.pantsbuild.org/setup/get-pants.sh | bash
ENV PATH="${PATH}:/root/.local/bin"
RUN python3.12 -m pip install --no-cache-dir poetry==2.4.1
RUN curl -fsSL https://astral.sh/uv/install.sh | sh \
    && uv --version
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
