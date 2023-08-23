#!/bin/sh
set -e

if [ -n "${UID+x}" ] && [ "${UID}" != "0" ]; then
  usermod -u "$UID" cln
fi

if [ -n "${GID+x}" ] && [ "${GID}" != "0" ]; then
  groupmod -g "$GID" cln
fi

echo "$0: assuming uid:gid for cln:cln of $(id -u cln):$(id -g cln)"

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for lightningd"

  set -- lightningd "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "lightningd" ]; then
  mkdir -p  "$LIGHTNINGD_DATA"
  chmod 700 "$LIGHTNINGD_DATA"
  # Fix permissions for home dir.
  chown -R cln:cln "$(getent passwd cln | cut -d: -f6)"
  # Fix permissions for lightning data dir.
  chown -R cln:cln "$LIGHTNING_DATA"

  echo "$0: setting data directory to $LIGHTNING_DATA"

  set -- "$@" -datadir="$LIGHTNING_DATA"
fi

if [ "$1" = "lightnigd" ] || [ "$1" = "lightning-cli" ] then
  echo
  exec su-exec cln "$@"
fi

echo
exec "$@"
