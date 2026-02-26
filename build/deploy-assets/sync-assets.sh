#!/bin/sh

set -eu

log() {
  echo "[mbms-assets] $*"
}

BUNDLE_ROOT=/bundle
OUT_ROOT=/out
ASSETS_DIR="$OUT_ROOT/.mbms/assets"
ADMIN_DIR="$OUT_ROOT/admin"
VERSION_FILE="$ASSETS_DIR/.mbms-assets-version"

if [ ! -f "$BUNDLE_ROOT/VERSION" ]; then
  log "Missing bundle VERSION at $BUNDLE_ROOT/VERSION"
  exit 1
fi

bundle_version=$(cat "$BUNDLE_ROOT/VERSION")
current_version=""
if [ -f "$VERSION_FILE" ]; then
  current_version=$(cat "$VERSION_FILE")
fi

if [ -n "$current_version" ] && [ "$bundle_version" = "$current_version" ]; then
  log "Bundle version $bundle_version already applied; skipping."
  exit 0
fi

log "Syncing bundle version $bundle_version (was '$current_version')."

mkdir -p "$ASSETS_DIR" "$ADMIN_DIR"

# Visible admin scripts
rsync -a --delete "$BUNDLE_ROOT/admin/" "$ADMIN_DIR/"

# Hidden managed assets
rsync -a --delete --exclude 'admin' "$BUNDLE_ROOT/" "$ASSETS_DIR/"

# Managed root files
cp -f "$BUNDLE_ROOT/example.env" "$OUT_ROOT/example.env"
cp -f "$BUNDLE_ROOT/docker-compose.yml" "$OUT_ROOT/docker-compose.yml"

# Version marker (4-segment) for Limbo
mbms_tag_version="$bundle_version"
if [ -n "$mbms_tag_version" ]; then
  echo "$mbms_tag_version" > "$ASSETS_DIR/MBMS_TAG_VERSION"
fi

echo "$bundle_version" > "$VERSION_FILE"

# Clean legacy managed paths at repo root (keep .env)
for path in compose default build README.md VERSION LICENSE LICENSE-MUSICBRAINZ TROUBLESHOOTING.md; do
  if [ -e "$OUT_ROOT/$path" ]; then
    rm -rf "$OUT_ROOT/$path"
  fi
done

log "Sync complete."
