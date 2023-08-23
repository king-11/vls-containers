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
      su-exec \
      zlib-dev \
      zlib-static

COPY . /source

RUN git clone https://gitlab.com/lightning-signer/vls-hsmd /repo --recursive && \
    cd /repo/lightning && \
    ./configure --enable-static --prefix=/usr && \
    make -j $(nproc) && \
    make install

FROM alpine:3.16 as runner

RUN apk update && \
    apk add \
      postgresql

COPY --from=builder /usr/bin/lightningd /usr/bin/
COPY --from=builder /usr/bin/lightning-cli /usr/bin/
COPY --from=builder /usr/bin/lightning-hsmtool /usr/bin/
COPY --from=builder /usr/libexec/c-lightning /usr/libexec/c-lightning
COPY --from=builder /usr/share/man/man8 /usr/share/man/man8
COPY --from=builder /usr/share/doc/c-lightning /usr/share/doc/c-lightning

ENV LIGHTING_DATA=/home/cln/.lightning
VOLUME ["/home/cln/.lightning"]

COPY lightning-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

COPY testnet-config /home/cln/.lightning/
COPY testnet-env /home/cln/.lightning/

ENTRYPOINT ["/usr/bin/lightningd", "--conf=/home/cln/.lightning/testnet-config", "--network=testnet", "--log-file=/home/cln/.lightning/testnet/lightning.log"]
