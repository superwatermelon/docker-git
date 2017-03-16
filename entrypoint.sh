#!/bin/bash -x

find /usr/share/ssh/ref \
  -type f \
  -exec /bin/bash -c '\
    source="{}" && \
    dest="$(echo "$source" | sed "s~/usr/share/ssh/ref~/etc/ssh~")" && \
    mkdir -p "$(dirname "$dest")" && [[ ! -f "$dest" ]] && cp -p "$source" "$dest"' \;

find /usr/share/git/ref \
  -type f \
  -exec /bin/bash -c '\
    source="{}" && \
    dest="$(echo "$source" | sed "s~/usr/share/git/ref~/var/git~")" && \
    mkdir -p "$(dirname "$dest")" && [[ ! -f "$dest" ]] && cp -p "$source" "$dest"' \;

if [[ ! -f /etc/ssh/ssh_host_rsa_key ]] ; then
    ssh-keygen -q -N '' -t rsa -f /etc/ssh/ssh_host_rsa_key
fi

if [[ ! -f /etc/ssh/ssh_host_dsa_key ]] ; then
    ssh-keygen -q -N '' -t dsa -f /etc/ssh/ssh_host_dsa_key
fi

if [[ ! -f /etc/ssh/ssh_host_ecdsa_key ]] ; then
    ssh-keygen -q -N '' -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
fi

if [[ ! -f /etc/ssh/ssh_host_ed25519_key ]] ; then
    ssh-keygen -q -N '' -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
fi

exec /usr/sbin/sshd $@
