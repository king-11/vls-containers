FROM debian:bookworm-slim as builder

RUN apt-get update
RUN apt-get install -qq -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        gettext \
        git \
        gnupg \
        libc-dev\
        libev-dev \
        libevent-dev \
        libffi-dev \
        libgmp-dev \
        libpq-dev \
        libsqlite3-dev \
        libssl-dev \
        libtool \
        pkg-config \
        protobuf-compiler \
        python3-dev \
        python3-mako \
        python3-pip \
        python3-setuptools \
        python3-venv \
        python3.11 \
        qemu-user-static \
        wget\
        zlib1g \
        zlib1g-dev

ENV DEBIAN_FRONTEND noninteractive

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    echo 'Etc/UTC' > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get update -qq && \
    apt-get install -qq -y locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    dpkg-reconfigure -f noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN mkdir /tmp/su-exec && cd /tmp/su-exec && \
    wget -q --timeout=60 --waitretry=0 --tries=8 -O su-exec.c "https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c" && \
    mkdir -p /tmp/su-exec_install/usr/local/bin && \
    SUEXEC_BINARY="/tmp/su-exec_install/usr/local/bin/su-exec" && \
    gcc -Wall su-exec.c -o"${SUEXEC_BINARY}" && \
    chown root:root "${SUEXEC_BINARY}" && \
    chmod 0755 "${SUEXEC_BINARY}"

ENV RUST_PROFILE=release \
    PATH=$PATH:/root/.cargo/bin
RUN curl --connect-timeout 5 --max-time 15 --retry 8 --retry-delay 0 --retry-all-errors --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    rustup toolchain install stable --component rustfmt --allow-downgrade

ENV PYTHON_VERSION=3 \
    PIP_ROOT_USER_ACTION=ignore
RUN curl --connect-timeout 5 --max-time 15 --retry 8 --retry-delay 0 --retry-all-errors -sSL https://install.python-poetry.org | python3 - && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 && \
    rm /usr/lib/python3.11/EXTERNALLY-MANAGED && \
    pip3 install --upgrade pip setuptools wheel && \
    pip3 wheel cryptography && \
    pip3 install grpcio-tools

RUN cd /tmp && \
    git clone -b 2023-08-remote-hsmd-v23.08rc3 --recursive --depth 1 https://github.com/lightning-signer/c-lightning.git

WORKDIR /tmp/c-lightning/

RUN /root/.local/bin/poetry install

RUN ./configure --prefix=/usr/local \
      --disable-address-sanitizer \
      --disable-compat \
      --disable-fuzzing \
      --disable-ub-sanitize \
      --disable-valgrind \
      --enable-rust \
      --enable-static

RUN /root/.local/bin/poetry run make -j$(nproc)

RUN /root/.local/bin/poetry run make DESTDIR=/tmp/lightning_install install

RUN apt-get install -qq -y --no-install-recommends \
        libev-dev \
        libcurl4-gnutls-dev \
        libsqlite3-dev \
        dnsutils \
        autoconf-archive && \
    cd /tmp && \
    git clone https://github.com/ZmnSCPxj/clboss

WORKDIR /tmp/clboss

RUN autoreconf -f -i && \
    ./configure --prefix=/usr/local

RUN make -j$(nproc) && \
    make DESTDIR=/tmp/clboss_install install

FROM debian:bookworm-slim as runner

ARG LIGHTNINGD_UID=100
ENV LIGHTNINGD_HOME=/home/cln
ENV LIGHTNINGD_DATA=${LIGHTNINGD_HOME}/.lightning

COPY ./entrypoint.sh /entrypoint.sh

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
        inotify-tools \
        libpq5 \
        python3.11 \
        python3-pip \
        qemu-user-static \
        socat && \
    apt-get install -y --no-install-recommends \
        dnsutils \
        libev-dev \
        libcurl4-gnutls-dev \
        libsqlite3-dev && \
    apt-get auto-clean && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 0755 /entrypoint.sh && \
    useradd --no-log-init --user-group \
      --create-home --home-dir ${LIGHTNINGD_HOME} \
      --shell /bin/bash --uid ${LIGHTNINGD_UID} cln

COPY --from=builder /tmp/su-exec_install/ /
COPY --from=builder /tmp/lightning_install/ /
COPY --from=builder /usr/local/lib/python3.11/dist-packages/ /usr/local/lib/python3.11/dist-packages/
COPY --from=builder /tmp/clboss_install/ /

WORKDIR "${LIGHTNINGD_DATA}"

COPY testnet-config .
COPY testnet-env .

VOLUME ["/home/cln/.lightning"]

ENTRYPOINT ["/entrypoint.sh"]

RUN lightningd -version

CMD ["lightningd"]
