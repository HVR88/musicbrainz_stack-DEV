#!/usr/bin/env bash

set -e -u

# shellcheck source=admin/lib/common.inc.bash
source "$(dirname "${BASH_SOURCE[0]}")/admin/lib/common.inc.bash"

admin/preflight

${DOCKER_COMPOSE_CMD} up -d --build
