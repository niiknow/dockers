#!/bin/sh
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
mkdir -p /var/run/mysqld

chown mysql:mysql /var/lib/mysql
chown mysql:mysql /var/log/mysql
chown mysql:mysql /var/run/mysqld

# ensure that /var/run/mysqld (used for socket and lock files) is writable
# regardless of the UID our mysqld instance ends up having at runtime
chmod 777 /var/run/mysqld

mysql_install_db --user=mysql > /dev/null

if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
  MYSQL_ROOT_PASSWORD=`pwgen 16 1`
  echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
fi

MYSQL_DATABASE=${MYSQL_DATABASE:-""}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

/usr/bin/mysqld_safe &

# wait for it to start
echo -n "wait for db to start"

c=1
while [[ $c -le 10 ]]
do
  echo 'SELECT 1' | /usr/bin/mysql &> /dev/null
#    echo "R=$?"
  if [ $? -eq 0 ]; then
    break
  fi
  echo "."
  sleep 1
  let c=c+1
done
echo "C=$c"

if [ $c -eq 11 ]; then
  echo "database failed to start"
  exit 1
fi

# remove some stuff
MYSQL_DATABASE=${MYSQL_DATABASE:-""}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

tfile=`mktemp`
if [ ! -f "$tfile" ]; then
    return 1
fi

cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;
UPDATE user SET password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE user='root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
EOF

if [ "$MYSQL_DATABASE" != "" ]; then
    echo "[i] Creating database: $MYSQL_DATABASE"
    echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

    if [ "$MYSQL_USER" != "" ]; then
      echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
      echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'; FLUSH PRIVILEGES;" >> $tfile
    fi
fi

/usr/bin/mysqld --user=mysql --bootstrap --verbose=0 < $tfile
rm -f $tfile

# finished, stop it for runit
/usr/bin/mysqladmin shutdown -p"$MYSQL_ROOT_PASSWORD" || true

