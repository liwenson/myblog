---
title: kafka 安装
date: 2019-12-13 14:00:00
categories: 
- bigdata
tags:
- kafka
---
## 环境准备

- 安装 jdk
- 安装 Zookeeper
- kafaka安装包 http://kafka.apache.org/downloads.html

### 修改host 文件

`vim /etc/hots`

```
192.168.1.12 node1
192.168.1.12 node2
192.168.1.12 node3
```

### 下载安装包

```
wget "http://mirrors.shu.edu.cn/apache/kafka/1.1.0/kafka_2.12-1.1.0.tgz"
tar -xzvf kafka_2.11-1.1.0.tgz
mv kafka_2.11-1.1.0 /mnt/
```
### 配置环境变量

将 `kafka_2.11-1.1.0/bin` 添加到`path`，以方便访问
```
vi /etc/profile
```
在末尾添加：
```
KAFKA_HOME=/mnt/kafka_2.11-1.1.0
PATH=$PATH:$KAFKA_HOME/bin
```

<hr>

## 单机模式

### 启动单机模式

### 修改配置文件
```
cd /mnt/kafka_2.11-1.1.0/config
vi server.properties
```
修改配置文件中的以下内容：
```
broker.id=1  
port=9091
host.name=192.168.1.12
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/mnt/kafka/kafka01/
num.partitions=1
num.recovery.threads.per.data.dir=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=false
zookeeper.connect=192.168.1.12:2181,192.168.1.12:2182,192.168.1.12:2183
zookeeper.connection.timeout.ms=6000
```
### 启动程序
先要确保zookeeper已启动，然后在Kafka目录执行
```
nohup bin/kafka-server-start.sh config/server.properties &
```
如果无报错则说明启动成功。nohup &  是实现在后台启动。

### 简单测试
打开2个终端，分别在Kafka目录执行以下命令 
启动producer
```
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test
```
### 启动consumer
```
bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic test --from-beginning
```
在producer的命令行输入任意字符，观察consumer是否能正确接收。

## 常见错误
###  启动Kafka时出现
```
Java HotSpot(TM) Server VM warning: INFO: os::commit_memory(0x67e00000, 1073741824, 0) failed; error='Cannot allocate memory' (errno=12)
#
# There is insufficient memory for the Java Runtime Environment to continue.
# Native memory allocation (mmap) failed to map 1073741824 bytes for committing reserved memory.
# An error report file with more information is saved as:
# /opt/kafka_2.11-0.9.0.1/hs_err_pid2249.log
```
### 错误原因： 
Kafka默认使用 `-Xmx1G -Xms1G` 的JVM内存配置，如果机器内存较小，需要调整启动配置。 
打开 `/config/kafka-server-start.sh` ，修改 
```
export KAFKA_HEAP_OPTS="-Xmx1G -Xms1G" 
```
为适合当前服务器的配置，例如
```
export KAFKA_HEAP_OPTS="-Xmx256M -Xms128M"
```



## 集群模式

### 配置hosts

### 准备缓存目录

````
mkdir -p /mnt/kafka/kafka0{1,2,3}
````

### 安装软件

```
ls /usr/local/kafka/
kafka01  kafka02  kafka03
```

### 修改kafka01 配置文件

```
vim /usr/local/kafka/kafka01/conf/server.properties

broker.id=1
port=9091
host.name=192.168.1.12
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/mnt/kafka/kafka01/
num.partitions=1
num.recovery.threads.per.data.dir=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=false
zookeeper.connect=192.168.1.12:2181,192.168.1.12:2182,192.168.1.12:2183
zookeeper.connection.timeout.ms=6000

```

### 修改kafka02 配置文件

```
vim /usr/local/kafka/kafka01/conf/server.properties

broker.id=2
port=9092
host.name=192.168.1.12
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/mnt/kafka/kafka02/
num.partitions=1
num.recovery.threads.per.data.dir=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=false
zookeeper.connect=192.168.1.12:2181,192.168.1.12:2182,192.168.1.12:2183
zookeeper.connection.timeout.ms=6000

```



### 修改kafka03 配置文件

```
vim /usr/local/kafka/kafka03/conf/server.properties

broker.id=3
port=9093
host.name=192.168.1.12
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/mnt/kafka/kafka03/
num.partitions=1
num.recovery.threads.per.data.dir=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=false
zookeeper.connect=192.168.1.12:2181,192.168.1.12:2182,192.168.1.12:2183
zookeeper.connection.timeout.ms=6000

```



### 启动kafka

先要确保zookeeper已启动，然后在启动Kafka

```
nohup /usr/local/kafka/kafka01/bin/kafka-server-start.sh /usr/local/kafka/kafka01/config/server.properties > /var/log/kafka01.out 2>&1 &
nohup /usr/local/kafka/kafka02/bin/kafka-server-start.sh /usr/local/kafka/kafka02/config/server.properties > /var/log/kafka02.out 2>&1 &
nohup /usr/local/kafka/kafka03/bin/kafka-server-start.sh /usr/local/kafka/kafka03/config/server.properties > /var/log/kafka03.out 2>&1 &
```

查看kafka进程

```
jps

14343 Kafka
14345 Kafka
16941 Jps
14350 Kafka
```



### 测试

#### 创建 topic,3个分片，3个副本

```
/usr/local/kafka/kafka03/bin/kafka-topics.sh –create –zookeeper localhost:2181 –replication-factor 3 –partitions 3 –topic test_topic
```

#### 启动一个生产者

```
/usr/local/kafka/kafka03/bin/kafka-console-producer.sh –broker-list node1:9091,node2:9092,node3:9093 –topic test_topic 
```

#### 启动一个消费者

```
/usr/local/kafka/kafka03/bin/kafka-console-consumer.sh –zookeeper localhost:2181 –topic test_topic 
```

####zookeeper查看topic

```
bin/zkCli.sh -server 192.168.1.12:2182

[zk: 192.168.1.12:2182(CONNECTED) 2] get /brokers/topics/test_topic
{"version":1,"partitions":{"2":[3,1,2],"1":[2,3,1],"0":[1,2,3]}}
```

### 配置文件说明

```
broker.id=1  #当前机器在集群中的唯一标识，和zookeeper的myid性质一样,

每一个broker在集群中的唯一表示，要求是正数。当该服务器的IP地址发生改变时，broker.id没有变化，则不会影响consumers的消息情况

port=9092  #当前kafka对外提供服务的端口默认是9092

host.name=192.168.1.172 #broker的主机地址，若是设置了，那么会绑定到这个地址上，若是没有，会绑定到所有的接口上，并将其中之一发送到ZK，一般不设置

num.network.threads=3 #broker处理消息的最大线程数，一般情况下数量为cpu核数

num.io.threads=8 #broker处理磁盘IO的线程数，数值为cpu核数2倍

socket.send.buffer.bytes=102400 #发送缓冲区buffer大小，数据不是一下子就发送的，先回存储到缓冲区了到达一定的大小后在发送，能提高性能

socket.receive.buffer.bytes=102400 #kafka接收缓冲区大小，当数据到达一定大小后在序列化到磁盘

socket.request.max.bytes=104857600 #这个参数是向kafka请求消息或者向kafka发送消息的请请求的最大数，这个值不能超过java的堆栈大小

log.dirs=/tmp/kafka-logs_1      #kafka数据的存放地址，多个地址的话用逗号分割,多个目录分布在不同磁盘上可以提高读写性能  /data/kafka-logs-1，/data/kafka-logs-2

num.partitions=3 #每个topic的分区个数，若是在topic创建时候没有指定的话会被topic创建时的指定参数覆盖

num.recovery.threads.per.data.dir=1 #用于在启动时,用于日志恢复的线程个数,默认是1.

log.retention.hours=168 #默认消息的最大持久化时间，168小时，7天

log.segment.bytes=1073741824    #topic的分区是以一堆segment文件存储的，这个控制每个segment的大小，会被topic创建时的指定参数覆盖

log.retention.check.interval.ms=300000 #每隔300000毫秒去检查上面配置的log失效时间（log.retention.hours=168 ），到目录查看是否有过期的消息如果有，删除

zookeeper.connect=localhost:2181,localhost:2182,localhost:2183

zookeeper.connection.timeout.ms=6000 #ZooKeeper的连接超时时间

```

### supervisor管理kafka

`vim bin/kafka-run-class.sh`   在最上面增加环境路径

```
JAVA_HOME=/usr/local/java
export JAVA_HOME
```

`vim /etc/supervisor/kafka.conf`

```
[program:kafka]
command=/usr/local/kafka/kafka01/bin/kafka-server-start.sh /usr/local/kafka/kafka01/config/server.properties
user=root
autostart=true
autorestart=true
startsecs=10
stdout_logfile=/var/log/kafka.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=10
stdout_capture_maxbytes=1MB
stderr_logfile=/var/log/kafka.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=10
stderr_capture_maxbytes=1MB
```