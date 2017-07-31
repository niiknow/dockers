FROM niiknow/base:0.1.0

MAINTAINER noogen <friends@niiknow.org>

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"

COPY rootfs/. /

RUN apk update && apk upgrade && \

# Make info file about this build
  printf "Build of niiknow/mariadb, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/10_mariadb && \

  apk add --no-cache \
      mariadb \
      mariadb-client \
      pwgen && \

# comment out any "user" in the MySQL config, let it be set by startup or runit
  sed -ri 's/^user\s/#&/' /etc/mysql/my.cnf && \

# Disable confd service
  rm -rf /etc/services.d/*confd && \

# cleanup
  rm -rf /var/cache/apk/*

EXPOSE 3306

VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/log/mysql"]
