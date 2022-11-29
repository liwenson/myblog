---
title: centos7安装redis5
date: 2021-01-14 14:29
categories:
- centos7
tags:
- redis
---

摘要: centos7 源码安装redis5
<!-- more -->

## 下载Redis

从[Redis官网](https://redis.io/download)下载后上传CentOS目录`/usr/local`, 当然, 你也可以使用wget命令下载

```bash
wget http://download.redis.io/releases/redis-5.0.3.tar.gz
```

## 安装编译环境

```bash
yum -y install gcc-c++
```

## 安装及配置Redis

### 安装Redis

```bash
# 解压
cd /usr/local
tar -zxvf redis-5.0.8.tar.gz

# 编译Redis
cd redis-5.0.8
make

# 在`/usr/local/`下创建多个文件夹
mkdir -p /usr/local/redis/{etc,data}

# 安装Redis, 将Redis安装在/usr/local/redis目录下
make PREFIX=/usr/local/redis install

# 复制redis.conf配置文件到/usr/local/redis/etc目录下
cp redis.conf /usr/local/redis/etc

# 添加环境变量, 任何目录下都可以使用redis-server、redis-cli等等
vim /etc/profile
# 最后面添加
export PATH=$PATH:/usr/local/redis/bin

```

### 修改配置文件

```txt
# 打开配置文件
cd /usr/local/redis
vim redis.conf

# 修改后台启动, 默认为daemonize no, 修改为daemonize yes
daemonize yes

# 客户端闲置多长时间后断开连接, 默认为0关闭此功能, 修改为300                                      
timeout 300

# 设置密码, 默认被注释, 取消注释修改为自定义密码(我的是123456)
requirepass 123456

# 监听ip, 允许访问的ip, 默认为127.0.0.1, 修改为0.0.0.0(允许所有服务器ip访问)或者注释掉
bind 0.0.0.0

# 指定监听端口, 默认为6379, 此处我保持默认
port 6379

# 修改AOF及RBD存放路径, 默认为./, 修改为/usr/local/redis/data
dir /usr/local/redis/data

# 修改log存放路径, 默认为"", 修改为"/usr/local/redis/data/redis_6379.log"
logfile "/usr/local/redis/data/redis_6379.log"

#save seconds changes  设置RDB的
save 900 1
save 300 10
save 60 10000

# 开启aof持久化
appendonly yes

# 指定文件名
appendfilename "appendonly.aof"

#每秒执行一次
#appendfsync everysec  每秒执行一次持久化(一般选这个,默认值)
#appendfsync always  执行一次写操作就执行一次持久化
#appendfsync no  根据操作系统的不同，环境的不同在一定时间内执行一次持久化

appendfsync everysec

```

## 启动Redis

```bash
# 启动
redis-server /usr/local/redis/etc/redis.conf

# 查看Redis是否启动
ps -ef | grep redis

# CentOS本地查看
redis-cli
# 输入配置密码即可
auth 123456

# 远程则自行使用工具查看
```

### 添加系统服务与开机自启

添加文件
```
# 新建文件
vim /lib/systemd/system/redis.service
```

```
# 添加内容
[Unit]
Description=redis.server
After=network.target

[Service]
Type=forking
PIDFILE=/var/run/redis_6379.pid
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/etc/redis.conf
ExecRepload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target

```

```bash
systemctl daemon-reload

# 启动redis服务
systemctl start redis.service

# 停止redis服务
systemctl stop redis.service

# 重启redis服务
systemctl restart redis.service

# 查看redis服务当前状态
systemctl status redis.service

# 设置redis服务开机自启动
systemctl enable redis.service

# 停止redis服务开机自启动
systemctl disable redis.service
```

