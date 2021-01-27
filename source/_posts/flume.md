---
title: Flume配置文件说明
date: 2019-12-13 14:00:00
categories: 
- bigdata
tags:
- flume
---

Flume目录结构

| 文件夹 | 描述                    |
| ------ | ----------------------- |
| bin    | 存放了启动脚本          |
| lib    | 启动所需的所有组件jar包 |
| conf   | 提供了几个测试配置文件  |
| docs   | 文档                    |

### Flume Agent组件

Flume内部有一个或者多个Agent,然而对于每一个Agent来说,它就是一共独立的守护进程(JVM),它从客户端哪儿接收收集,或者从其他的 Agent哪儿接收,然后迅速的将获取的数据传给下一个目的节点sink,或者agent

#### Source

source 负责数据的产生或搜集，一般是对接一些RPC的程序或者是其他的flume节点的sink，从数据发生器接收数据,并将接收的数据以Flume的event格式传递给一个或者多个通道Channel,Flume提供多种数据接收的方式,比如包括avro、thrift、exec、jms、spooling directory、netcat、sequence generator、syslog、http、legacy、自定义

| **类型**           | **描述**                                                  |
| ------------------ | --------------------------------------------------------- |
| Avro               | 监听Avro端口并接收Avro Client的流数据                     |
| Thrift             | 监听Thrift端口并接收Thrift Client的流数据                 |
| Exec               | 基于Unix的command在标准输出上生产数据                     |
| JMS                | 从JMS（Java消息服务）采集数据                             |
| Spooling Directory | 监听指定目录                                              |
| Twitter 1%         | 通过API持续下载Twitter数据（实验阶段）                    |
| Kafka              | 采集Kafka topic中的message                                |
| NetCat             | 监听端口（要求所提供的数据是换行符分隔的文本）            |
| Sequence Generator | 序列产生器，连续不断产生event，用于测试                   |
| Syslog             | 采集syslog日志消息，支持单端口TCP、多端口TCP和UDP日志采集 |
| HTTP               | 接收HTTP POST和GET数据                                    |
| Stress             | 用于source压力测试                                        |
| Legacy             | 向下兼容，接收低版本Flume的数据                           |
| Custom             | 自定义source的接口                                        |
| Scribe             | 从facebook Scribe采集数据                                 |

### channel

Channel 是一种短暂的存储容器,负责数据的存储持久化，可以持久化到jdbc,file,memory，将从source处接收到的event格式的数据缓存起来,直到它们被sinks消费掉,可以把channel看成是一个队列，队列的优点是先进先出，放好后尾部一个个event出来，Flume比较看重数据的传输，因此几乎没有数据的解析预处理。仅仅是数据的产生，封装成event然后传输。数据只有存储在下一个存储位置（可能是最终的存储位置，如HDFS；也可能是下一个Flume节点的channel），数据才会从当前的channel中删除。这个过程是通过事务来控制的，这样就保证了数据的可靠性。

不过flume的持久化也是有容量限制的，比如内存如果超过一定的量，不够分配，也一样会爆掉。

| **类型**                   | **描述**                                                     |
| -------------------------- | ------------------------------------------------------------ |
| Memory                     | Event数据存储在内存中                                        |
| JDBC                       | Event数据存储在持久化存储中，当前Flume Channel内置支持Derby  |
| Kafka                      | Event存储在kafka集群                                         |
| File Channel               | Event数据存储在磁盘文件中                                    |
| Spillable Memory Channel   | Event数据存储在内存中和磁盘上，当内存队列满了，会持久化到磁盘文件（当前试验性的，不建议生产环境使用） |
| Pseudo Transaction Channel | 测试用途                                                     |
| Custom Channel             | 自定义Channel实现                                            |

### sink

sink 负责数据的转发，将数据存储到集中存储器比如Hbase和HDFS,它从channel消费数据(events)并将其传递给目标地。目标地可能是另一个sink,也可能是hdfs、logger、avro、thrift、ipc、file、null、Hbase、solr、自定义等

| **类型**       | **描述**                                            |
| -------------- | --------------------------------------------------- |
| HDFS           | 数据写入HDFS                                        |
| HIVE           | 数据导入到HIVE中                                    |
| Logger         | 数据写入日志文件                                    |
| Avro           | 数据被转换成Avro Event，然后发送到配置的RPC端口上   |
| Thrift         | 数据被转换成Thrift Event，然后发送到配置的RPC端口上 |
| IRC            | 数据在IRC上进行回放                                 |
| File Roll      | 存储数据到本地文件系统                              |
| Null           | 丢弃到所有数据                                      |
| Hive           | 数据写入Hive                                        |
| HBase          | 数据写入HBase数据库                                 |
| Morphline Solr | 数据发送到Solr搜索服务器（集群）                    |
| ElasticSearch  | 数据发送到Elastic Search搜索服务器（集群）          |
| Kite Dataset   | 写数据到Kite Dataset，试验性质的                    |
| Kafka          | 数据写到Kafka Topic                                 |
| Custom         | 自定义Sink实现                                      |

**Flume有哪些优缺点**

####优点

- Flume可以将应用产生的数据存储到任何集中存储器中，比如HDFS,HBase

- 当收集数据的速度超过将写入数据的时候，也就是当收集信息遇到峰值时，这时候收集的信息非常大，甚至超过了系统的写入数据能力，这时候，Flume会在数据生产者和数据收容器间做出调整，保证其能够在两者之间提供一共平稳的数据.

- 提供上下文路由特征
- Flume的管道是基于事务，保证了数据在传送和接收时的一致性.
- Flume是可靠的，容错性高的，可升级的，易管理的,并且可定制的。
- 实时性，Flume有一个好处可以实时的将分析数据并将数据保存在数据库或者其他系统中

#### 缺点

Flume的配置很繁琐，source，channel，sink的关系在配置文件里面交织在一起，不便于管理



### Flume启动参数

```
Usage: ./flume-ng <command> [options]...  
  
commands:  
  help                  display this help text  
  agent                 run a Flume agent  
  avro-client           run an avro Flume client  
  version               show Flume version info  
  
global options:  
  --conf,-c <conf>      use configs in <conf> directory  
  --classpath,-C <cp>   append to the classpath  
  --dryrun,-d           do not actually start Flume, just print the command  
  --plugins-path <dirs> colon-separated list of plugins.d directories. See the  
                        plugins.d section in the user guide for more details.  
                        Default: $FLUME_HOME/plugins.d  
  -Dproperty=value      sets a Java system property value  
  -Xproperty=value      sets a Java -X option  
  
agent options:  
  --conf-file,-f <file> specify a config file (required)  
  --name,-n <name>      the name of this agent (required)  
  --help,-h             display help text  
  
avro-client options:  
  --rpcProps,-P <file>   RPC client properties file with server connection params  
  --host,-H <host>       hostname to which events will be sent  
  --port,-p <port>       port of the avro source  
  --dirname <dir>        directory to stream to avro source  
  --filename,-F <file>   text file to stream to avro source (default: std input)  
  --headerFile,-R <file> File containing event headers as key/value pairs on each new line  
  --help,-h              display help text  
  
  Either --rpcProps or both --host and --port must be specified.  
  
Note that if <conf> directory is specified, then it is always included first  
in the classpath. 
```

#### 命令

| 参数        | 描述                      |
| ----------- | ------------------------- |
| help        | 打印帮助信息              |
| agent       | 运行一个Flume Agent       |
| avro-client | 运行一个Avro Flume 客户端 |
| version     | 显示Flume版本。           |

#### 全局选项

| 参数                  | 描述                                               |
| --------------------- | -------------------------------------------------- |
| --conf,-c <conf>      | 在<conf>目录使用配置文件。指定配置文件放在什么目录 |
| --classpath,-C <cp>   | 追加一个classpath     |
| --dryrun,-d           | 不真正运行Agent，而只是打印命令一些信息。          |
| --plugins-path <dirs> | 插件目录列表。默认：$FLUME_HOME/plugins.d          |
| -Dproperty=value      | 设置一个JAVA系统属性值。        |
| -Xproperty=value      | 设置一个JAVA -X的选项。     |

#### Agent选项

| 参数                  | 描述                                                         |
| --------------------- | ------------------------------------------------------------ |
| --conf-file,-f <file> | 指定配置文件，这个配置文件必须在**全局选项**的--conf参数定义的目录下。（必填） |
| --name,-n <name>      | Agent的名称（必填）             |
| --help,-h             | 帮助                |

#### Avro客户端选项

| 参数                   | 描述                        |
| ---------------------- | --------------------------- |
| --rpcProps,-P <file>   | 连接参数的配置文件。        |
| --host,-H <host>       | Event所要发送到的Hostname。 |
| --port,-p <port>       | Avro Source的端口。         |
| --dirname <dir>        | Avro Source流到达的目录。   |
| --filename,-F <file>   | Avro Source流到达的文件名。 |
| --headerFile,-R <file> | 设置一个JAVA -X的选项。     |

启动Avro客户端要么指定--rpcProps，要么指定--host和--port。



### 启动脚本

```
#!/bin/bash
if [ ! -d "/data/" ];then
mkdir /var/log/flume/
fi
name=$2
conf=$1
dir=`find / -name "flume" | awk -F "docs" 'NR==1{print $1"conf"}'`
confdir=$dir"conf"
cmd=$dir"bin/flume-ng"
nohup $cmd agent --conf $confdir -f conf/$conf -Dflume.root.logger=DEBUG,console -n $name  > /var/log/flume/flume.out 2>&1 &
```

### 停止脚本

```
#!/bin/bash
kill -9 $(lsof -i:12306 | awk '{print $2}' | tail -n 1)
```

### 报错

#### 文件名相同，导致flume停止

```
File name has been re-used with different files. Spooling assumptions violated for /data/yfanglog/host-manager.2018-04-17.log.COMPLETED
```

这种情况下后进来的 host-manager.2018-04-17.log，在flume读取完成后会对其进行重命名，但是该文件名已经被占用了，flume就会抛出如下的异常信息,停止处理该监控目录下的其他文件。

跟踪抛出异常的源码，SpoolDirectorySource 会启动一个线程轮询监控目录下的目标文件，当读取完该文件(readEvents)之后会对该文件进行重名(rollCurrentFile)，当重命名失败时会抛出IllegalStateException，被SpoolDirectoryRunnable catch重新抛出RuntimeException，导致当前线程退出，从源码看SpoolDirectoryRunnable 是单线程执行的，因此线程结束后，监控目录下其他文件不再被处理

现在基本清楚了异常栈的调用逻辑，那么和前面自定义解析器一样，我们可以重写ReliableSpoolingFileEventReader以及SpoolDirectorySource的相关实现,也就是自定义一个spooling source，在rollCurrentFile()重命名失败时，做些处理措施，比如将该文件重新命名为access_2015_10_01_16_30.log(2).COMPLETED(此时文件内容已经读取完毕了)继续处理(注意要是.COMPLETED结尾，不然flume会再次读取该文件)。