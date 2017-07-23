FROM niiknow/base

MAINTAINER noogen <friends@niiknow.org>

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"

COPY rootfs/. /

RUN apk update && apk upgrade && \

# Make info file about this build
    printf "Build of niiknow/mariadb, date: %s\n"  `date -u +"%Y-%m-%dT%H:%M:%SZ"` >> /etc/BUILD && \

    apk add --no-cache \
        mariadb \
        mariadb-client \
        pwgen && \

# comment out any "user" in the MySQL config, let it be set by startup or runit
    sed -ri 's/^user\s/#&/' /etc/mysql/my.cnf /etc/mysql/conf.d/* && \

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
    sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf && \
    echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf && \
    mv /tmp/my.cnf /etc/mysql/my.cnf && \

    # Disable confd service
    rm -rf /etc/services.d/*confd

EXPOSE 3306

VOLUME ["/var/lib/mysql"]
