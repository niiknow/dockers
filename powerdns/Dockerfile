FROM niiknow/mariadb:0.1.2

MAINTAINER noogen <friends@niiknow.org>

ENV POWERDNS_VERSION=4.0.4 \
    MYSQL_AUTOCONF=true \
    MYSQL_HOST="127.0.0.1" \
    MYSQL_PORT="3306" \
    MYSQL_DATABASE="pdns" \
    MYSQL_USER="pdns" \
    MYSQL_PASSWORD="pdns"

RUN \
  apk --update add mysql-client mariadb-client-libs libpq sqlite-libs libstdc++ libgcc && \
  apk add --virtual build-deps g++ make mariadb-dev postgresql-dev sqlite-dev curl boost-dev && \

# Make info file about this build
  printf "Build of niiknow/powerdns, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/powerdns && \

# get powerdns
  curl -sSL https://downloads.powerdns.com/releases/pdns-$POWERDNS_VERSION.tar.bz2 | tar xj -C /tmp && \

# build
  cd /tmp/pdns-$POWERDNS_VERSION && \
  ./configure --prefix="" --exec-prefix=/usr --sysconfdir=/etc/pdns \
    --with-modules="bind gmysql gpgsql gsqlite3" --without-lua && \

# install
  make && make install-strip && cd / && \
  mkdir -p /etc/pdns/conf.d && \

# setup user
  addgroup -S pdns 2>/dev/null && \
  adduser -S -D -H -h /var/empty -s /bin/false -G pdns -g pdns pdns 2>/dev/null && \

# purge build
  apk del --purge build-deps && \

# cleanup
  rm -rf /tmp/pdns-$POWERDNS_VERSION /var/cache/apk/*

COPY rootfs/. /

RUN \
# move syspreps
  mv /root/syspreps/etc/pdns/* /etc/pdns/ && \
  rm -rf /root/syspreps

EXPOSE 53/udp 53/tcp 80 8001 53000

VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/log/mysql", "/etc/pdns"]
