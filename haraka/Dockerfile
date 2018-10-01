FROM niiknow/base:0.2.2

LABEL maintainer="noogen <friends@niiknow.org>"

ENV USER=root

RUN printf "Build of niiknow/haraka, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/10_haraka && \
 apk --no-cache --update add --virtual .gyp \
    nodejs nodejs-npm g++ gcc git make bash python libcap rsync \
 && npm install --unsafe-perm -g Haraka \
 && setcap cap_net_bind_service=+ep `readlink -f \`which node\`` \
 && setcap cap_net_bind_service=+ep /usr/lib/node_modules/Haraka/bin/haraka \
 && haraka -i /usr/local/app/haraka \
 && cd /usr/local/app/haraka \
 && npm install \
 && chown -R app:app /usr/local/app \
 && mkdir -p /usr/local/app/haraka-bak \
 && rsync -a /usr/local/app/haraka /usr/local/app/haraka-bak \
 && chown -R app:app /usr/local/app/haraka-bak \
 && curl -fSL https://raw.githubusercontent.com/madeingnecca/haraka-plugins/master/relay_fake.js -o /usr/local/app/haraka/plugins/relay_fake.js \
 && rm -rf /var/cache/apk/*

COPY rootfs/. /

EXPOSE 25 80 443 465 587
