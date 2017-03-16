FROM alpine:latest
ENV GIT_HOME=/var/git
ARG user=git
ARG group=git
ARG uid=1001
ARG gid=1001
RUN apk add --no-cache openssh git bash && \
  addgroup -g ${gid} ${group} && \
  adduser -h "$GIT_HOME" -s /bin/bash -G ${group} -u ${uid} -D ${user} && \
  passwd -d ${user} && \
  mkdir -p /var/run/sshd /usr/share/ssh/ref /usr/share/git/ref/.ssh && \
  cp /etc/ssh/sshd_config /usr/share/ssh/ref/sshd_config && \
  sed -i 's/#\?PasswordAuthentication\b.*/PasswordAuthentication no/' /usr/share/ssh/ref/sshd_config && \
  sed -i 's/#\?ChallengeResponseAuthentication\b.*/ChallengeResponseAuthentication no/' /usr/share/ssh/ref/sshd_config && \
  sed -i 's/#\?PermitRootLogin\b.*$/PermitRootLogin no/' /usr/share/ssh/ref/sshd_config && \
  touch /usr/share/git/ref/.ssh/authorized_keys && \
  chown -R ${user}:${group} /usr/share/git && \
  chmod 700 /usr/share/git/ref/.ssh && \
  chmod 600 /usr/share/git/ref/.ssh/authorized_keys
COPY entrypoint.sh /entrypoint.sh
EXPOSE 22
VOLUME /etc/ssh
VOLUME /var/git
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-De"]
