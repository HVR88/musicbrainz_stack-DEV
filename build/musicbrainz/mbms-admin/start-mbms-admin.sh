#!/usr/bin/env bash

set -euo pipefail

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

if ! is_true "${MBMS_ADMIN_ENABLED:-0}"; then
  exit 0
fi

if [ -z "${MBMS_ADMIN_KEY:-}" ]; then
  echo "MBMS_ADMIN_ENABLED is true but MBMS_ADMIN_KEY is empty; skipping mbms-admin listener." >&2
  exit 0
fi

if [ ! -f /opt/mbms-admin/listener.py ]; then
  echo "mbms-admin listener not found at /opt/mbms-admin/listener.py" >&2
  exit 1
fi

python3 /opt/mbms-admin/listener.py &
