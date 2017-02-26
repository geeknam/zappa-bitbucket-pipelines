FROM postgres:latest

MAINTAINER Nam Ngo <namngology@gmail.com>

# remove several traces of debian python
RUN apt-get purge -y python.*

ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        libsqlite3-0 \
        libssl1.0.0 \
    && rm -rf /var/lib/apt/lists/*

# gpg: key 18ADD4FF: public key "Benjamin Peterson <benjamin@python.org>" imported
ENV GPG_KEY C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF

ENV PYTHON_VERSION 2.7.11

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 8.1.2

RUN set -ex \
    && buildDeps=' \
        curl \
        gcc \
        libbz2-dev \
        libc6-dev \
        libncurses-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        make \
        xz-utils \
        zlib1g-dev \
    ' \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
    && curl -fSL "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
    && curl -fSL "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
    && gpg --batch --verify python.tar.xz.asc python.tar.xz \
    && rm -r "$GNUPGHOME" python.tar.xz.asc \
    && mkdir -p /usr/src/python \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz \
    \
    && cd /usr/src/python \
    && ./configure --enable-shared --enable-unicode=ucs4 \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && curl -fSL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
    && pip install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
    && find /usr/local -depth \
        \( \
            \( -type d -a -name test -o -name tests \) \
            -o \
            \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        \) -exec rm -rf '{}' + \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -rf /usr/src/python ~/.cache

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc \
        libpq-dev \
        libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

ADD requirements.txt /requirements.txt

RUN pip install -r /requirements.txt
