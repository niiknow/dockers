#!/bin/sh
BASEURL=https://raw.githubusercontent.com

cd /app/haraka/plugins
curl -fSL $BASEURL/madeingnecca/haraka-plugins/master/relay_fake.js -o relay_fake.js

# install queue plugin
rsync -raz /sysprepz/plugins/ /app/haraka/plugins
rsync /sysprepz/config/ /app/haraka/config
