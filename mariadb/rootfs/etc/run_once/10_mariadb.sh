#!/bin/sh
me=`basename "$0"`
echo "[i] MySQL running: $me"

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

# random password generator
randpw() {
  tr -dc _A-Za-z0-9 < /dev/urandom | head -c${1:-12};echo;
}

cd /tmp

MYSQL_DATA_DIR=/var/lib/mysql

mkdir -p "$MYSQL_DATA_DIR"
mkdir -p /var/log/mysql
mkdir -p /var/run/mysqld

chown -R mysql:mysql "$MYSQL_DATA_DIR"
chown -R mysql:mysql /var/log/mysql
chown -R mysql:mysql /run/mysqld


# ensure that /var/run/mysqld (used for socket and lock files) is writable
# regardless of the UID our mysqld instance ends up having at runtime
chmod 777 /var/run/mysqld

mysql_install_db --user=mysql --datadir="$MYSQL_DATA_DIR" > /dev/null

: ${MYSQL_ROOT_PASSWORD:=$(randpw)}

echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
cd "$MYSQL_DATA_DIR"
echo "$MYSQL_ROOT_PASSWORD" > passwd.root
chmod 600 "passwd.root"

# wait until mysql is running
mysqld_safe --datadir="$MYSQL_DATA_DIR" >/dev/null &
mysqladmin --silent --wait=30 ping >/dev/null

echo "[i] MySQL initializing database"

# initialize users and remove test database
mysql -uroot -e \
  "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;\
  GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;\
  DROP DATABASE IF EXISTS test ;\
  "

if [ "$MYSQL_USER" ]; then
  : ${MYSQL_PASSWORD:=$(randpw)}

  echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
  mysql -uroot -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;"

  cd "$MYSQL_DATA_DIR"
  echo "$MYSQL_PASSWORD" > "passwd.${MYSQL_USER}"
  chmod 600 "passwd.${MYSQL_USER}"

  # maybe need initialize a new database for the user
  if [ "$MYSQL_DATABASE" ]; then
    mysql -uroot -e "CREATE DATABASE \`$MYSQL_DATABASE\` DEFAULT CHARSET UTF8 COLLATE UTF8_GENERAL_CI ;"
    mysql -uroot -e "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;"
  fi
fi

mysql -uroot -e 'FLUSH PRIVILEGES ;'

echo "[i] MySQL stopping database for runit"
mysqladmin -uroot shutdown
