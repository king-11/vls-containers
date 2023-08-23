set -e

if [ -n "${UID+x}" ] && [ "${UID}" != "0" ]; then
  usermod -u "$UID" cln
fi

if [ -n "${GID+x}" ] && [ "${GID}" != "0" ]; then
  groupmod -g "$GID" cln
fi

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for lightningd"

  set -- lightningd "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "bitcoind" ]; then
  mkdir -p "$LIGHTNING_DATA"
  chmod 700 "$LIGHTNING_DATA"
  # Fix permissions for home dir.
  chown -R cln:cln "$(getent passwd cln | cut -d: -f6)"
  # Fix permissions for bitcoin data dir.
  chown -R cln:cln "$LIGHTNING_DATA"

  echo "$0: setting data directory to $LIGHTNING_DATA"

  set -- "$@" -datadir="$LIGHTNING_DATA"
fi

if [ "$1" = "lightnigd" ] || [ "$1" = "lightning-cli" ] then
  echo
  exec su-exec bitcoin "$@"
fi

echo
exec "$@"
