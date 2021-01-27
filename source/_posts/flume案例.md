---
title: Flume 案例
date: 2019-12-13 14:00:00
categories: 
- bigdata
tags:
- flume
---

Spool监测配置的目录下新增的文件，并将文件中的数据读取出来。需要注意两点：

- 拷贝到 spool 目录下的文件不可以再打开编辑。
- spool 目录下不可包含相应的子目录。

在 `/opt` 创建 agent 的配置文件 spool.conf。

```
hadoop@907b3dc56edb:/opt$ sudo vi apache-flume-1.6.0-bin/conf/spool.conf
# 添加如下内容
```

```
# Describe the agent
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe/configure the source
a1.sources.r1.type = spooldir
a1.sources.r1.channels = c1
a1.sources.r1.spoolDir = /opt/apache-flume-1.6.0-bin/logs
a1.sources.r1.fileHeader = true

# Describe the sink
a1.sinks.k1.type = logger

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```

启动 Flume 代理。

```
hadoop@907b3dc56edb:/opt/apache-flume-1.6.0-bin$ bin/flume-ng agent -c conf -f conf/spool.conf -n a1 -Dflume.root.logger=INFO,console
```

另外开启一个终端，追加文件到 apache-flume-1.6.0-bin/logs 目录。

```
hadoop@907b3dc56edb:/opt$ echo "Hello World" > apache-flume-1.6.0-bin/logs/spool.log
```

### 案例二之 ExecEXEC 

执行一个给定的命令获得输出的源。

在 `/opt` 创建 agent 的配置文件 exec.conf。

```
hadoop@907b3dc56edb:/opt$ sudo vi apache-flume-1.6.0-bin/conf/exec.conf
# 添加如下内容
```

```
# Describe the agent
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe the source
a1.sources.r1.type = exec
a1.sources.r1.channels = c1
a1.sources.r1.command = tail -F /opt/apache-flume-1.6.0-bin/logs/log_exec_tail

# Describe the sink
a1.sinks.k1.type = logger

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```

启动 Flume 代理。

```
hadoop@907b3dc56edb:/opt/apache-flume-1.6.0-bin$ bin/flume-ng agent -c conf -f conf/exec.conf -n a1 -Dflume.root.logger=INFO,console
```



另外开启一个终端，用脚本输出信息到 /opt/apache-flume-1.6.0-bin/log_exec_tail

```
for i in {1..1000}
do
echo "exec tail$i" >> /opt/apache-flume-1.6.0-bin/logs/log_exec_tail
done
```



### 案例三之 JSONHandler

从远程客户端接收数据。

在 `/opt` 创建 agent 的配置文件 json.conf。

```
hadoop@907b3dc56edb:/opt$ sudo vi apache-flume-1.6.0-bin/conf/json.conf
# 添加如下内容
```

```
# Describe the agent
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe the source
a1.sources.r1.type = org.apache.flume.source.http.HTTPSource
a1.sources.r1.port = 8888
a1.sources.r1.channels = c1


# Describe the sink
a1.sinks.k1.type = logger

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100


# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```

启动 Flume 代理。

```
hadoop@907b3dc56edb:/opt/apache-flume-1.6.0-bin$ bin/flume-ng agent -c conf -f conf/json.conf -n a1 -Dflume.root.logger=INFO,console
```

生成 JSON 格式的POST request。

```
hadoop@907b3dc56edb:/opt/apache-flume-1.6.0-bin$  curl -X POST -d '[{ "headers" :{"a" : "a1","b" : "b1"},"body" : "shiyanlou.org_body"}]' http://localhost:8888
```

### 案例四之 Syslogtcp

接下来，我们将要介绍如何把数据写入HDFS。

在 `/opt` 创建 agent 配置文件 syslogtcp.conf。

```
hadoop@907b3dc56edb:/opt$ sudo vi apache-flume-1.6.0-bin/conf/syslogtcp.conf
# 添加如下内容
```

```
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe/configure the source
a1.sources.r1.type = syslogtcp
a1.sources.r1.port = 4444
a1.sources.r1.host = localhost
a1.sources.r1.channels = c1

# Describe the sink
a1.sinks.k1.type = hdfs
a1.sinks.k1.channel = c1
a1.sinks.k1.hdfs.path = hdfs://localhost:9000/user/hadoop/syslogtcp
a1.sinks.k1.hdfs.filePrefix = Syslog
a1.sinks.k1.hdfs.round = true
a1.sinks.k1.hdfs.roundValue = 10
a1.sinks.k1.hdfs.roundUnit = minute

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```

启动 Flume 代理。

```
hadoop@907b3dc56edb:/opt/apache-flume-1.6.0-bin$ bin/flume-ng agent -c conf -f conf/syslogtcp.conf -n a1 -Dflume.root.logger=INFO,console
```

测试产生 syslog。

```
hadoop@907b3dc56edb:/opt/apache-flume-1.6.0-bin$  echo "hello  flume" | nc localhost 4444
```

再次打开一个 Xfce 终端，检查 hdfs 上是否生成文件。



### 案例五之 File Roll Sink

接下来，我们将要介绍写入稍微复杂的文件数据，把动态生成的时间戳和数据一同写入 HDFS。

在 `/opt` 创建 agent 的配置文件 file_roll.conf。

```
hadoop@907b3dc56edb:/opt$ sudo vi apache-flume-1.6.0-bin/conf/file_roll.conf
# 添加如下内容
```

```
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# Describe/configure the source
a1.sources.r1.type = syslogtcp
a1.sources.r1.port = 5555
a1.sources.r1.host = localhost
a1.sources.r1.channels = c1

# Describe the sinkmior

a1.sinks.k1.type = file_roll
a1.sinks.k1.sink.directory = /opt/apache-flume-1.6.0-bin/logs

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```

启动 Flume 代理。

```
hadoop@907b3dc56edb:/opt/apache-flume-1.6.0-bin$ bin/flume-ng agent -c conf -f conf/file_roll.conf -n a1 -Dflume.root.logger=INFO,console
```

另外开启一个 Xfce 终端中，测试产生 log。

```
hadoop@907b3dc56edb:/opt/apache-flume-1.6.0-bin$ echo "Hello world!"|nc localhost 5555
```

再次打开一个 Xfce 终端，查看 /opt/apache-flume-1.6.0-bin/logs 下是否生成文件，默认每30秒生成一个新文件。