#!/bin/sh
set -e

cp -u /testnet-config ${LIGHTNINGD_DATA}/testnet-config

export GREENLIGHT_VERSION=$(lightningd --version)

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for lightningd"

  set -- lightningd "$@"
fi

echo
exec "$@"
