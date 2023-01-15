---
title: centos7安装nacos 2.x
date: 2022-11-29 10:16
categories:
- centos7
tags:
- nacos
---
  
  
摘要: centos7安装nacos 2.x
<!-- more -->

## 前言

Nacos2.0 版本相比1.X新增了gRPC的通信方式，因此需要增加2个端口。新增端口是在配置的主端口(server.port)基础上，进行一定偏移量自动生成。

生成方式

grpc的端口      = nacos主端口 + 1000
nacos的主端口为  = 9848 - 1000 = 8848

是由主端口+1000、主端口+1001生成。

|端口 | 与主端口的偏移量 | 描述|
|---|---|---|
|8848 | 0 | Nacos程序主配置端口|
|9848 | Nacos程序主配置端口 +1000 | 客户端gRPC请求服务端端口，用于客户端向服务端发起连接和请求|
|9849 | Nacos程序主配置端口 +1001 | 服务端gRPC请求服务端端口，用于服务间同步等|
|7848 | Nacos程序主配置端口 -1000 | Nacos 集群通信端口，用于Nacos 集群间进行选举，检测等|


## 下载安装

可以从github下载最新的release版本：

下载地址：<https://github.com/alibaba/nacos/releases>

github上下载比较慢：<https://ghproxy.com/https://github.com/alibaba/nacos/releases/download/2.1.0/nacos-server-2.1.0.tar.gz>

下载完成之后得到nacos-server-2.1.0.zip，解压之后就可以运行了。

## 配置MySQL数据库

nacos支持使用MySQL数据库，可以使用MySQL数据库代替内嵌的derby数据库。

- 安装MySQL数据库
- 新建一个MySQL数据库账户：nacos/12345678
- 初始化mysql数据库nacos，数据库初始化文件：nacos-mysql.sql
- 配置application.properties

配置文件application.properties中，把MySQL相关配置注释放开，并根据实际情况配置:

```bash
### use MySQL as datasource:
spring.datasource.platform=mysql
### Count of DB:
db.num=1
### Connect URL of DB:
db.url.0=jdbc:mysql://127.0.0.1:3306/nacos?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=UTC
db.user=nacos
db.password=12345678
```

## 单机启动

```bash
cd bin
startup.sh -m standalone
```

## 集群配置

复制 cluster.conf.example 为 cluster.conf，并配置IP和端口。端口为

```txt
10.181.10.242:8851
10.181.10.242:8861
10.181.10.242:8871
```

## 访问

```txt
http://localhost:8848/nacos/#/login
```

默认用户名和密码：nacos/nacos，密码在登录之后可以修改，已经集成了用户相关管理

## 配置成服务

```bash
vim /usr/lib/systemd/system/nacos.service

[Unit]
Description=nacos-server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
Environment="JAVA_HOME=/usr/local/jdk1.8.0_161"  # 不加java的环境变量，脚本会找不到系统中的java环境变量
WorkingDirectory=/opt/nacos               # 工作目录，不加work 目录和access.log 会在 / 下面
ExecStart=/opt/nacos/bin/startup.sh       #这个地址更换为你得安装地址
ExecStop=/opt/nacos/bin/shutdown.sh       #这个地址更换为你得安装地址
Restart=always
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

systemd 管理nacos ，nacos启动脚本会找不到JAVA_HOME,需要修改nacos的启动脚本，指定java路径

```bash

vim bin/startup.sh

[ ! -e "$JAVA_HOME/bin/java" ] && JAVA_HOME=/usr/local/jdk
# [ ! -e "$JAVA_HOME/bin/java" ] && JAVA_HOME=/usr/java
# [ ! -e "$JAVA_HOME/bin/java" ] && JAVA_HOME=/opt/taobao/java
# [ ! -e "$JAVA_HOME/bin/java" ] && unset JAVA_HOME

```

## 重新启动服务

```bash
systemctl restart nacos.service
```

## 查看服务状态

```bash
systemctl status nacos.service
```

## 开启自启动

```bash
systemctl enable nacos.service
```

## Nginx配置负载均衡

Nacos2.0 版本相比1.X 新增了gRPC的通信方式，因此需要增加2个端口。新增端口是在配置的主端口(server.port)基础上，进行一定偏移量自动生成。使用VIP/nginx请求时，需要配置成TCP转发，不能配置http2转发，否则连接会被nginx断开。

|端口 | 与主端口的偏移量 | 描述|
|---|---|---|
|9848 | 1000 | 客户端gRPC请求服务端端口，用于客户端向服务端发起连接和请求|
|9849 | 1001 | 服务端gRPC请求服务端端口，用于服务间同步等|

```nginx

# tcp 代理
stream {

    # 客户端gRPC请求服务端端口，用于客户端向服务端发起连接和请求
    upstream nacosClientGrpc {
        server a:9848;      //  nacos port + 1000
        server b:9848;
        server c:9848;
    }

    server {
        listen 9080;     //  Y + 1000
        proxy_pass nacosClientGrpc;
    }

    # 服务端gRPC请求服务端端口，用于服务间同步等
    upstream nacosServerGrpc {
        server a:9849;      //  nacos port + 1001
        server b:9849;
        server c:9849;
    }

    server {
        listen 9081;     //  Y + 1001
        proxy_pass nacosServerGrpc;
    }
}


# http 代理

http {
    # ignore something here
    #gzip  on;

    upstream nacosClu {
        server a:8848;      //  X = nacos端口，  默认8848
        server b:8848;
        server c:8848;
    }

    server {
        listen       8080;     //  Y = nginx监听端口， 但是端口别跟其他的冲突了
        server_name  nginxIp;

        location / {
            proxy_pass http://nacosClu;
        }
        # ignore something here
   }
}

```

## 注意

nacos 控制台 nginx 配置https ，nacos 会302跳转到http,nginx 需要配置80 跳转443 ，并开启80 访问的防火墙
