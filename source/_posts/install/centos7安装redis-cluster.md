---
title: centos7安装redis集群
date: 2021-07-29 09:22
categories:
- centos7
tags:
- redis
- redis-cluster
---
	
	
摘要: centos7 安装redis集群
<!-- more -->


## 主机
|主机|端口|
|---|---|
|10.200.75.193|6379|
|10.200.75.193|6380|
|10.200.75.194|6379|
|10.200.75.194|6380|
|10.200.75.195|6379|
|10.200.75.195|6380|



## 目录创建
```
mkdir -p /opt/{redis,soft}
```
## 编译安装
```
make
make install PREFIX=/usr/local/redis
```


## redis解压
```
cd /opt/soft

tar xvf redis-4.0.10.tar.gz -C /opt/redis/
mv redis-4.0.10  redis-6379
cp -rf redis-6379 redis-6380
```

## 目录创建
```
mkdir redis-6379/{conf,data,logs}
mkdir redis-6380/{conf,data,logs}
```

## 配置文件
```
vim  redis-6379/conf/redis.conf

# 允许访问地址
bind 0.0.0.0
# 关闭保护模式
protected-mode no
# 端口
port 6379
# 设置tcp的backlog
tcp-backlog 511
# 当客户端闲置多长时间后关闭连接，如果指定为0，表示永不关闭：
timeout 0
# 设置检测客户端网络中断时间间隔，单位为秒，如果设置为0，则不检测，建议设置为60：
tcp-keepalive 0
# 后台运行
daemonize yes
supervised no
# 后台运行时，redis默认会把pid写入/var/run/redis.pid文件
pidfile /var/run/redis_6379.pid
# 指定日志记录级别，redis总共支持四个级别：debug、verbose、notice、warning
loglevel notice
# 日志输出路径
logfile "/opt/redis/redis-6379/logs/redis.log"
# 设置数据库数量，默认值为16，默认当前数据库为0
databases 16
# 指定在多长时间内，有多少次更新操作，就将数据同步到数据文件，可以多个条件配合
save 900 1
save 300 10
save 60 10000
# 
stop-writes-on-bgsave-error yes
# 指定存储至本地数据库时是否压缩数据，默认为yes，redis采用LZF压缩，如果为了节省CPU时间，可以关闭该选项，但会导致数据库文件变得巨大
rdbcompression yes
rdbchecksum yes
# 指定本地数据库文件名
dbfilename dump.rdb
# 配置数据目录  
dir /opt/redis/redis-6379/data
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
# 默认redis使用的是rdb方式持久化，这种方式在许多应用中已经足够用了，
# 但是redis如果中途宕机，会导致可能有几分钟的数据丢失，
# 根据save来策略进行持久化，Append Only File是另一种持久化方式，可以提供更好的持久化特性，
# Redis会把每次写入的数据在接收后都写入 appendonly.aof 文件，
# 每次启动时Redis都会先把这个文件的数据读入内存里，先忽略RDB文件。
appendonly yes
# 指定更新日志文件名
appendfilename "appendonly.aof"
# 指定更新日志条件，共有3个可选值：
# no：表示等操作系统进行数据缓存同步到磁盘（快）；
# always：表示每次更新操作后手动调用fsync()将数据写到磁盘（慢，安全）；
# everysec：表示每秒同步一次（折中，默认值）
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
# 是否开启集群
cluster-enabled yes
# 集群配置文件的名称，每个节点都有一个集群相关的配置文件，持久化保存集群的信息，
# 这个文件并不需要手动配置，这个配置文件有Redis生成并更新，
# 每个Redis集群节点需要一个单独的配置文件，请确保与实例运行的系统中配置文件名称不冲突。
cluster-config-file master-01.conf
# 节点互连超时的阀值。集群节点超时毫秒数
cluster-node-timeout 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes

```


```
vim  redis-6380/conf/redis.conf

# 允许访问地址
bind 0.0.0.0
# 关闭保护模式
protected-mode no
# 端口
port 6380
# 设置tcp的backlog
tcp-backlog 511
# 当客户端闲置多长时间后关闭连接，如果指定为0，表示永不关闭：
timeout 0
# 设置检测客户端网络中断时间间隔，单位为秒，如果设置为0，则不检测，建议设置为60：
tcp-keepalive 0
# 后台运行
daemonize yes
supervised no
# 后台运行时，redis默认会把pid写入/var/run/redis.pid文件
pidfile /var/run/redis_6380.pid
# 指定日志记录级别，redis总共支持四个级别：debug、verbose、notice、warning
loglevel notice
# 日志输出路径
logfile "/opt/redis/redis-6380/logs/redis.log"
# 设置数据库数量，默认值为16，默认当前数据库为0
databases 16
# 指定在多长时间内，有多少次更新操作，就将数据同步到数据文件，可以多个条件配合
save 900 1
save 300 10
save 60 10000
# 
stop-writes-on-bgsave-error yes
# 指定存储至本地数据库时是否压缩数据，默认为yes，redis采用LZF压缩，如果为了节省CPU时间，可以关闭该选项，但会导致数据库文件变得巨大
rdbcompression yes
rdbchecksum yes
# 指定本地数据库文件名
dbfilename dump.rdb
# 配置数据目录  
dir /opt/redis/redis-6380/data
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
# 默认redis使用的是rdb方式持久化，这种方式在许多应用中已经足够用了，
# 但是redis如果中途宕机，会导致可能有几分钟的数据丢失，
# 根据save来策略进行持久化，Append Only File是另一种持久化方式，可以提供更好的持久化特性，
# Redis会把每次写入的数据在接收后都写入 appendonly.aof 文件，
# 每次启动时Redis都会先把这个文件的数据读入内存里，先忽略RDB文件。
appendonly yes
# 指定更新日志文件名
appendfilename "appendonly.aof"
# 指定更新日志条件，共有3个可选值：
# no：表示等操作系统进行数据缓存同步到磁盘（快）；
# always：表示每次更新操作后手动调用fsync()将数据写到磁盘（慢，安全）；
# everysec：表示每秒同步一次（折中，默认值）
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
# 是否开启集群
cluster-enabled yes
# 集群配置文件的名称，每个节点都有一个集群相关的配置文件，持久化保存集群的信息，
# 这个文件并不需要手动配置，这个配置文件有Redis生成并更新，
# 每个Redis集群节点需要一个单独的配置文件，请确保与实例运行的系统中配置文件名称不冲突。
cluster-config-file slave-01.conf   ##  修改此处
# 节点互连超时的阀值。集群节点超时毫秒数
cluster-node-timeout 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes

```


## systemctl管理
```
vim /lib/systemd/system/redis-6379.service

[Unit]
Description=redis.server
After=network.target

[Service]
Type=forking
PIDFILE=/var/run/redis_6379.pid
ExecStart=/opt/redis/redis-6379/bin/redis-server /opt/redis/redis-6379/conf/redis.conf
ExecRepload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
```

```
vim /lib/systemd/system/redis-6380.service


[Unit]
Description=redis.server
After=network.target

[Service]
Type=forking
PIDFILE=/var/run/redis_6380.pid
ExecStart=/opt/redis/redis-6380/bin/redis-server /opt/redis/redis-6380/conf/redis.conf
ExecRepload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target

```

## systemctl管理
```
systemctl daemon-reload

# 启动redis服务
systemctl start redis-6379.service
systemctl start redis-6380.service

# 停止redis服务
systemctl stop redis-6379.service
systemctl stop redis-6380.service

# 重启redis服务
systemctl restart redis-6379.service
systemctl restart redis-6380.service

# 查看redis服务当前状态
systemctl status redis-6379.service
systemctl status redis-6380.service

# 设置redis服务开机自启动
systemctl enable redis-6379.service
systemctl enable redis-6380.service

# 停止redis服务开机自启动
systemctl disable redis.service
```

## 加入集群
```
/opt/redis/redis-6379/src/redis-trib.rb create --replicas 1 10.200.75.193:6379 10.200.75.193:6380 10.200.75.194:6379 10.200.75.194:6380 10.200.75.195:6379 10.200.75.195:6380
```

## redis-cluster集群关系
```
./redis-cli -h 10.200.75.193 -p 6379 -c cluster nodes

./redis-cli -h 10.200.75.193 -p 6379 -c cluster slots | xargs -n8 | awk '{print $3":"$4"->"$6":"$7}' | sort -nk2 -t ':' | uniq

10.200.75.193:6379->10.200.75.194:6380
10.200.75.194:6379->10.200.75.195:6380
10.200.75.195:6379->10.200.75.193:6380

```