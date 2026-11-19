#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 -m json.tool "$ROOT/.devcontainer/devcontainer.json" >/dev/null
for f in "$ROOT"/scripts/*.sh; do
  bash -n "$f"
done
for f in README_AR.md START_HERE_AR.md .gitignore .devcontainer/devcontainer.json; do
  test -s "$ROOT/$f"
done
if grep -RniE '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|ghp_[a-zA-Z0-9]{30}|sk-ant-[a-zA-Z0-9]{20})' \
  "$ROOT/scripts" "$ROOT/.devcontainer" "$ROOT"/*.md; then
  echo 'Possible credential content detected' >&2
  exit 1
fi
echo 'TEMPLATE CHECK: PASS (static JSON, Bash, files, basic credential scan)'
