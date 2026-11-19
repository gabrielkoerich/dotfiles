# echo "Loading .zprofile"

unsetopt HIST_VERIFY

# ssh shares one connection per server through sockets here, ~/.ssh/config is synced but the sockets stay on this machine
[ -d ~/.ssh/cm ] || mkdir -m 700 -p ~/.ssh/cm
