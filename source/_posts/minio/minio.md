---
title: minio安装
date: 2019-12-13 14:00:00
categories: 
- minio
tags:
- minio
---


摘要：
<!-- more -->

### 分布式Minio有什么好处?

在大数据领域，通常的设计理念都是无中心和分布式。Minio分布式模式可以帮助你搭建一个高可用的对象存储服务，你可以使用这些存储设备，而不用考虑其真实物理位置。

**数据保护**

分布式Minio采用 erasure code（纠删码）来防范多个节点宕机和位衰减bit rot。

分布式Minio至少需要4个节点，使用分布式Minio自动引入了纠删码功能。

**高可用**

单机Minio服务存在单点故障，相反，如果是一个N节点的分布式Minio,只要有N/2节点在线，你的数据就是安全的。不过你需要至少有N/2+1个节点 Quorum 来创建新的对象。

例如，一个8节点的Minio集群，每个节点一块盘，就算4个节点宕机，这个集群仍然是可读的，不过你需要5个节点才能写数据。

**限制**

分布式Minio单租户存在最少4个盘最多16个盘的限制（受限于纠删码）。这种限制确保了Minio的简洁，同时仍拥有伸缩性。如果你需要搭建一个多租户环境，你可以轻松的使用编排工具（Kubernetes）来管理多个Minio实例。

注意，只要遵守分布式Minio的限制，你可以组合不同的节点和每个节点几块盘。比如，你可以使用2个节点，每个节点4块盘，也可以使用4个节点，每个节点两块盘，诸如此类。

**一致性**

Minio在分布式和单机模式下，所有读写操作都严格遵守read-after-write一致性模型。



### 纠删码 (多块硬盘 / 服务)

| 项目           | 参数    |
| -------------- | ------- |
| 最大驱动器数量 | 16      |
| 最小驱动器数量 | 4       |
| 读仲裁         | N / 2   |
| 写仲裁         | N / 2+1 |





## Minio分布式集群搭建

生产环境建议最少4节点

|  节点   |      IP       |       data       |      home      |
| :-----: | :-----------: | :--------------: | :------------: |
| minio01 | 172.28.105.11 | /data/minio_data | /opt/minio/bin |
| minio02 | 172.28.105.12 | /data/minio_data | /opt/minio/bin |
| minio03 | 172.28.105.13 | /data/minio_data | /opt/minio/bin |
| minio04 | 172.28.105.14 | /data/minio_data | /opt/minio/bin |



### 获取Minio

```
wget https://dl.min.io/server/minio/release/linux-amd64/minio
```

### 目录创建

```
mkdir -p /data/minio_data
mkdir -p /etc/minio
mkdir -p /opt/minio/bin
```

### 集群启动文件

创建/opt/minio/bin/run.sh

```shell
#!/bin/bash
export MINIO_ACCESS_KEY=root
export MINIO_SECRET_KEY=12345678

/data/minio/run/minio server --config-dir /etc/minio \
http://172.28.105.11/data/minio_data \
http://172.28.105.12/data/minio_data \
http://172.28.105.13/data/minio_data \
http://172.28.105.14/data/minio_data \
```

- MINIO_ACCESS_KEY：  用户名，长度最小是5个字符
- MINIO_SECRET_KEY：  密码，密码不能设置过于简单，不然minio会启动失败，长度最小是8个字符
- --config-dir：  指定集群配置文件目录

### 创建服务

创建/usr/lib/systemd/system/minio.service

- WorkingDirectory：二进制文件目录
- ExecStart：指定集群启动脚本



```shell
cat > /usr/lib/systemd/system/minio.service <<EOF
[Unit]
Description=Minio service
Documentation=https://docs.minio.io/

[Service]
WorkingDirectory=/opt/minio/
ExecStart=/opt/minio/bin/run.sh

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### 二进制文件

将minio二进制文件上传到/data/minio/run目录

```
cp minio /opt/minio/bin
chmo +x /opt/minio/bin/minio
chmo +x /opt/minio/bin/run.sh
chmod +x /usr/lib/systemd/system/minio.service
```



### 启动集群

```shell
systemctl daemon-reload
systemctl enable minio && systemctl start minio
```





## 通过nginx代理集群

### 配置负载均衡

```shell
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

	upstream minio{
	        server 172.28.105.11:9000;
	        server 172.28.105.12:9000;
	        server 172.28.105.13:9000;
	        server 172.28.105.14:9000;
	}

    server {
        listen 9001;
        server_name 172.28.105.10;
        location / {
                proxy_pass http://minio;
                proxy_set_header Host $http_host;
                client_max_body_size 1000m;
        }
	}

}
```





## mc客户端配置

### 下载

```
wget https://dl.min.io/client/mc/release/linux-amd64/mc
```

### 简单操作

```
mc config host add <ALIAS> <YOUR-S3-ENDPOINT> <YOUR-ACCESS-KEY> <YOUR-SECRET-KEY> [--api API-SIGNATURE]
```



```csharp
mc config host add myminio http://172.28.105.11:9000 6FN56FQD3BBYYFHRV8CV 99HwhtPhIpVph+eyNh5ouRcorCBAvGUiVM3LXtuq

mc ls play                    # 列出所有桶
mc mb myminio/testbucket        # 创建桶
mc cp io.out myminio/testbucket       # 拷贝测试文件
mc ls myminio/testbucket           # 列出目录
mc policy public  myminio/testbucket      # 设置公开权限  [none, download, upload, public]
```