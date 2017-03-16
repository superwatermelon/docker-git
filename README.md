# Git Docker Image

Docker image for serving Git repositories over SSH.

### Basic usage

```
docker run --detach --publish 22:22 --name git superwatermelon/git:latest
```

Adding an authorized SSH key:

```
docker exec --interactive \
  git bash -c 'cat - >>/var/git/.ssh/authorized_keys' <~/.ssh/id_rsa
```

Creating a repository:

```
ssh git@localhost git init --bare myrepo.git
```

Cloning the repository:

```
git clone git@localhost:myrepo.git
```

### Advanced usage

The repositories and authorized keys live in `/var/git` and can be mounted
from the host.

To preserve or add host keys across containers use the mount point `/etc/ssh`,
this can be mounted to the host and will cause the SSH host fingerprint to
remain the same. This prevents seeing the following message:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
```

To mount the volumes:

```
docker run \
  --detach \
  --publish 22:22 \
  --volume /data/ssh:/etc/ssh \
  --volume /data/git:/var/git \
  --name git \
  superwatermelon/git:latest
```

### Non-standard SSH port

To use a non-standard SSH port, i.e.:

```
docker run --detach --publish 2222:22 --name git superwatermelon/git:latest
```

Create a `~/.ssh/config` file, with the following contents:

```
Host git.example.com
Port 2222
IdentityFile ~/key
```

Clone as normal:

```
git clone git@git.example.com:myrepo.git
```
