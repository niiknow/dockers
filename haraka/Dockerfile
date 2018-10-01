FROM node:10-alpine
LABEL maintainer="noogen <friends@niiknow.org>"
USER root
ENV HOME=/root PATH=$PATH:/usr/local/bin
WORKDIR /root
COPY rootfs/. /
RUN mkdir -p /etc/BUILDS/ \
 && printf "Build of niiknow/haraka, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/10_haraka \
 && chmod +x /sysprepz/base-install.sh \
 && sh /sysprepz/base-install.sh \
 && apk --no-cache --update add --virtual deps \
    g++ gcc git make python \
 && npm install --unsafe-perm -g Haraka \
 && haraka -i /app/haraka \
 && cd /app/haraka \
 && npm install \
 && npm install --save aws-sdk \
 && mkdir -p /app/haraka-bak /app/haraka/plugins \
 && sh /sysprepz/install-plugins.sh \
 && rsync -raz /app/haraka/ /app/haraka-bak \
 && chown -R node:node /app \
 && apk del --purge deps \
 && rm -rf /var/cache/apk/* /tmp/* /sysprepz/*
EXPOSE 25 80 443 465 587
VOLUME ["/app"]
CMD ["/boot.sh"]
