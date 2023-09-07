FROM alpine:3.16 as builder

WORKDIR /build

RUN apk update && \
    apk add \
      alpine-sdk \
      autoconf \
      automake \
      ca-certificates \
      cargo \
      gettext \
      git \
      libsodium \
      libtool \
      net-tools \
      postgresql-dev \
      py3-mako \
      python3 \
      python3-dev \
      sqlite-dev \
      sqlite-static \
      zlib-dev \
      zlib-static

RUN git clone -b 2023-08-remote-hsmd-v23.08rc3 --recursive https://github.com/lightning-signer/c-lightning.git /repo --recursive && \
    cd /repo && \
    ./configure --enable-static --prefix=/usr && \
    make -j $(nproc) && \
    make install

RUN apk add \
      autoconf-archive \
      bind-tools \
      build-base \
      curl-dev \
      libev-dev \
      pkgconf \
      sqlite-dev

RUN git clone -b 2023-09-gnuc-version --recurse-submodules https://github.com/ksedgwic/clboss.git /clboss && \
    cd /clboss && \
    autoreconf -i && \
    ./configure --prefix=/usr && \
    make -j $(nproc) && \
    make install

FROM alpine:3.16 as runner

RUN apk update && \
    apk add \
      python3 \
      postgresql \
      bitcoin-cli \
      pkgconf \
      build-base \
      bind-tools \
      libev-dev \
      curl-dev \
      sqlite-dev

ARG LIGHTNINGD_UID=101
ENV LIGHTNINGD_USER=lightning
ENV LIGHTNINGD_HOME=/home/${LIGHTNINGD_USER}
ENV LIGHTNINGD_DATA=${LIGHTNINGD_HOME}/.lightning \
    LIGHTNINGD_RPC_PORT=9835 \
    LIGHTNINGD_PORT=9735 \
    LIGHTNINGD_NETWORK=testnet \
    BITCOIND_HOME=/root/.bitcoin

COPY lightningd/entrypoint.sh /entrypoint.sh

COPY --from=builder /usr/bin/lightningd /usr/bin/
COPY --from=builder /usr/bin/lightning-cli /usr/bin/
COPY --from=builder /usr/bin/lightning-hsmtool /usr/bin/
COPY --from=builder /usr/libexec/c-lightning /usr/libexec/c-lightning
COPY --from=builder /usr/share/man/man8 /usr/share/man/man8
COPY --from=builder /usr/share/doc/c-lightning /usr/share/doc/c-lightning
COPY --from=builder /usr/bin/clboss /usr/bin/clboss

RUN addgroup -S lightning && adduser -S lightning -G lightning && \
    mkdir -p ${LIGHTNINGD_DATA} && \
    touch ${LIGHTNINGD_DATA}/config && \
    chown -R lightning:lightning "${LIGHTNINGD_DATA}"

VOLUME ["${LIGHTNINGD_DATA}"]

RUN mkdir -p "${BITCOIND_HOME}" && \
    chown -R lightning:lightning "${BITCOIND_HOME}"

COPY assets/remote_bitcoin.conf "${BITCOIND_HOME}"/bitcoin.conf

USER lightning

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s \
    CMD lighting-cli --testnet getinfo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["lightningd"]