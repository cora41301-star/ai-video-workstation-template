#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGDIR="$HOME/.cache/ai-video-workstation"
mkdir -p "$LOGDIR"
exec > >(tee -a "$LOGDIR/install.log") 2>&1
trap 'echo "[ERROR] Setup failed near line $LINENO. Read $LOGDIR/install.log and README_AR.md." >&2' ERR
export DEBIAN_FRONTEND=noninteractive
export PATH="$HOME/.local/bin:$PATH"

note() { printf '\n========== %s ==========\n' "$*"; }
warn() { printf '[WARNING] %s\n' "$*" >&2; }

note "SYSTEM CHECK"
printf 'User: %s\n' "$(id -un)"
printf 'CPU: %s\n' "$(nproc)"
free -h | head -n 2
df -h / | tail -n 1
if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
  echo "This template currently supports amd64 Linux only" >&2
  exit 1
fi

note "APT: switch Ubuntu mirror URLs to HTTPS, with backups"
backup="$LOGDIR/apt-sources-backup-$(date +%Y%m%d%H%M%S)"
sudo mkdir -p "$backup"
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list; do
  [[ -f "$f" ]] || continue
  if grep -Eq 'http://(archive|security).ubuntu.com/ubuntu' "$f"; then
    sudo cp -a "$f" "$backup/$(basename "$f")"
    sudo sed -i -e 's@http://archive.ubuntu.com/ubuntu@https://archive.ubuntu.com/ubuntu@g' \
      -e 's@http://security.ubuntu.com/ubuntu@https://security.ubuntu.com/ubuntu@g' "$f"
  fi
done
APT=(sudo apt-get -o Acquire::ForceIPv4=true -o Acquire::Retries=2 -o Acquire::https::Timeout=30)
"${APT[@]}" update

note "INSTALL GUI + VIDEO BASICS"
"${APT[@]}" install -y --no-install-recommends \
  ca-certificates curl gnupg python3 xz-utils \
  xfce4 xfce4-terminal thunar dbus-x11 \
  tigervnc-standalone-server tigervnc-tools novnc websockify \
  ffmpeg fonts-noto-core fonts-noto-color-emoji

note "CHROME (official Debian package)"
if ! command -v google-chrome-stable >/dev/null 2>&1; then
  curl -fL --retry 2 --connect-timeout 15 --max-time 180 \
    'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb' \
    -o /tmp/ai-workstation-chrome.deb
  if [[ "$(dpkg-deb -f /tmp/ai-workstation-chrome.deb Package)" != "google-chrome-stable" ]]; then
    echo "Chrome package identity check failed" >&2; exit 1
  fi
  "${APT[@]}" install -y /tmp/ai-workstation-chrome.deb
  rm -f /tmp/ai-workstation-chrome.deb
fi

note "CLAUDE DESKTOP (signed official apt repository)"
if ! dpkg-query -W -f='${Status}' claude-desktop 2>/dev/null | grep -q 'install ok installed'; then
  curl -fsSLo /tmp/ai-workstation-claude-key.asc \
    'https://downloads.claude.ai/claude-desktop/key.asc'
  key_fingerprint="$(gpg --show-keys --with-colons /tmp/ai-workstation-claude-key.asc 2>/dev/null | awk -F: '$1 == "fpr" {print $10; exit}')"
  if [[ "$key_fingerprint" != "31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE" ]]; then
    echo "Claude Desktop signing-key fingerprint mismatch; refusing installation" >&2
    exit 1
  fi
  sudo install -m 0644 /tmp/ai-workstation-claude-key.asc /usr/share/keyrings/claude-desktop-archive-keyring.asc
  printf '%s\n' 'deb [signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main' | sudo tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null
  "${APT[@]}" update
  "${APT[@]}" install -y claude-desktop
  rm -f /tmp/ai-workstation-claude-key.asc
fi

note "CLAUDE CODE CLI (official installer)"
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL --retry 2 --max-time 90 'https://claude.ai/install.sh' -o /tmp/ai-workstation-claude-install.sh
  bash /tmp/ai-workstation-claude-install.sh
  rm -f /tmp/ai-workstation-claude-install.sh
fi
if ! grep -qF 'AI_VIDEO_WORKSTATION_LOCAL_BIN' "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# AI_VIDEO_WORKSTATION_LOCAL_BIN\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
fi

note "YT-DLP"
mkdir -p "$HOME/.local/bin"
if [[ ! -x "$HOME/.local/bin/yt-dlp" ]]; then
  curl -fL --retry 2 --connect-timeout 15 --max-time 120 \
    'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp' \
    -o "$HOME/.local/bin/yt-dlp"
  chmod 755 "$HOME/.local/bin/yt-dlp"
fi

note "HYPERFRAMES STUDIO (official Linux package)"
if ! find /usr/share/applications "$HOME/.local/share/applications" -maxdepth 1 -iname '*hyperframes*.desktop' -print -quit 2>/dev/null | grep -q .; then
  if curl -fL --retry 2 --connect-timeout 15 --max-time 240 \
      'https://hyperframes.studio/studio/download?os=deb&src=docs-install' \
      -o /tmp/ai-workstation-hyperframes.deb; then
    if dpkg-deb -f /tmp/ai-workstation-hyperframes.deb Package 2>/dev/null | grep -qi 'hyperframes'; then
      if ! "${APT[@]}" install -y /tmp/ai-workstation-hyperframes.deb; then
        warn "HyperFrames Studio installation failed; try the official download manually."
      fi
    else
      warn "HyperFrames package did not pass package-name check, so it was not installed."
    fi
    rm -f /tmp/ai-workstation-hyperframes.deb
  else
    warn "HyperFrames Studio download failed; retry later."
  fi
fi

note "CLAUDE CODE HYPERFRAMES PLUGIN"
if command -v claude >/dev/null 2>&1; then
  if ! claude plugin marketplace add heygen-com/hyperframes; then
    warn "HyperFrames marketplace registration could not complete."
  fi
  if ! claude plugin install hyperframes@hyperframes; then
    warn "HyperFrames plugin installation could not complete."
  fi
else
  warn "Claude Code not found, so its plugin cannot be added."
fi

note "DESKTOP ICONS"
mkdir -p "$HOME/Desktop" "$ROOT/video-projects" "$ROOT/video-projects/exports" "$ROOT/video-projects/assets" "$ROOT/video-projects/references" "$HOME/.local/bin"
copy_desktop_file() {
  local pattern="$1" target="$2" found
  found="$(find /usr/share/applications "$HOME/.local/share/applications" -maxdepth 1 -iname "$pattern" -print -quit 2>/dev/null || true)"
  if [[ -n "$found" && -f "$found" ]]; then
    cp "$found" "$HOME/Desktop/$target"
    chmod 755 "$HOME/Desktop/$target"
  else
    warn "Desktop launcher not found: $pattern"
  fi
}
copy_desktop_file '*chrome*.desktop' 'Google Chrome.desktop'
copy_desktop_file '*claude*.desktop' 'Claude Desktop.desktop'
copy_desktop_file '*hyperframes*.desktop' 'HyperFrames.desktop'
cat > "$HOME/.local/bin/launch-claude-video" <<EOF2
#!/usr/bin/env bash
export PATH="\$HOME/.local/bin:\$PATH"
cd "$ROOT/video-projects" || exit 1
exec claude
EOF2
chmod 755 "$HOME/.local/bin/launch-claude-video"
cat > "$HOME/Desktop/Claude Code.desktop" <<EOF2
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Code (Terminal)
Comment=Launch Claude Code for video projects
Exec=xfce4-terminal --disable-server --command=$HOME/.local/bin/launch-claude-video
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF2
chmod 755 "$HOME/Desktop/Claude Code.desktop"
ln -sfn "$ROOT/video-projects" "$HOME/Desktop/Video Files"

note "PRIVATE DESKTOP PASSWORD (NOT COMMITTED)"
mkdir -p "$HOME/.vnc"
if [[ ! -s "$HOME/.cache/ai-video-workstation/desktop-password" ]]; then
  python3 - <<'PY' > "$HOME/.cache/ai-video-workstation/desktop-password"
import secrets
alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
print(''.join(secrets.choice(alphabet) for _ in range(8)))
PY
fi
chmod 600 "$HOME/.cache/ai-video-workstation/desktop-password"
cat "$HOME/.cache/ai-video-workstation/desktop-password" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
cat > "$HOME/.vnc/xstartup" <<'EOF2'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
EOF2
chmod 700 "$HOME/.vnc/xstartup"

note "NOVNC WELCOME PAGE"
WEB="$HOME/.local/share/ai-video-workstation/novnc"
mkdir -p "$(dirname "$WEB")"
if [[ ! -d "$WEB" ]]; then
  cp -a /usr/share/novnc "$WEB"
fi
cat > "$WEB/index.html" <<'EOF2'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=vnc.html?autoconnect=1"><title>سطح المكتب</title></head><body><a href="vnc.html?autoconnect=1">فتح سطح المكتب</a></body></html>
EOF2

cat > "$ROOT/DESKTOP_ACCESS.md" <<EOF2
# افتح سطح المكتب الآن

✅ اكتمل التجهيز على هذه الآلة **إذا ظهرت جميع البرامج في تقرير الفحص**.

1. افتح تبويب **PORTS** الموجود بجوار Terminal في Codespaces.
2. اختر المنفذ **6080** ثم **Open in Browser**.
3. تأكد من أن **Port Visibility = Private**. لا تستخدم **Make Public**.
4. عند ظهور noVNC، أدخل كلمة المرور التالية:

**كلمة مرور سطح المكتب: \`$(cat "$HOME/.cache/ai-video-workstation/desktop-password")\`**

5. افتح البرامج من سطح المكتب: Chrome وClaude وHyperFrames.
6. سجّل الدخول بحسابك الشخصي في Claude وHeyGen فقط، ولا تشارك بيانات الدخول.

> هذا الملف ينشأ محليًا آليًا وممنوع من Git عبر .gitignore؛ **لا ترفعه إلى المستودع أو تشارك صورته**.
>
> إذا لم يظهر المنفذ 6080، نفّذ من Terminal: \`bash scripts/start-desktop.sh\`.
EOF2
chmod 600 "$ROOT/DESKTOP_ACCESS.md"

note "FINAL STATUS"
bash "$ROOT/scripts/verify.sh" || true
printf '\nInstallation log: %s\n' "$LOGDIR/install.log"
printf 'Desktop instructions: %s\n' "$ROOT/DESKTOP_ACCESS.md"
echo "INSTALL COMPLETE"
