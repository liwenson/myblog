---
title: minio分布式部署
date: 2021-03-21 16:39
categories:
- minio
tags:
- minio
---
  
  
摘要: minio分布式部署(非docker方式)
<!-- more -->


## 一、Minio分布式集群搭建（多机器多硬盘）
### 1、环境说明
4台服务器


|节点|	数据目录(不能是/root下的)| 进程/脚本目录 |
|---|---|---|
|10.34.252.87 |	/home/minio/{data1.data2} |	/home/minio/{run}|
|10.34.252.88 |	/home/minio/{data1.data2} |	/home/minio/{run}|
|10.34.252.89 |	/home/minio/{data1.data2} |	/home/minio/{run}|
|10.34.252.93 |	/home/minio/{data1.data2} |	/home/minio/{run}|



### 2、创建目录(4台集群主机都执行)
mkdir -p /home/minio/{run,data1,data2} && mkdir -p /etc/minio


### 3、从官网获取Minio二进制文件并上传至4台集群主机

下载二进制文件：
```
wget https://dl.min.io/server/minio/release/linux-amd64/minio
```

上传Minio到4台集群主机进程脚本目录 /home/minio/run
```
scp,ftp等方式
```

### 4、集群启动文件配置(4台集群主机都执行)
>Minio默认9000端口，在配置文件中加入–address "127.0.0.1:9029" 可更改端口
注意:
MINIO_ACCESS_KEY：用户名，长度最小是5个字符
MINIO_SECRET_KEY：密码，密码不能设置过于简单，不然minio会启动失败，长度最小是8个字符
–config-dir：指定集群配置文件目录

```
vim /home/minio/run/minio-run.sh
```

集群节点10.34.252.87内容为:
```
#!/bin/bash
export MINIO_ACCESS_KEY=admin
export MINIO_SECRET_KEY=admin123
/home/minio/run/minio server --config-dir /etc/minio \
--address "10.34.252.87:9000" \
http://10.34.252.87/home/minio/data1 http://10.34.252.87/home/minio/data2 \
http://10.34.252.88/home/minio/data1 http://10.34.252.88/home/minio/data2 \
http://10.34.252.89/home/minio/data1 http://10.34.252.89/home/minio/data2 \
http://10.34.252.93/home/minio/data1 http://10.34.252.93/home/minio/data2
```

集群节点10.34.252.88内容为:
```
#!/bin/bash
export MINIO_ACCESS_KEY=admin
export MINIO_SECRET_KEY=admin123
/home/minio/run/minio server --config-dir /etc/minio \
--address "10.34.252.88:9000" \
http://10.34.252.87/home/minio/data1 http://10.34.252.87/home/minio/data2 \
http://10.34.252.88/home/minio/data1 http://10.34.252.88/home/minio/data2 \
http://10.34.252.89/home/minio/data1 http://10.34.252.89/home/minio/data2 \
http://10.34.252.93/home/minio/data1 http://10.34.252.93/home/minio/data2
```

集群节点10.34.252.89内容为:
```
#!/bin/bash
export MINIO_ACCESS_KEY=admin
export MINIO_SECRET_KEY=admin123
/home/minio/run/minio server --config-dir /etc/minio \
--address "10.34.252.89:9000" \
http://10.34.252.87/home/minio/data1 http://10.34.252.87/home/minio/data2 \
http://10.34.252.88/home/minio/data1 http://10.34.252.88/home/minio/data2 \
http://10.34.252.89/home/minio/data1 http://10.34.252.89/home/minio/data2 \
http://10.34.252.93/home/minio/data1 http://10.34.252.93/home/minio/data2
```

集群节点10.34.252.93内容为:
```
#!/bin/bash
export MINIO_ACCESS_KEY=admin
export MINIO_SECRET_KEY=admin123
/home/minio/run/minio server --config-dir /etc/minio \
--address "10.34.252.93:9000" \
http://10.34.252.87/home/minio/data1 http://10.34.252.87/home/minio/data2 \
http://10.34.252.88/home/minio/data1 http://10.34.252.88/home/minio/data2 \
http://10.34.252.89/home/minio/data1 http://10.34.252.89/home/minio/data2 \
http://10.34.252.93/home/minio/data1 http://10.34.252.93/home/minio/data2
```


### 创建Minio.server,将minio加入系统服务（4台集群主机都执行）

```
vim /usr/lib/systemd/system/minio.service
```
```
[Unit]
Description=Minio service
Documentation=https://docs.minio.io/

[Service]
WorkingDirectory=/home/minio/run/
ExecStart=/home/minio/run/minio-run.sh

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 权限修改（4台集群主机都执行）
```
chmod +x /usr/lib/systemd/system/minio.service && chmod +x /home/minio/run/minio && chmod +x /home/minio/run/minio-run.sh
```

### 启动集群（4台集群主机都执行）
```
systemctl daemon-reload
systemctl start minio
systemctl enable minio
```

### 查看集群状态
```
systemctl status minio.service -l
```

日志类似以下内容，则启动成功:

```
[root@cn-gri-gicar-bdms-05 csz]# systemctl status minio.service -l
● minio.service - Minio service
   Loaded: loaded (/usr/lib/systemd/system/minio.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2021-01-22 10:44:29 CST; 43min ago
     Docs: https://docs.minio.io/
 Main PID: 3663052 (minio-run.sh)
    Tasks: 41
   Memory: 89.2M
   CGroup: /system.slice/minio.service
           ├─3663052 /bin/bash /root/docker/minio/run/minio-run.sh
           └─3663053 /root/docker/minio/run/minio server --config-dir /etc/minio --address 10.34.252.87:9000 http://10.34.252.87/home/minio/data1 http://10.34.252.87/home/minio/data2 http://10.34.252.88/home/minio/data1 http://10.34.252.88/home/minio/data2 http://10.34.252.89/home/minio/data1 http://10.34.252.89/home/minio/data2 http://10.34.252.93/home/minio/data1 http://10.34.252.93/home/minio/data2

Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: Endpoint: http://10.34.252.87:9000
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: Browser Access:
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: http://10.34.252.87:9000
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: Object API (Amazon S3 compatible):
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: Go:         https://docs.min.io/docs/golang-client-quickstart-guide
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: Java:       https://docs.min.io/docs/java-client-quickstart-guide
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: Python:     https://docs.min.io/docs/python-client-quickstart-guide
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: JavaScript: https://docs.min.io/docs/javascript-client-quickstart-guide
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: .NET:       https://docs.min.io/docs/dotnet-client-quickstart-guide
Jan 22 10:44:32 cn-gri-gicar-bdms-05 minio-run.sh[3663052]: Waiting for all MinIO IAM sub-system to be initialized.. lock acquired
```


### 登录页面测试
登录任一页面

### 测试

创建 bucket 并上传两个文件，在到4台集群主机查看存储情况
