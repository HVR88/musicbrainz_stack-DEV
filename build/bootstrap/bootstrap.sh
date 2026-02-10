#!/bin/bash

set -euo pipefail

log() {
  echo "[bootstrap] $*"
}

BOOTSTRAP_DB="${MUSICBRAINZ_BOOTSTRAP_DB:-1}"
BOOTSTRAP_FETCH_DUMPS="${MUSICBRAINZ_BOOTSTRAP_FETCH_DUMPS:-1}"
BOOTSTRAP_MATERIALIZED="${MUSICBRAINZ_BOOTSTRAP_MATERIALIZED:-1}"
BOOTSTRAP_WGET_OPTIONS="${MUSICBRAINZ_BOOTSTRAP_WGET_OPTIONS:-}"

DB_MARKER="${MUSICBRAINZ_BOOTSTRAP_DB_MARKER:-/media/dbdump/.bootstrap.db.done}"
MATERIALIZED_MARKER="${MUSICBRAINZ_BOOTSTRAP_MATERIALIZED_MARKER:-/media/dbdump/.bootstrap.materialized.done}"
FINAL_MARKER="${MUSICBRAINZ_BOOTSTRAP_MARKER:-/media/dbdump/.bootstrap.done}"
CLEAN_MARKERS="${MUSICBRAINZ_BOOTSTRAP_CLEAN_MARKERS:-0}"

mkdir -p "$(dirname "$DB_MARKER")"

if [[ "$CLEAN_MARKERS" == "1" ]]; then
  log "Cleaning bootstrap markers."
  rm -f "$DB_MARKER" "$MATERIALIZED_MARKER" "$FINAL_MARKER"
  exit 0
fi

_db_exists() {
  carton exec -- /musicbrainz-server/script/database_exists MAINTENANCE >/dev/null 2>&1
}

if [[ "$BOOTSTRAP_DB" == "1" ]]; then
  if [[ -f "$DB_MARKER" ]]; then
    log "DB marker exists at $DB_MARKER, skipping database creation."
  elif _db_exists; then
    log "Database already exists, writing marker."
    touch "$DB_MARKER"
  else
    log "Creating database and importing dumps. This can take hours."
    if [[ "$BOOTSTRAP_FETCH_DUMPS" == "1" ]]; then
      if [[ -n "$BOOTSTRAP_WGET_OPTIONS" ]]; then
        createdb.sh -fetch -wget-opts "$BOOTSTRAP_WGET_OPTIONS"
      else
        createdb.sh -fetch
      fi
    else
      if [[ -n "$BOOTSTRAP_WGET_OPTIONS" ]]; then
        createdb.sh -wget-opts "$BOOTSTRAP_WGET_OPTIONS"
      else
        createdb.sh
      fi
    fi
    touch "$DB_MARKER"
    log "Database bootstrap complete."
  fi
else
  log "Database bootstrap disabled (MUSICBRAINZ_BOOTSTRAP_DB=$BOOTSTRAP_DB)."
fi

if [[ "$BOOTSTRAP_MATERIALIZED" == "1" ]]; then
  if [[ -f "$MATERIALIZED_MARKER" ]]; then
    log "Materialized marker exists at $MATERIALIZED_MARKER, skipping."
  else
    if _db_exists; then
      log "Building materialized tables (default enabled)."
      carton exec -- /musicbrainz-server/admin/BuildMaterializedTables --database=MAINTENANCE all
      touch "$MATERIALIZED_MARKER"
      log "Materialized tables complete."
    else
      log "Database not found; skipping materialized tables."
    fi
  fi
else
  log "Materialized tables disabled (MUSICBRAINZ_BOOTSTRAP_MATERIALIZED=$BOOTSTRAP_MATERIALIZED)."
fi

touch "$FINAL_MARKER"
log "Bootstrap finished."
