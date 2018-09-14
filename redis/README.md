# redis
to load custom module(s): redis-tsdb-module.so

Download your redis conf here: http://download.redis.io/redis-stable/redis.conf

Add to your redis.conf:
```
loadmodule /usr/local/lib/redis-tsdb-module.so
```

Example Docker Compose:
```
  redis:
    image: "niiknow/redis"
    container_name: docker-redis
    command: redis-server /usr/local/etc/redis/redis.conf
    volumes:
      - "./data/redis:/data"
      - "./data/redis.conf:/usr/local/etc/redis/redis.conf"
    ulimits:
      nproc: 65535
      nofile:
        soft: 20000
        hard: 40000
    sysctls:
      net.core.somaxconn: '511'
    labels:
      - "Docker Redis"
    restart: unless-stopped
```
