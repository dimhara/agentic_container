#!/bin/bash
if [ -z "$DISPLAY" ]; then
    # Clean up old locks silently
    rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null
    # 1. Start Xvnc and send output to a log file
    Xvnc :1 -geometry 1280x720 -depth 24 -rfbauth ~/.vnc/passwd > /tmp/xvnc.log 2>&1 &
    # 2. Export Display
    export DISPLAY=:1
    # 3. Start fluxbox and send output to a log file
    fluxbox > /tmp/fluxbox.log 2>&1 &
    # 4. Start noVNC proxy and send output to a log file
    /usr/share/novnc/utils/novnc_proxy --vnc 127.0.0.1:5901 --listen 0.0.0.0:6080 > /tmp/novnc.log 2>&1 &
    # 5. Print a single, clean success message
    echo "🖥️  Desktop securely sandboxed at http://localhost:6080/vnc.html"
fi
