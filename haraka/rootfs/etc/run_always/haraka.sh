#!/bin/sh
#

echo "[i] running $0"

cd /app/haraka

# restore backup folder
if [ ! -f /app/haraka/package.json ]; then
  echo "[i] running for the 1st time"
  rsync -raz --exclude="config" /app/haraka-bak/ /app/haraka
  chown -R node:node /app/haraka
fi

mkdir -p /app/haraka/config

if [ ! -f /app/haraka/config/me ]; then
  echo "[i] sync config"
  rsync -raz /app/haraka-bak/config/ /app/haraka/config
  chown -R node:node /app/haraka/config
fi

# only run if SMTP_HOST has a value
if [ -n "$SMTP_HOST" ]; then
  echo "[i] updating smtp host to: $SMTP_HOST"
  echo "$SMTP_HOST" > /app/haraka/config/me
fi

rm -f /etc/service/haraka/down
