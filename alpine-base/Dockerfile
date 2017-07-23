FROM alpine:edge

MAINTAINER noogen <friends@niiknow.org>

RUN echo "@community http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \

    # read packages and update
    apk update && apk upgrade && \

    # add packages
    apk add ca-certificates rsyslog logrotate runit curl && \

    # add extra package for installation
    cd /tmp && \

    # Install utils and init process from minis project
    curl -Ls https://github.com/nimmis/docker-utils/archive/master.tar.gz | tar xfz - && \
    /tmp/docker-utils-master/install.sh && \

    # fix container bug for syslog, by disabling: emerg and imklog
    sed -i "s|\*.emerg|\#\*.emerg|" /etc/rsyslog.conf && \
    sed -i 's/$ModLoad imklog/#$ModLoad imklog/' /etc/rsyslog.conf && \
    sed -i 's/$KLogPermitNonKernelFacility on/#$KLogPermitNonKernelFacility on/' /etc/rsyslog.conf && \

    # cleanup
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["/boot.sh"]
