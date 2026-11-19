#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
export PATH="$HOME/.local/bin:$PATH"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOME/.cache/ai-video-workstation"
LOG="$HOME/.cache/ai-video-workstation/desktop.log"
if [[ ! -s "$HOME/.vnc/passwd" || ! -x "$(command -v vncserver || true)" ]]; then
  echo "Desktop not installed yet; see START_HERE_AR.md or install log" >&2
  exit 1
fi
if ! (ss -ltn | grep -Eq '127\.0\.0\.1:5901\b|\[::1\]:5901\b'); then
  vncserver :1 -localhost yes -geometry 1366x768 -depth 24 \
    -SecurityTypes VncAuth >> "$LOG" 2>&1 || {
    echo "VNC startup failed; see $LOG" >&2
    exit 1
  }
fi
WEB="$HOME/.local/share/ai-video-workstation/novnc"
if ! ss -ltn | grep -Eq '127\.0\.0\.1:6080\b'; then
  nohup websockify --web="$WEB" 127.0.0.1:6080 127.0.0.1:5901 >> "$LOG" 2>&1 < /dev/null &
fi
sleep 2
if curl -fsSI --max-time 5 http://127.0.0.1:6080/vnc.html >/dev/null 2>&1; then
  echo "DESKTOP READY: port 6080 (keep PRIVATE in GitHub Ports panel)"
else
  echo "DESKTOP NOT READY: inspect $LOG" >&2
  exit 1
fi
