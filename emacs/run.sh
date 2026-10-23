#!/bin/bash
# build with: podman build -t debian-emacs-wayland .

set -e

WAYLAND_SOCKET="${WAYLAND_DISPLAY:-wayland-0}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
SOCKET_PATH="$RUNTIME_DIR/$WAYLAND_SOCKET"

# Ensure socket is accessible to the sub-UID
chmod o+rw "$SOCKET_PATH"

SANDBOX_HOME="$HOME/Documents/emacsuser"
mkdir -p "$SANDBOX_HOME"


##
podman run --name emacs --rm -it \
  --cap-drop=ALL \
  --security-opt=no-new-privileges \
  -e GSETTINGS_BACKEND=keyfile \
  -e WAYLAND_DISPLAY="$WAYLAND_SOCKET" \
  -e XDG_RUNTIME_DIR="/tmp/run" \
  -v "$SOCKET_PATH:/tmp/run/$WAYLAND_SOCKET:rw" \
  -v "$SANDBOX_HOME:/home/user:U" \
  -w /home/user \
  debian-emacs-wayland emacs

# Revert to original when Emacs exits
podman unshare chown -R 0:0 "$SANDBOX_HOME"
