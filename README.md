# docker-mac-ssh-auth-sock

`$SSH_AUTH_SOCK` is not available in Docker for Mac. See: https://github.com/docker/for-mac/issues/410

This project proxies `$SSH_AUTH_SOCK` from host machine (Mac) to Docker for Mac VM over stdin/stdout
and exposes `$SSH_AUTH_SOCK` under the same path as in host for docker containers

## Requirements

* Docker for Mac
* Must have `socat` installed. `brew install socat`

## Usage

* `git clone git@github.com:mariusgrigaitis/docker-mac-ssh-auth-sock.git`
* `cd docker-mac-ssh-auth-sock`
* `./forward.sh`

In different terminal:

`docker run -it -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK --rm alpine:3.4 /bin/sh -c "apk update && apk add dropbear-ssh && ssh -T git@github.com"`

```
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/community/x86_64/APKINDEX.tar.gz
v3.4.6-299-ge10ec9b [http://dl-cdn.alpinelinux.org/alpine/v3.4/main]
v3.4.6-160-g14ad2a3 [http://dl-cdn.alpinelinux.org/alpine/v3.4/community]
OK: 5973 distinct packages available
(1/2) Installing dropbear (2017.75-r0)
(2/2) Installing dropbear-ssh (2017.75-r0)
Executing busybox-1.24.2-r14.trigger
OK: 5 MiB in 13 packages

Host 'github.com' is not in the trusted hosts file.
(ssh-rsa fingerprint md5 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48)
Do you want to continue connecting? (y/n) y
Hi mariusgrigaitis! You've successfully authenticated, but GitHub does not provide shell access.
```

## Disclaimer

This is really ugly solution, does not check for errors etc. It might lead to your Docker for Mac VM not working or agent on host machine
not working. In such cases, restart your Mac / Docker for Mac VM. It's also relying on undocumented features in Docker for Mac which
should not be used
