FROM niiknow/base:0.1.5

LABEL maintainer="noogen <friends@niiknow.org>"

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    MARIADB_MAJOR=10.2 \
    MARIADB_VERSION=10.2.13

COPY rootfs/. /

RUN printf "Build of niiknow/mariadb, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILDS/10_mariadb && \
    apk add --no-cache rsync \
        mariadb \
        mariadb-client && \
    sed -ri 's/^user\s/#&/' /etc/mysql/my.cnf && \
    echo "skip-name-resolve" | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
    && mv /tmp/my.cnf /etc/mysql/my.cnf && \
    echo "skip-host-cache" | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
    && mv /tmp/my.cnf /etc/mysql/my.cnf && \
    sed -i 's/\/run\/mysqld\/mysqld.sock/\/var\/run\/mysqld\/mysqld\.sock/' /etc/mysql/my.cnf && \
    rm -rf /etc/services.d/*confd && \
    rsync -a /etc/mysql/ /etc/mysql-bak && \
    rm -rf /var/cache/apk/*

EXPOSE 3306

VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/log/mysql"]
