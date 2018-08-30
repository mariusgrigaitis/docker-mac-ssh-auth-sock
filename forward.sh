#!/usr/bin/env bash

if ! which socat >/dev/null; then
    echo "socat is missing. Install it: brew install socat"
    exit 1
fi

if ! docker ps >/dev/null; then
    echo "Docker for Mac is not running. Make sure it's running"
    exit 1
fi

if [[ -z "${SSH_AUTH_SOCK}" ]]; then
    echo "SSH_AUTH_SOCK is missing. Is ssh-agent running?"
    exit 1
fi

if ! test -S ${SSH_AUTH_SOCK}; then
    echo "$SSH_AUTH_SOCK is not a socket. Check agent?"
    exit 1
fi

TTY_FILE=~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty

if ! test -c $TTY_FILE; then
    echo "$TTY_FILE is not available. Docker for Mac setup has changed?"
    exit 1
fi

# This is where the UGLY hack starts
#
# Problem: if you do: docker run -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK container
# you get a socket file which is mounted over osxfs from Mac host.
# This socket file can't be reused or removed because it would make ssh commands on
# host machine to not work
#
# Solution:
# 1. connect to VM over special tty channel
# 2. create an empty directory
# 3. bind mount that empty directory over $SSH_AUTH_SOCK directory
# 4. Profit
#
# This makes other docker containers see the created directory instead of osxfs mounted one.
# It also allows to create socket file under same path that does not collide with host one.
# Command is sent over special tty channel to Docker for Mac VM and does not check for errors, etc
# meaning it could be very "unreliable"
COMMAND="mkdir -p /ssh-auth-sock-hack && mount -o bind /ssh-auth-sock-hack $(dirname $SSH_AUTH_SOCK) && rmdir $SSH_AUTH_SOCK"

echo ctr -n services.linuxkit tasks exec --exec-id 'ssh-$(hostname)-$$' docker sh -c \"$COMMAND\" > $TTY_FILE
# give some time for command to execute.
sleep 1

echo "Hoping Docker for Mac VM is prepared now"

echo "Starting socket proxy"
# This is where the proxying magic happens
# On host machine it connects to $SSH_AUTH_SOCK socket and pipes output to stdout, takes input from stdin
# On docker VM it launches a container running socat, which creates a socket file under $SSH_AUTH_SOCK path, accepts
# input and forwards it to stdout/stdin
# socat running on host machine connects stdin/stdout between those two sockets can communicate over stdin/stdout
#
# This is not really reliable because forwarding input/output over stdin/stdout does not allow for multiple communications
# at the same time. It fails when doing multiple connections to $SSH_AUTH_SOCK at the same time.
exec socat "EXEC:\"docker run -i --rm -v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK) alpine/socat UNIX-LISTEN:$SSH_AUTH_SOCK,reuseaddr,fork,unlink-early -\"" "EXEC:\"socat - UNIX:${SSH_AUTH_SOCK}\""
