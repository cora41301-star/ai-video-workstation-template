#!/usr/bin/env bash
set -u
export PATH="$HOME/.local/bin:$PATH"
printf '%-24s | %s\n' "CHECK" "RESULT"
printf '%s\n' '---------------------------------------------'
for tool in claude claude-desktop google-chrome-stable ffmpeg ffprobe yt-dlp vncserver websockify; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%-24s | PASS\n' "$tool"
  else
    printf '%-24s | MISSING\n' "$tool"
  fi
done
find /usr/share/applications "$HOME/.local/share/applications" -maxdepth 1 -iname '*hyperframes*.desktop' -print -quit 2>/dev/null | grep -q . \
  && echo 'HyperFrames Studio       | DESKTOP ENTRY FOUND' \
  || echo 'HyperFrames Studio       | CHECK MANUALLY'
if command -v claude >/dev/null 2>&1; then
  claude plugin list 2>/dev/null | grep -qi hyperframes \
    && echo 'HyperFrames Plugin       | FOUND' \
    || echo 'HyperFrames Plugin       | CHECK MANUALLY'
fi
if curl -fsSI --max-time 2 http://127.0.0.1:6080/vnc.html >/dev/null 2>&1; then
  echo 'noVNC                   | ACTIVE'
else
  echo 'noVNC                   | NOT RUNNING YET'
fi
df -h / | tail -n 1
