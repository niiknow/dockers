FROM redis:4-alpine
LABEL maintainer="noogen <friends@niiknow.org>"
RUN apk update && apk add --no-cache --virtual .build-deps \
        build-base \
        gcc \
        git \
    && cd /tmp \
    && git clone \--recursive https://github.com/danni-m/redis-timeseries /tmp/redis-timeseries \
    && cd /tmp/redis-timeseries/src \
    && make \
    && cp /tmp/redis-timeseries/src/redis-tsdb-module.so /usr/local/lib/ \
    && mkdir -p /usr/local/etc/redis \
    && chown -R redis:redis /usr/local/etc/redis \
    && rm -rf /var/cache/apk/* /tmp/*
USER redis
