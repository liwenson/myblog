---
title: centos7 安装mongodb4.4
date: 2021-07-24 19:13
categories:
- linux
tags:
- mongodb
---
	
	
摘要: centos7 安装mongodb4.4
<!-- more -->


## 下载
```
https://www.mongodb.com/try/download/community
```

## 解压
```
tar xf mongodb-linux-x86_64-rhel70-4.4.7.tgz -C /opt/mongodb/
```

## 创建目录
```
cd /opt/mongodb/mongodb-linux-x86_64-rhel70-4.4.7/bin/
mkdir logs config data
```

## systemc 管理
```
vim /lib/systemd/system/mongodb.service


[Unit] 
   
Description=mongodb  
After=network.target remote-fs.target nss-lookup.target 
   
[Service] 
Type=forking 
ExecStart=/opt/mongodb/mongodb-linux-x86_64-rhel70-4.4.7/bin/mongod --config  /opt/mongodb/mongodb-linux-x86_64-rhel70-4.4.7/config/mongodb.conf
ExecReload=/bin/kill -s HUP $MAINPID 
ExecStop=/opt/mongodb/mongodb-linux-x86_64-rhel70-4.4.7/bin/mongod --shutdown --config  /opt/mongodb/mongodb-linux-x86_64-rhel70-4.4.7/config/mongodb.conf
PrivateTmp=true
     
[Install] 
WantedBy=multi-user.target

```

vim config/mongodb.conf
```
systemLog:
  destination: file
  path: /opt/mongodb/mongodb-linux-x86_64-rhel70-4.4.7/logs/mongod.log
  logAppend: true
	quiet: true
processManagement:
  fork: true
  pidFilePath: "/opt/mongodb/mongodb-linux-x86_64-rhel70-4.4.7/data/mongod.pid"
net:
  port: 27017
  http:
    enabled: true
storage:
  dbPath: "/opt/mongodb/mongodb-linux-x86_64-rhel70-4.4.7/data"
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: zlib
    indexConfig:
      prefixCompression: true
  journal:
    enabled: true
  directoryPerDB: true
security:
  authorization: enabled      # 开启关闭验证
```


```
systemctl daemon-reload
systemctl start mongodb

systemctl enable mongodb
systemctl is-enabled mongodb
```