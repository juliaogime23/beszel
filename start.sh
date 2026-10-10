#!/usr/bin/env bash
# Brings Beszel up. Safe to re-run at any time.
#
#   ./start.sh            hub + agent in Docker, built from this checkout
#   ./start.sh --build    same, rebuilding the images first
#   ./start.sh dev        hub (go run, :8090) + web UI (vite) with live reload
#
# Docker mode goes through ../infra-dev (override with INFRA_DEV=<path>).
# Dev mode pulls Go/Node through mise; the agent there needs the hub key:
#   KEY="<public key from the hub>" make dev-agent
set -euo pipefail
SELF=$(realpath "${BASH_SOURCE[0]}")
cd "$(dirname "$SELF")"

INFRA_DEV=${INFRA_DEV:-../infra-dev}
GO_VERSION=$(sed -n 's/^go //p' go.mod)
NODE_VERSION=22.22.0

mode=stack
args=()
for arg in "$@"; do
  case $arg in
    dev) mode=dev ;;
    --build) args+=(--build) ;;
    -h|--help) sed -n '2,10p' "$SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $arg (see ./start.sh --help)" >&2; exit 1 ;;
  esac
done

if [[ $mode == stack ]]; then
  [[ -x $INFRA_DEV/start.sh ]] || { echo "$INFRA_DEV/start.sh not found" >&2; exit 1; }
  exec "$INFRA_DEV/start.sh" "${args[@]}" beszel
fi

[[ ${#args[@]} -eq 0 ]] || { echo "--build does not apply to dev mode" >&2; exit 1; }
mise=$(command -v mise || echo "$HOME/.local/bin/mise")
[[ -x $mise ]] || { echo "dev mode needs mise: https://mise.jdx.dev" >&2; exit 1; }

echo "==> hub http://localhost:8090, web UI with live reload (see vite output)"
exec "$mise" exec "go@$GO_VERSION" "node@$NODE_VERSION" -- make -j2 dev-server dev-hub
