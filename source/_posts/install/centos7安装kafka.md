---
title: centos7安装kafka集群
date: 2021-07-24 15:29
categories:
- centos7
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


操作日志清理脚本
```
#!/usr/bin/env bash
#  @author  Yakir.King
#  @date  2020/8/3 20:14
# 

# 清除多余日志
# 清除规则
## 1、保留个数，kafka默认按照小时保存日志，每小时保存一个，约定保留文件个数，默认72个
## 2、保留时间，默认保存72小时
## 3、保存大小，为避免服务出问题导致频繁刷日志，将 磁盘撑满，每个文件保留大小均不可超过1G，超过1G的文件将被清理。
###   3.1 为保留出问题的现场，所以需要保留第一个超过1G的文件。

# 保留文件个数，默认72
RETAIN_FILES_NUM=72

# 保留文件时间，默认72小时，单位：小时
RETAIN_FILES_TIME=72

# 保存文件大小，默认1G，单位：M
RETAIN_FILE_MB=1024

# 日志保存目录
LOG_DIR=/opt/kafka/kafka_2.12-2.8.0/logs

# 保留个数方法，由于日志按照小时保存，所以使用保留时间方法即可。
function retain_files_num() {
	echo ""
 }
# 保留时间方法
# 传入参数为日志文件前缀，如server.log.2020-08-01-11 传入参数为server
function retain_files_date(){
    for file_name in $* ; do
        FILE_NAME=${file_name}
        # 确认给定时间之前的时间
        DELETE_DATE=`date +%Y-%m-%d-%H -d "${RETAIN_FILES_TIME} hours ago"`
        # 获取所有日志，将日志的时间戳获取
        # 遍历所有日志文件，截取日志文件的时间戳部分，与delete_date对比，小于等于这个时间的，删除。
        for log_file in `ls -1 ${LOG_DIR}/${FILE_NAME}.log.20*`;do
            LOG_FILE_DATE=`ls -1 ${log_file} | awk -F . '{print $(NF)}'`
            if [[ ${LOG_FILE_DATE} < ${DELETE_DATE} ]]; then
                echo "当前日志文件：${log_file}, 保存时间已超过${RETAIN_FILES_TIME}个小时，删除中……"
                rm -f ${LOG_DIR}/${log_file}
            fi
        done
	done
}

# 保存大小方法
# 传入参数为日志文件前缀，如server.log.2020-08-01-11 传入参数为server
function retain_files_size(){
    for file_name in $* ; do
        FILE_NAME=${file_name}
        # 判断出文件大小
        # 判断超过1G的文件个数，超过两个删除新文件（保留旧的文件，事件现场）。
        BIG_FILE_NUM=`ls -lh ${LOG_DIR}/${FILE_NAME}.log.20* | grep -v total | grep G | wc -l `
        if [[ ${BIG_FILE_NUM} > 1 ]];then
            flag=1
            for log_file in `ls -lh ${LOG_DIR}/${FILE_NAME}.log.20* | grep -v total | grep G | awk '{print $(NF)}'` ;do
                if [[ ${flag} -gt 1 ]] ;then
                    echo "当前日志文件：${log_file}, 大小已超过${RETAIN_FILE_MB}M，删除中……"
                    rm -f ${LOG_DIR}/${log_file}
                fi
                ((flag++))
            done
        fi
        if [[ ${BIG_FILE_NUM} == 1 ]];then
            echo "剩余1个超过${RETAIN_FILE_MB}M的文件，请检查文件过大内容，如有问题解决问题后清除。"
        fi
        echo "${LOG_DIR}/${FILE_NAME}.log的保留文件大小正常"
    done
}

# 执行保留时间方法
retain_files_date server controller kafka-authorizer kafka-request log-cleaner state-change
# 执行保留大小方法
retain_files_size server controller kafka-authorizer kafka-request log-cleaner state-change

```

```
1 */1 * * * /bin/bash ${script_home}/oplogs_cleaner.sh >> oplogs_cleaner.log 2>&1
```