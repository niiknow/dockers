FROM niiknow/base:0.1.3

MAINTAINER noogen <friends@niiknow.org>

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"

COPY rootfs/. /

RUN \
  # Make info file about this build
    printf "Build of niiknow/mariadb, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/10_mariadb && \

    apk add --no-cache rsync \
        mariadb \
        mariadb-client && \

  # comment out any "user" in the MySQL config, let it be set by startup or runit
    sed -ri 's/^user\s/#&/' /etc/mysql/my.cnf && \

  # comment out a few problematic configuration values
  # don't reverse lookup hostnames, they are usually another container
    echo "skip-name-resolve" | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
    && mv /tmp/my.cnf /etc/mysql/my.cnf && \
    echo "skip-host-cache" | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
    && mv /tmp/my.cnf /etc/mysql/my.cnf && \

  # change run socket
    sed -i 's/\/run\/mysqld\/mysqld.sock/\/var\/run\/mysqld\/mysqld\.sock/' /etc/mysql/my.cnf && \

  # Disable confd service
    rm -rf /etc/services.d/*confd && \

  # backup mysql conf
    rsync -a /etc/mysql/ /etc/mysql-bak && \

  # cleanup
    rm -rf /var/cache/apk/*

EXPOSE 3306

VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/log/mysql"]
