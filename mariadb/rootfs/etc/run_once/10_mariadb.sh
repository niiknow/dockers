#!/bin/sh
me=`basename "$0"`
echo "[i] running: $me"

if [[ -z "$MYSQL_DATABASE" ]]; then
  echo "[i] MYSQL_DATABASE is required, skipping creation"
  exit 0
fi

if [ -d /var/lib/mysql/mysql ]; then
  echo "[i] MySQL directory already present, skipping creation"
  exit 0
fi

# all validation succeed
echo "[i] MySQL data directory not found, creating initial DBs"

cd /tmp

mkdir -p /var/lib/mysql
mkdir -p /var/log/mysql
mkdir -p /run/mysqld

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/log/mysql
chown -R mysql:mysql /run/mysqld

# ensure that /var/run/mysqld (used for socket and lock files) is writable
# regardless of the UID our mysqld instance ends up having at runtime
chmod 777 /var/run/mysqld

mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
  MYSQL_ROOT_PASSWORD=`pwgen 16 1`
  echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
  echo $MYSQL_ROOT_PASSWORD > /var/lib/mysql/.root_password
  chmod 600 /var/lib/mysql/.root_password
fi

MYSQL_DATABASE=${MYSQL_DATABASE:-""}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

tfile=`mktemp`
if [ ! -f "$tfile" ]; then
  return 1
fi

cat << EOF > $tfile
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE user='root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
FLUSH PRIVILEGES;
EOF

if [ "$MYSQL_DATABASE" != "" ]; then
  echo "[i] Creating database: $MYSQL_DATABASE"
  echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

  if [ "$MYSQL_USER" != "" ]; then
    echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
    echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'; \nFLUSH PRIVILEGES;" >> $tfile
  fi
fi

echo "[i] initializing database"
/usr/bin/mysqld --user=mysql --init-file=$tfile >/dev/null 2>&1 &

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/log/mysql
chown -R mysql:mysql /run/mysqld

echo "[i] stopping database for runit"
# finished, stop it for runit
pkill mysqld || true

rm -f $tfile
