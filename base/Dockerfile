FROM alpine:edge
LABEL maintainer="noogen <friends@niiknow.org>"
USER root
ENV HOME /root
WORKDIR /root
COPY rootfs/. /
RUN echo "@community http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && apk upgrade && \
    apk add ca-certificates rsyslog logrotate runit curl sudo bash && \
    mkdir -p /etc/BUILDS/ && \
    printf "Build of niiknow/base, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` > /etc/BUILDS/00_niiknow_base && \
    cd /tmp && \
    curl -Ls https://github.com/nimmis/docker-utils/archive/master.tar.gz | tar xfz - && \
    /tmp/docker-utils-master/install.sh && \
    sed -i "s|\*.emerg|\#\*.emerg|" /etc/rsyslog.conf && \
    sed -i 's/$ModLoad imklog/#$ModLoad imklog/' /etc/rsyslog.conf && \
    sed -i 's/$KLogPermitNonKernelFacility on/#$KLogPermitNonKernelFacility on/' /etc/rsyslog.conf && \
    sed -i "s/-exec.*/-print0 \| sort -zn \| xargs -0 -I '{}' '{}'/" /etc/runit/1 && \
    mkdir -p /usr/local/app && \
    addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app -s /bin/bash -h /usr/local/app && \
    adduser app wheel && \
    chown -R app:app /usr/local/app && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel && \
    rm -rf /var/cache/apk/* /tmp/*
CMD ["/boot.sh"]
