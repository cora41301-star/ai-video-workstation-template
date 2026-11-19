#!/usr/bin/env bash
set -u
# Stops the desktop GUI services only; the GitHub Codespace itself stays active.
if command -v vncserver >/dev/null 2>&1; then
  vncserver -kill :1 2>/dev/null || true
fi
# Scoped to our local websockify forward target and port.
pids="$(pgrep -f 'websockify.*127\.0\.0\.1:6080.*127\.0\.0\.1:5901' || true)"
if [[ -n "$pids" ]]; then
  kill $pids 2>/dev/null || true
fi
echo "Desktop services stopped. To stop GitHub compute billing, also Stop the Codespace at https://github.com/codespaces"
