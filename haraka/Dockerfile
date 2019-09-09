FROM node:12-alpine
LABEL maintainer="noogen <friends@niiknow.org>"
USER root
ENV HOME=/root PATH=$PATH:/usr/local/bin HARAKA=/app/haraka
WORKDIR /root
COPY rootfs/. /
RUN mkdir -p /etc/BUILDS/ \
 && printf "Build of niiknow/haraka, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/10_haraka \
 && chmod +x /sysprepz/base-install.sh \
 && sh /sysprepz/base-install.sh \
 && apk --no-cache --update add --virtual deps \
    g++ gcc git make python \
 && npm install --unsafe-perm -g git+https://github.com/haraka/Haraka.git \
 && haraka -i $HARAKA \
 && cd $HARAKA \
 && npm install \
 && npm install --save aws-sdk \
 && mkdir -p $HARAKA-bak $HARAKA/plugins \
 && sh /sysprepz/install-plugins.sh \
 && rsync -raz $HARAKA/ $HARAKA-bak \
 && chown -R node:node /app \
 && apk del --purge deps \
 && rm -rf /var/cache/apk/* /tmp/* /sysprepz/*
EXPOSE 25 80 443 465 587
VOLUME ["/app/haraka"]
CMD ["/boot.sh"]
