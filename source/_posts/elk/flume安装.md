---
title: Flume安装
date: 2019-12-13 14:00:00
categories: 
- elk
tags:
- flume
---
### 准备 flume

安装jdk

官方文档

`http://flume.apache.org/FlumeUserGuide.html`

下载地址

```
http://mirrors.tuna.tsinghua.edu.cn/apache/flume/1.8.0/apache-flume-1.8.0-bin.tar.gz

http://mirrors.hust.edu.cn/apache/flume/1.8.0/apache-flume-1.8.0-bin.tar.gz 

http://mirrors.shu.edu.cn/apache/flume/1.8.0/apache-flume-1.8.0-bin.tar.gz 

http://mirrors.tuna.tsinghua.edu.cn/apache/flume/1.8.0/apache-flume-1.8.0-bin.tar.gz 
```

修改hosts

`vim /etc/hots`

```
192.168.1.12 node1
192.168.1.12 node2
192.168.1.12 node3
```



准备目录

```
mkdir -p /data/{aboutyunlog,flume_data/{checkpoint,data,log}}
```



### 安装flume

```
cd /usr/local/
tar xf  apache-flume-1.8.0-bin.tar.gz 
cd  apache-flume-1.8.0-bin
```

### 修改配置文件

```
# set source
a1.sources.source1.type = spooldir
a1.sources.source1.spoolDir=/data/aboutyunlog
a1sources.source1.fileHeader = flase

# set sink
a1.sinks.sink1.channel = channel1
a1.sinks.sink1.type = org.apache.flume.sink.kafka.KafkaSink
a1.sinks.sink1.kafka.topic = aboutyunlog
a1.sinks.sink1.kafka.bootstrap.servers = 192.168.1.12:9091,192.168.1.12:9092,192.168.1.12:9093
a1.sinks.sink1.kafka.flumeBatchSize = 20
a1.sinks.sink1.kafka.producer.acks = 1
a1.sinks.sink1.kafka.producer.linger.ms = 1
a1.sinks.sink1.kafka.producer.compression.type = snappy

# set channel
a1.channels.channel1.type = file
a1.channels.channel1.checkpointDir = /data/flume_data/checkpoint
a1.channels.channel1.dataDirs= /data/flume_data/data

# bind
a1.sources.source1.channels = channel1
a1.sinks.sink1.channel = channel1
```

### 启动 fulme

```
flume-ng agent --conf-file /usr/local/apache-flume-1.8.0-bin/conf/single_agent.conf --name a1 -Dflume.root.logger=INFO,console
```

### 测试

在kafka上创建名为aboutyunlog的topic

```
kafka-topics.sh --zookeeper master:2181,slave1:2181,slave2:2181 --create --topic aboutyunlog --replication-factor 1 --partitions 3
```

启动flume

```
flume-ng agent --conf-file /usr/local/apache-flume-1.8.0-bin/conf/single_agent.conf --name a1 -Dflume.root.logger=INFO,console
```

创建一个kafka的consumer

flume启动其实是启动了产生着，所以这里创建一个消费者。那么这个消费者创建到什么地方。

我这里创建在node1 上。

```
/usr/local/kafka/kafka03/bin/kafka-console-consumer.sh --zookeeper node1:2181 --topic aboutyunlog --from-beginning
```

添加文件到flume source目录

```
echo -e "this is a test file! \nhttp://www.aboutyun.com\n20170710">log.1
mv log.1 /data/aboutyunlog/
```

在node1 上收到

```
this is a test file! 666 
http://www.aboutyun.com
20170710

```



### supervisor 管理flume

```
[program:flume]  
command=/usr/local/apache-flume-1.8.0-bin/bin/flume-ng agent --conf /usr/local/apache-flume-1.8.0-bin/conf --conf-file /usr/local/apache-flume-1.8.0-bin/conf/single_agent.conf  --name a1 -Dflume.root.logger=INFO,console   
directory=/usr/local/apache-flume-1.8.0-bin  
autostart = false
autorestart = false
redirect_stderr=true
stdout_logfile=/data/flume_data/log/flume_dir.log
stdout_logfile_maxbytes=100MB  
stdout_logfile_backups=10  

```

主要参数说明:

```
command：启动程序使用的命令，可以是绝对路径或者相对路径
process_name：一个python字符串表达式，用来表示supervisor进程启动的这个的名称，默认值是%(program_name)s
numprocs：Supervisor启动这个程序的多个实例，如果numprocs>1，则process_name的表达式必须包含%(process_num)s，默认是1
numprocs_start：一个int偏移值，当启动实例的时候用来计算numprocs的值
priority：权重，可以控制程序启动和关闭时的顺序，权重越低：越早启动，越晚关闭。默认值是999
autostart：如果设置为true，当supervisord启动的时候，进程会自动重启。
autorestart：值可以是false、true、unexpected。false：进程不会自动重启，unexpected：当程序退出时的退出码不是exitcodes中定义的时，进程会重启，true：进程会无条件重启当退出的时候。
startsecs：程序启动后等待多长时间后才认为程序启动成功
startretries：supervisord尝试启动一个程序时尝试的次数。默认是3
exitcodes：一个预期的退出返回码，默认是0,2。
stopsignal：当收到stop请求的时候，发送信号给程序，默认是TERM信号，也可以是 HUP, INT, QUIT, KILL, USR1, or USR2。
stopwaitsecs：在操作系统给supervisord发送SIGCHILD信号时等待的时间
stopasgroup：如果设置为true，则会使supervisor发送停止信号到整个进程组
killasgroup：如果设置为true，则在给程序发送SIGKILL信号的时候，会发送到整个进程组，它的子进程也会受到影响。
user：如果supervisord以root运行，则会使用这个设置用户启动子程序
redirect_stderr：如果设置为true，进程则会把标准错误输出到supervisord后台的标准输出文件描述符。
stdout_logfile：把进程的标准输出写入文件中，如果stdout_logfile没有设置或者设置为AUTO，则supervisor会自动选择一个文件位置。
stdout_logfile_maxbytes：标准输出log文件达到多少后自动进行轮转，单位是KB、MB、GB。如果设置为0则表示不限制日志文件大小
stdout_logfile_backups：标准输出日志轮转备份的数量，默认是10，如果设置为0，则不备份
stdout_capture_maxbytes：当进程处于stderr capture mode模式的时候，写入FIFO队列的最大bytes值，单位可以是KB、MB、GB
stdout_events_enabled：如果设置为true，当进程在写它的stderr到文件描述符的时候，PROCESS_LOG_STDERR事件会被触发
stderr_logfile：把进程的错误日志输出一个文件中，除非redirect_stderr参数被设置为true
stderr_logfile_maxbytes：错误log文件达到多少后自动进行轮转，单位是KB、MB、GB。如果设置为0则表示不限制日志文件大小
stderr_logfile_backups：错误日志轮转备份的数量，默认是10，如果设置为0，则不备份
stderr_capture_maxbytes：当进程处于stderr capture mode模式的时候，写入FIFO队列的最大bytes值，单位可以是KB、MB、GB
stderr_events_enabled：如果设置为true，当进程在写它的stderr到文件描述符的时候，PROCESS_LOG_STDERR事件会被触发
environment：一个k/v对的list列表
directory：supervisord在生成子进程的时候会切换到该目录
umask：设置进程的umask
serverurl：是否允许子进程和内部的HTTP服务通讯，如果设置为AUTO，supervisor会自动的构造一个url
```



