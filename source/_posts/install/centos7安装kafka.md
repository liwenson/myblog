---
title: centos7安装kafka集群
date: 2021-07-24 15:29
categories:
- Linux
tags:
- kafka
---
	
	
摘要: centos7安装kafka集群
<!-- more -->



## 集群模式

10.200.75.180
10.200.75.181
10.200.75.182


### 创建目录
```
mkdir -p /opt/kafka
```

### 下载安装包

```
curl -O https://apache.website-solution.net/kafka/2.8.0/kafka_2.12-2.8.0.tgz
tar xvf kafka_2.12-2.8.0.tgz -C /opt/kafka/

```
### 配置环境变量

将 `kafka_2.12-2.8.0/bin` 添加到`path`，以方便访问
```
vi /etc/profile
```
在末尾添加：
```
KAFKA_HOME=/opt/kafka/kafka_2.12-2.8.0
PATH=$PATH:$KAFKA_HOME/bin
```

### 创建目录
```
mkdir -p /opt/kafka/kafka_2.12-2.8.0/mylog
```

### 修改jvm 配置文件，开启jmx 监控

vim bin/kafka-server-start.sh
```
# 修改29 行
export KAFKA_HEAP_OPTS="-Xmx6G -Xms6G"
export JMX_PORT="9999"
```

### 修改kafka01 配置文件

```
vim /opt/kafka/kafka_2.12-2.8.0/config/server.properties

broker.id=1
port=9091
host.name=10.200.75.180
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/opt/kafka/kafka_2.12-2.8.0/mylog
num.partitions=1
num.recovery.threads.per.data.dir=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=false
zookeeper.connect=10.200.75.177:2180,10.200.75.178:2180,10.200.75.179:2180
zookeeper.connection.timeout.ms=6000

```

### 修改kafka02 配置文件

```
vim /opt/kafka/kafka_2.12-2.8.0/config/server.properties

broker.id=2
port=9091
host.name=10.200.75.181
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/opt/kafka/kafka_2.12-2.8.0/mylog
num.partitions=1
num.recovery.threads.per.data.dir=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=false
zookeeper.connect=10.200.75.177:2180,10.200.75.178:2180,10.200.75.179:2180
zookeeper.connection.timeout.ms=6000

```



### 修改kafka03 配置文件

```
vim /opt/kafka/kafka_2.12-2.8.0/config/server.properties

broker.id=3
port=9091
host.name=10.200.75.182
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/opt/kafka/kafka_2.12-2.8.0/mylog
num.partitions=1
num.recovery.threads.per.data.dir=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=false
zookeeper.connect=10.200.75.177:2180,10.200.75.178:2180,10.200.75.179:2180
zookeeper.connection.timeout.ms=6000

```

## systemctl 管理kafka
```
cat > /usr/lib/systemd/system/kafka.service <<"EOF"
[Unit]
Description=Apache Kafka server
After=network.target  zookeeper.service

[Service]
Type=simple
Environment=JAVA_HOME=/opt/jdk1.8.0_161
User=root
Group=root
ExecStart=/opt/kafka/kafka_2.12-2.8.0/bin/kafka-server-start.sh /opt/kafka/kafka_2.12-2.8.0/config/server.properties
ExecStop=/opt/kafka/kafka_2.12-2.8.0/bin/kafka-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

```
systemctl daemon-reload
systemctl start kafka

systemctl enable kafka
systemctl is-enabled kafka
```


### 定期清理日志
```
cat > /opt/kafka/kafka_2.12-2.8.0/bin/clean_kafka_logs.sh << "EOF"
#!/bin/bash
find /opt/kafka/kafka_2.12-2.8.0/logs/ -type f -mtime +7|xargs rm -rf
EOF

chmod +x /opt/kafka/kafka_2.12-2.8.0/bin/clean_kafka_logs.sh


执行crontab -e，加入一行
0 0 * * * /bin/bash /opt/kafka/kafka_2.12-2.8.0/bin/clean_kafka_logs.sh
```
