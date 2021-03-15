---
title: centos7安装mysql5.7
date: 2021-03-15 15:57
categories:
- centos7
tags:
- mysql
---


摘要: centos7安装mysql5.7
<!-- more -->

## 获取mysql5.7
```
https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.23-linux-glibc2.12-x86_64.tar.gz
```
连接可能或失效，从官网获取最新下载地址

[官网地址](https://downloads.mysql.com/archives/community/)


## 安装
### 创建mysql用户
```
useradd -M -s /sbin/nologin  mysql
```
### 创建mysql 目录
```
mkdir -p /opt/data/mysql

chown mysql /opt/data/mysql
```

### 配置文件
```
vim /etc/my.cnf
[mysqld]
bind-address=0.0.0.0
port=3306
user=mysql
basedir=/opt/soft/mysql
datadir=/opt/data/mysql
socket=/opt/data/mysql/mysql.sock
log-error=/opt/data/mysql/mysql.err
pid-file=/opt/data/mysql/mysql.pid
#character config
character_set_server=utf8mb4
symbolic-links=0
explicit_defaults_for_timestamp=true
!includedir /etc/my.cnf.d
```


### 初始化
```
cd /opt/soft/mysql
./bin/mysqld --defaults-file=/etc/my.cnf --basedir=/opt/soft/mysql/ --datadir=/opt/data/mysql/ --user=mysql --initialize
```

### 查看密码
```
cat /opt/data/mysql/mysql.err
```

### 启动mysql
```
cp /opt/soft/mysql/support-files/mysql.server /etc/init.d/mysql
service mysql start
```

### 修改密码
```
SET PASSWORD = PASSWORD('123456');
ALTER USER 'root'@'localhost' PASSWORD EXPIRE NEVER;
FLUSH PRIVILEGES; 
```

### 远程登录
```
use mysql                                            #访问mysql库
update user set host = '%' where user = 'root';      #使root能再任何host访问
FLUSH PRIVILEGES;  
```


### 软连接
```
ln -s  /usr/local/mysql/bin/mysql    /usr/bin
```

