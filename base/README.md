# base
alpine base docker image that support runit.  It allow for building a docker image that contain everything for your App.

# features
- [x] runit for keeping your service alive
- [x] cron for running scheduled tasks.  You can access container environment variables with: source /etc/envvars 
- [x] syslog for logging
- [x] run_once and run_always in alphanumeric order

# reference
Special thanks to the minis [docker-alpine-micro](https://github.com/nimmis/docker-alpine-micro) project.

# examples
Self-contained MariaDB + PowerDNS docker https://github.com/niiknow/dockers/blob/master/powerdns/Dockerfile

# MIT
