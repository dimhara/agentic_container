#!/bin/sh
set -e

# If .bashrc does not exist, copy default skeleton dotfiles
if [ ! -f "$HOME/.bashrc" ]; then
    echo "Initializing home directory from /etc/skel..."
    # -n (no-clobber) ensures existing files are never overwritten
    cp -r -n /etc/skel/. "$HOME/"
    
    echo '[ -f /home/user/workspace/init.sh ] && . /home/user/workspace/init.sh' >> /home/user/.bashrc
fi

mkdir -p /home/user/workspace


# bellow is emacs specific (runs outside bash)
[ -f /home/user/workspace/init.sh ] && . /home/user/workspace/init.sh

# Execute the container command (default: emacs)
exec "$@"
