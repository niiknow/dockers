# powerdns
alpine based, self-contained powerdns master or slave server.

- [x] self-contained powerdns with mysql backend
- [x] able to run as master/primary or slave/secondary server
- [x] mysql and pdns data persistence

## Configuration

**Environment Configuration:**

* MySQL connection settings
  * `MYSQL_HOST=127.0.0.1`
  * `MYSQL_DB=powerdns_db`
  * `MYSQL_USER=powerdns_dbuser`
  * `MYSQL_PASSWORD=`
* Want to disable mysql initialization? Use `MYSQL_AUTOCONF=false`
* Want to use own config and data persistence? Image expose volumes: `/etc/mysql, /var/lib/mysql, /var/log/mysql, /etc/pdns`
* Slave settings
  * `SUPERMASTER_IP=123.123.123.123`
  * `SLAVE_DNSNAME=ns2.example.com`
* Want API access? Update configuration to use exposed port: 80 or 8001
* Additionally, expose port 3306 to allow external Apps access to internal database.  The passwords are saved under: /var/lib/mysql/{root.passwd,powerdns_dbuser.passwd} 

# reference
This image is made possible base on the example of [psitrax/powerdns](https://github.com/psi-4ward/docker-powerdns)

# MIT
