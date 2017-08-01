#!/bin/sh

# make sure this run after run_once/10_mariadb.sh
me=`basename "$0"`
echo "[i] PDNS running: $me"

# if localhost then start mysqld
if [ "$MYSQL_HOST" = "127.0.0.1" ]; then
  mysqld_safe >/dev/null &
  MYSQL_PASSWORD=`cat "/var/lib/mysql/passwd.${MYSQL_USER}"`
else
  # do not run local mysql if not using 127.0.0.1
  rm -f /etc/service/mysqld
fi

# Set MySQL Credentials in pdns.conf
if $MYSQL_AUTOCONF ; then
  sed -r -i "s/^[# ]*gmysql-host=.*/gmysql-host=${MYSQL_HOST}/g" /etc/pdns/pdns.conf
  sed -r -i "s/^[# ]*gmysql-port=.*/gmysql-port=${MYSQL_PORT}/g" /etc/pdns/pdns.conf
  sed -r -i "s/^[# ]*gmysql-user=.*/gmysql-user=${MYSQL_USER}/g" /etc/pdns/pdns.conf
  sed -r -i "s/^[# ]*gmysql-password=.*/gmysql-password=${MYSQL_PASSWORD}/g" /etc/pdns/pdns.conf
  sed -r -i "s/^[# ]*gmysql-dbname=.*/gmysql-dbname=${MYSQL_DATABASE}/g" /etc/pdns/pdns.conf
fi

MYSQLCMD="mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD -r -N"

# wait for Database come ready
isDBup () {
  echo "SHOW STATUS" | $MYSQLCMD 1>/dev/null
  echo $?
}

RETRY=10
until [ `isDBup` -eq 0 ] || [ $RETRY -le 0 ] ; do
  echo "Waiting for database to come up"
  sleep 5
  RETRY=$(expr $RETRY - 1)
done
if [ $RETRY -le 0 ]; then
  >&2 echo Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT
  exit 1
fi

# init database if necessary
echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;" | $MYSQLCMD
MYSQLCMD="$MYSQLCMD $MYSQL_DATABASE"

if [ "$(echo "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \"$MYSQL_DATABASE\";" | $MYSQLCMD)" -le 1 ]; then
  echo Initializing Database
  cat /etc/pdns/pdns.sql | $MYSQLCMD

  # Configure supermasters if needed
  if [[ -n "$SUPERMASTER_IP" && -n "$SLAVE_DNSNAME" ]] ; then
    echo "TRUNCATE supermasters;" | $MYSQLCMD
    echo "INSERT INTO supermasters (ip, nameserver, account) VALUES ('$SUPERMASTER_IP', '$SLAVE_DNSNAME', 'internal');" | $MYSQLCMD
  fi
fi

echo "[i] PDNS stopping database for runit"

if [ "$MYSQL_HOST" = "127.0.0.1" ]; then
  # finished, stop it for runit
  mysqladmin -uroot shutdown
fi

