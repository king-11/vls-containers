#!/bin/sh
set -e

cp -u /bitcoin.conf $BITCOIN_DATA/

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for bitcoind"

  set -- bitcoind "$@"
fi

echo
exec "$@"