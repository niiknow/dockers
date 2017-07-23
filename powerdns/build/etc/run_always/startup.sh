#!/bin/sh

if [ -f /data/mysql.configured ]; then
  exit 0
fi

#
# create all directories if missing
#

mkdir -p /data/log/mysql
mkdir -p /data/db/mysql/
mkdir -p /data/conf
mkdir -p /var/run/mysqld

#
# set correct owner
#

chown -R mysql.mysql /data/log/mysql
chown -R mysql.mysql /data/db/mysql/
chown -R mysql.mysql /var/run/mysqld

#
# check for config-file
#

if [ ! -f /data/conf/my.cnf ]; then
  cp /etc/mysql/my.cnf  /data/conf/my.cnf
  chmod +r /data/conf/my.cnf
fi

# do some compatible variables with mysql

if [ -z "$MARIADB_RANDOM_ROOT_PASSWORD" ]; then
  MARIADB_RANDOM_ROOT_PASSWORD="$MYSQL_RANDOM_ROOT_PASSWORD"
fi

if [ -z "$MARIADB_ROOT_PASSWORD" ]; then
  MARIADB_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD"
fi

if [ -z "$MARIADB_ALLOW_EMPTY_PASSWORD" ]; then
  MARIADB_ALLOW_EMPTY_PASSWORD="$MYSQL_ALLOW_EMPTY_PASSWORD"
fi

if [ -z "$MARIADB_DATABASE" ]; then
  MARIADB_DATABASE="$MYSQL_DATABASE"
fi

if [ -z "$MARIADB_USER" ]; then
  MARIADB_USER="$MYSQL_USER"
fi

if [ -z "$MARIADB_PASSWORD" ]; then
  MARIADB_PASSWORD="$MYSQL_PASSWORD"
fi

if [ -z "$MARIADB_REMOTE_ROOT" ]; then
  MARIADB_REMOTE_ROOT="$MYSQL_REMOTE_ROOT"
fi

# determine root password
unset ROOT_PASSWORD

if [ ! -z "$MARIADB_RANDOM_ROOT_PASSWORD" ]; then
  ROOT_PASSWORD=`date +%s | sha256sum | base64 | head -c 16 ; echo`
  echo "set root to random password $ROOT_PASSWORD"
else
  if [ ! -z "$MARIADB_ROOT_PASSWORD" ]; then
    echo "seting root password to $MARIADB_ROOT_PASSWORD"
    ROOT_PASSWORD="$MARIADB_ROOT_PASSWORD"
  fi
fi

if [ -z "$ROOT_PASSWORD" ]; then
  if [ ! -z "$MARIADB_ALLOW_EMPTY_PASSWORD" ]; then
     echo "WARNING: It is a security risk running a database without a root password"
  else
     echo "ERROR: No root password (-e MARIADB_ROOT_PASSWORD=<pwd>) defined, use -e MARIADB_ALLOW_EMPTY_PASSWORD=yes to allow"
     exit 1
  fi
fi

mkdir -p /data
chown -R mysql.mysql /data

if [ ! -d /data/db/mysql/mysql ]; then
  # initialize database if not found
  /usr/bin/mysql_install_db --datadir=/data/db/mysql/ --user=mysql 2> /dev/null

  # start database for config

  /usr/bin/mysqld_safe --defaults-file=/data/conf/my.cnf --datadir=/data/db/mysql/  &

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

  echo "DROP DATABASE IF EXISTS test;" | /usr/bin/mysql
  echo "DELETE FROM mysql.user WHERE user='';" | /usr/bin/mysql

  if [ ! -z $MARIADB_DATABASE ]; then
     echo "Creating database $MARIADB_DATABASE"
     echo "CREATE DATABASE IF NOT EXISTS $MARIADB_DATABASE ;" | /usr/bin/mysql
  fi

  if [ ! -z $MARIADB_USER ]; then
     echo "Creating user $MARIADB_USER"
     echo "CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD' ;FLUSH PRIVILEGES;" | /usr/bin/mysql
     echo "CREATE USER '$MARIADB_USER'@'localhost' IDENTIFIED BY '$MARIADB_PASSWORD' ;FLUSH PRIVILEGES;" | /usr/bin/mysql
     if [ ! -z $MARIADB_DATABASE ]; then
       echo "Grating access for $MARIADB_USER to $MARIADB_DATABASE"
       echo "GRANT ALL ON $MARIADB_DATABASE.* TO '$MARIADB_USER'@'%' ;FLUSH PRIVILEGES;" | /usr/bin/mysql
       echo "GRANT ALL ON $MARIADB_DATABASE.* TO '$MARIADB_USER'@'localhost' ;FLUSH PRIVILEGES;" | /usr/bin/mysql
     fi
  fi

  if [ ! -z "$MARIADB_REMOTE_ROOT" ]; then
     echo "Grant root access from remote host"
     echo "GRANT ALL ON *.* to 'root'@'%' IDENTIFIED BY '$ROOT_PASSWORD' ;" | /usr/bin/mysql
  fi

  if [ ! -z "$ROOT_PASSWORD" ]; then
     echo "UPDATE mysql.user SET Password=PASSWORD('$ROOT_PASSWORD') WHERE User='root';FLUSH PRIVILEGES;" | /usr/bin/mysql
     echo "root password updated"
  fi

fi

# finished, stop it an runit start the mysqld

/usr/bin/mysqladmin shutdown -p"$ROOT_PASSWORD"

# mark configured

touch /data/mysql.configured


if [ -d /var/lib/mysql/mysql ]; then
  echo "[i] MySQL directory already present, skipping creation"
else
  echo "[i] MySQL data directory not found, creating initial DBs"

  chown -R mysql:mysql /var/lib/mysql

  mysql_install_db --user=mysql > /dev/null

  if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
    MYSQL_ROOT_PASSWORD=`pwgen 16 1`
    echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
  fi

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
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE user='root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
EOF

  if [ "$MYSQL_DATABASE" != "" ]; then
      echo "[i] Creating database: $MYSQL_DATABASE"
      echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

      if [ "$MYSQL_USER" != "" ]; then
        echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
        echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
      fi
  fi

  /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 < $tfile
  rm -f $tfile
fi
