#!/bin/sh
echo "@community http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk update && apk upgrade
apk add ca-certificates rsyslog logrotate runit curl sudo bash git rsync openssl
cd /tmp
curl -Ls https://github.com/nimmis/docker-utils/archive/master.tar.gz | tar xfz -
/tmp/docker-utils-master/install.sh
sed -i "s|\*.emerg|\#\*.emerg|" /etc/rsyslog.conf
sed -i 's/$ModLoad imklog/#$ModLoad imklog/' /etc/rsyslog.conf
sed -i 's/$KLogPermitNonKernelFacility on/#$KLogPermitNonKernelFacility on/' /etc/rsyslog.conf
sed -i "s/-exec.*/-print0 \| sort -zn \| xargs -0 -I '{}' '{}'/" /etc/runit/1
