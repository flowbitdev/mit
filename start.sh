#!/bin/bash
set -Eeuo pipefail

: "${PORT:=10000}"
: "${VNC_GEOMETRY:=1366x768}"
: "${VNC_PASSWORD:=change-me-now}"
: "${START_CHROMIUM:=true}"

if [[ "$VNC_PASSWORD" == "change-me-now" || ${#VNC_PASSWORD} -lt 6 ]]; then
  echo "ERROR: Set VNC_PASSWORD to a strong password of at least 6 characters in Render environment variables." >&2
  exit 1
fi

# /var/data should be the mount path of a Render persistent disk.
mkdir -p /var/data/{.config/chromium,Downloads,Desktop,.vnc}
ln -sfn /var/data/.config/chromium "$HOME/.config-chromium"
ln -sfn /var/data/Downloads "$HOME/Downloads"
ln -sfn /var/data/Desktop "$HOME/Desktop"
mkdir -p "$HOME/.config"
ln -sfn /var/data/.config/chromium "$HOME/.config/chromium"

# TigerVNC and X11 need a local home profile and an X authority file.
mkdir -p "$HOME/.vnc" "$HOME/.cache"
touch "$HOME/.Xauthority"
chmod 600 "$HOME/.Xauthority"
export XAUTHORITY="$HOME/.Xauthority"

# TigerVNC stores only the first 8 password characters, as required by VNC auth.
printf '%s\n' "$VNC_PASSWORD" | vncpasswd -f > /var/data/.vnc/passwd
chmod 600 /var/data/.vnc/passwd
ln -sfn /var/data/.vnc/passwd "$HOME/.vnc/passwd"

# Clean up stale runtime files after an unclean container stop.
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

tigervncserver -kill :1 >/dev/null 2>&1 || true
tigervncserver :1 \
  -geometry "$VNC_GEOMETRY" \
  -depth 24 \
  -rfbauth "$HOME/.vnc/passwd" \
  -localhost no \
  -SecurityTypes VncAuth \
  -xstartup /usr/local/bin/xstartup

if [[ "$START_CHROMIUM" == "true" ]]; then
  # --no-sandbox is needed in this unprivileged container without a setuid sandbox.
  # The browser retains ordinary tabs, address bar, extensions, and Web Store access.
  DISPLAY=:1 chromium \
    --no-sandbox \
    --disable-dev-shm-usage \
    --no-first-run \
    --no-default-browser-check \
    --user-data-dir=/var/data/.config/chromium \
    --disk-cache-dir=/var/data/.cache/chromium \
    >/var/data/chromium.log 2>&1 &
fi

# noVNC uses websockify to bridge browser WebSockets to TigerVNC's TCP port.
exec websockify --web=/opt/novnc --heartbeat=30 "$PORT" 127.0.0.1:5901
