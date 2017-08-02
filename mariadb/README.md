# mariadb
alpine base MariaDB image run as an runit server.  Currently, alpine highest MariaDB repo is 10.1.x so that is the max this image will support.  It implement your standard MYSQL docker container for running MARIADB as mysqld/server.  

This image was created for the purpose of being use as a base image to app that require MYSQL database.  You should use the official image if you wish to run standalone MYSQL container.

# Environment Variables

When you start the mariadb image, you can adjust the configuration of the MariaDB instance by passing one or more environment variables on the docker run command line. Do note that none of the variables below will have any effect if you start the container with a data directory that already contains a database: any pre-existing database will always be left untouched on container startup.

## MYSQL_ROOT_PASSWORD

This variable is mandatory and specifies the password that will be set for the MariaDB root superuser account.

## MYSQL_DATABASE

This variable is optional and allows you to specify the name of a database to be created on image startup. If a user/password was supplied (see below) then that user will be granted superuser access (corresponding to GRANT ALL) to this database.

## MYSQL_USER, MYSQL_PASSWORD

These variables are optional, used in conjunction to create a new user and to set that user's password. This user will be granted superuser permissions (see above) for the database specified by the MYSQL_DATABASE variable. Both variables are required for a user to be created.

# examples
Self-contained MariaDB + PowerDNS docker https://github.com/niiknow/dockers/blob/master/powerdns/Dockerfile

# MIT
