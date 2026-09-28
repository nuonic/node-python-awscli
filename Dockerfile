# syntax=docker/dockerfile:1

ARG UV_VERSION=latest

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

###############################################################################
# Build toolchain. Each component below is compiled in its own stage, so
# BuildKit builds them in parallel and a version bump only rebuilds that one
# component. None of the compilers, source trees or build dirs reach the final
# image — only the installed artefacts are copied across.
###############################################################################
FROM amazonlinux:2023 AS builder

# Fail on any command in a pipeline (e.g. a failed download piped into tar).
# Inherited by every stage built FROM this one.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN dnf -y install --setopt=install_weak_deps=False \
        gcc gcc-c++ make cmake pkgconfig tar gzip bzip2 xz unzip findutils sqlite \
        zlib-devel ncurses-devel gdbm-devel nss-devel openssl-devel readline-devel libffi-devel \
        curl-devel bzip2-devel xz-devel libuuid-devel libtiff-devel sqlite-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

WORKDIR /src

# ---------------------------------------------------------------------------
FROM builder AS geos
ARG GEOS_VERSION=3.13.1
RUN curl -fsSL https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 | tar xjf - \
    && cmake -S geos-${GEOS_VERSION} -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_TESTING=OFF \
    && cmake --build build -j"$(nproc)" \
    && DESTDIR=/out cmake --install build --strip

# ---------------------------------------------------------------------------
FROM builder AS spatialindex
ARG SPATIALINDEX_VERSION=2.1.0
RUN curl -fsSL https://github.com/libspatialindex/libspatialindex/releases/download/${SPATIALINDEX_VERSION}/spatialindex-src-${SPATIALINDEX_VERSION}.tar.bz2 | tar xjf - \
    && cmake -S spatialindex-src-${SPATIALINDEX_VERSION} -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_TESTING=OFF \
    && cmake --build build -j"$(nproc)" \
    && DESTDIR=/out cmake --install build --strip

# ---------------------------------------------------------------------------
FROM builder AS proj
ARG PROJ_VERSION=9.6.2
RUN curl -fsSL https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz | tar xzf - \
    && cmake -S proj-${PROJ_VERSION} -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_TESTING=OFF \
    && cmake --build build -j"$(nproc)" \
    && DESTDIR=/out cmake --install build --strip

# ---------------------------------------------------------------------------
# Installed straight into /usr/local (which is otherwise empty in this stage)
# so the Python stages below can build against it.
FROM builder AS sqlite
ARG SQLITE_YEAR=2024
ARG SQLITE_VERSION=3450100
RUN curl -fsSL https://sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz | tar xzf - \
    && cd sqlite-autoconf-${SQLITE_VERSION} \
    && ./configure --prefix=/usr/local \
    && make -j"$(nproc)" \
    && make install-strip \
    && rm -rf /usr/local/share/man

# ---------------------------------------------------------------------------
# pip is bootstrapped in the final stage with `ensurepip`, so its scripts get
# correct shebangs. The rpath makes the sqlite3 module use the sqlite above.
FROM sqlite AS python311
ARG PYTHON_VERSION=3.11.5
RUN curl -fsSL https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz | tar xzf - \
    && cd Python-${PYTHON_VERSION} \
    && PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure \
        --enable-optimizations \
        --without-ensurepip \
        LDFLAGS="-Wl,-rpath,/usr/local/lib" \
    && make -j"$(nproc)" \
    && make altinstall DESTDIR=/out \
    && find /out/usr/local/lib -depth -type d \( -name test -o -name tests -o -name idle_test \) -exec rm -rf {} + \
    && find /out/usr/local/lib -type f -name '*.so' -exec strip --strip-unneeded {} + \
    && find /out/usr/local/lib -type f -name 'libpython*.a' -exec strip --strip-debug {} + \
    && strip --strip-unneeded /out/usr/local/bin/python${PYTHON_VERSION%.*}

# ---------------------------------------------------------------------------
FROM sqlite AS python312
ARG PYTHON_VERSION=3.12.11
RUN curl -fsSL https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz | tar xzf - \
    && cd Python-${PYTHON_VERSION} \
    && PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure \
        --enable-optimizations \
        --without-ensurepip \
        LDFLAGS="-Wl,-rpath,/usr/local/lib" \
    && make -j"$(nproc)" \
    && make altinstall DESTDIR=/out \
    && find /out/usr/local/lib -depth -type d \( -name test -o -name tests -o -name idle_test \) -exec rm -rf {} + \
    && find /out/usr/local/lib -type f -name '*.so' -exec strip --strip-unneeded {} + \
    && find /out/usr/local/lib -type f -name 'libpython*.a' -exec strip --strip-debug {} + \
    && strip --strip-unneeded /out/usr/local/bin/python${PYTHON_VERSION%.*}

# ---------------------------------------------------------------------------
FROM builder AS gnumake
ARG MAKE_VERSION=4.4
RUN curl -fsSL https://ftp.gnu.org/gnu/make/make-${MAKE_VERSION}.tar.gz | tar xzf - \
    && cd make-${MAKE_VERSION} \
    && ./configure --prefix=/usr/local \
    && make -j"$(nproc)" \
    && make install-strip DESTDIR=/out \
    && rm -rf /out/usr/local/share/info /out/usr/local/share/man

# ---------------------------------------------------------------------------
FROM builder AS awscli
RUN curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip -q awscliv2.zip \
    && ./aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin

# ---------------------------------------------------------------------------
FROM builder AS packer
RUN mkdir /out \
    && curl -fsSL https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip -o packer-1.2.2.zip \
    && unzip -q packer-1.2.2.zip -d /out \
    && curl -fsSL https://releases.hashicorp.com/packer/1.7.5/packer_1.7.5_linux_amd64.zip -o packer-1.7.5.zip \
    && unzip -p packer-1.7.5.zip packer > /out/packer-1.7.5 \
    && chmod +x /out/packer-1.7.5

###############################################################################
# Final image
###############################################################################
FROM amazonlinux:2023

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /tmp

# Explicit toolchain instead of the "Development Tools" group, which drags in
# gdb, valgrind, systemtap, rpm-build, subversion and friends. Headers are kept
# so pipelines can still build Python wheels from sdists.
RUN dnf -y update \
    && dnf -y install \
        gcc gcc-c++ make binutils patch autoconf automake libtool pkgconfig cmake \
        git wget unzip tar gzip bzip2 xz findutils which p7zip p7zip-plugins glibc-langpack-en \
        zlib-devel ncurses-devel gdbm-devel nss-devel openssl openssl-devel readline-devel libffi-devel \
        curl-devel bzip2-devel xz-devel libuuid-devel freetype-devel libpng-devel libtiff-devel sqlite-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/log/dnf* \
    && printf '/usr/local/lib\n/usr/local/lib64\n' > /etc/ld.so.conf.d/usr-local.conf

# Set UTF-8 locale environment variables to ensure proper character encoding and avoid setlocale warnings
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt \
    PATH="${PATH}:/root/.local/bin"

COPY --from=sqlite       /usr/local/         /usr/local/
COPY --from=geos         /out/usr/local/     /usr/local/
COPY --from=spatialindex /out/usr/local/     /usr/local/
COPY --from=proj         /out/usr/local/     /usr/local/
COPY --from=gnumake      /out/usr/local/     /usr/local/
COPY --from=awscli       /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=packer       /out/               /root/.bin/
COPY --from=python311    /out/usr/local/     /usr/local/
COPY --from=python312    /out/usr/local/     /usr/local/

# 3.11 first, then 3.12, so the unversioned pip/pip3 scripts belong to 3.12
RUN ldconfig \
    && ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws \
    && ln -s /usr/local/aws-cli/v2/current/bin/aws_completer /usr/local/bin/aws_completer \
    && python3.11 -m ensurepip --altinstall \
    && python3.11 -m pip install --no-cache-dir --upgrade pip \
    && python3.12 -m ensurepip --altinstall \
    && python3.12 -m pip install --no-cache-dir --upgrade pip \
    && pip3.12 install --no-cache-dir --upgrade pipenv virtualenv poetry==2.4.1

# Node.js 22 and yarn
RUN curl -fsSL https://d3rnber7ry90et.cloudfront.net/linux-x86_64/node-v22.16.0.tar.gz \
        | tar -xzf - --strip-components=1 -C /usr/local \
            --exclude='*/CHANGELOG.md' --exclude='*/README.md' --exclude='*/LICENSE' --exclude='*/share/doc' \
    && npm install --global yarn \
    && npm cache clean --force

# Pants launcher
RUN curl --proto '=https' --tlsv1.2 -fsSL https://static.pantsbuild.org/setup/get-pants.sh | bash

# uv / uvx
COPY --from=uv /uv /uvx /usr/local/bin/

# Smoke test the toolchain
RUN node --version \
    && yarn --version \
    && aws --version \
    && python3.11 -c "import sqlite3, ssl, lzma, ctypes" \
    && python3.12 -c "import sqlite3, ssl, lzma, ctypes; assert sqlite3.sqlite_version == '3.45.1', sqlite3.sqlite_version" \
    && [[ "$(pip --version)" == *"python 3.12"* ]] \
    && poetry --version \
    && geos-config --version \
    && projinfo EPSG:4326 > /dev/null \
    && [[ "$(make --version)" == "GNU Make 4.4"* ]] \
    && uv --version \
    && /root/.bin/packer version \
    && /root/.bin/packer-1.7.5 version
