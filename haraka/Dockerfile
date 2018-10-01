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
 && apk --no-cache --update add --virtual .gyp \
    g++ gcc git make python libcap \
 && npm install --unsafe-perm -g Haraka \
 && setcap cap_net_bind_service=+ep `readlink -f \`which node\`` \
 && setcap cap_net_bind_service=+ep /usr/local/lib/node_modules/Haraka/bin/haraka \
 && haraka -i /app/haraka \
 && cd /app/haraka \
 && npm install \
 && chown -R node:node /app \
 && mkdir -p /app/haraka-bak /app/haraka/plugins \
 && rsync -raz /app/haraka/ /app/haraka-bak \
 && chown -R node:node /app/haraka-bak \
 && curl -fSL https://raw.githubusercontent.com/madeingnecca/haraka-plugins/master/relay_fake.js -o /app/haraka/plugins/relay_fake.js \
 && rm -rf /var/cache/apk/*
EXPOSE 25 80 443 465 587
VOLUME ["/app"]
CMD ["/boot.sh"]
