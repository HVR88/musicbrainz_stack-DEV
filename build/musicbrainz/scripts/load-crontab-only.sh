#!/bin/bash

set -e -u

dockerize \
  -wait "tcp://${MUSICBRAINZ_POSTGRES_SERVER}:5432" -timeout 60s \
  -wait "tcp://${MUSICBRAINZ_REDIS_SERVER}:6379" -timeout 60s \
  true

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

build_replication_schedule() {
  if [ -n "${MUSICBRAINZ_REPLICATION_SCHEDULE:-}" ]; then
    echo "$MUSICBRAINZ_REPLICATION_SCHEDULE"
    return 0
  fi
  local time="${MUSICBRAINZ_REPLICATION_TIME:-03:00}"
  if [[ ! "$time" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
    echo "Invalid MUSICBRAINZ_REPLICATION_TIME: '$time' (expected HH:MM 24hr)" >&2
    return 1
  fi
  local hh="${time%%:*}"
  local mm="${time##*:}"
  echo "${mm} ${hh} * * *"
}

if is_true "${MUSICBRAINZ_REPLICATION_ENABLED:-0}"; then
  if [ -z "${MUSICBRAINZ_REPLICATION_TOKEN:-}" ] && [ ! -f /run/secrets/metabrainz_access_token ]; then
    echo "Replication enabled but no access token found; skipping cron setup."
  else
    schedule="$(build_replication_schedule)"
    cat > /crons.conf <<EOF
SHELL=/bin/bash
BASH_ENV=/noninteractive.bash_env
${schedule} /usr/local/bin/replication.sh
EOF
    crontab /crons.conf
    cron -f &
  fi
fi

sleep infinity
