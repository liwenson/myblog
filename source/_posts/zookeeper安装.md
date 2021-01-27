---
title: zookeeper 安装
date: 2019-12-13 14:00:00
categories: 
- bigdata
tags:
- zookeeper
---

## 一、 准备
- 安装JDK
- 准备 安装包 http://archive.apache.org/dist/zookeeper/
- 官方手册 
http://zookeeper.apache.org/doc/r3.4.6/zookeeperStarted.html

## 二、单机安装

### 2.1、解压安装包

```bash
cd /usr/local/src
tar -zxf zookeeper-3.4.9.tar.gz -C /usr/local/
```
### 2.2、配置

创建data和logs 目录
```bash
mkdir -p /mnt/zookeeper/{data,logs}
```
新建`zoo.cfg` 文件,写入以下内容保存：
```
tickTime=2000
dataDir=/usr/myapp/zookeeper-3.4.5/data
dataLogDir=/usr/myapp/zookeeper-3.4.5/logs
clientPort=2181
```
### 2.3、启动和停止
进入bin目录，启动、停止、重启分和查看当前节点状态（包括集群中是何角色）别执行：
```
./zkServer.sh start
./zkServer.sh stop
./zkServer.sh restart
./zkServer.sh status
```

<hr/>

## 三、伪集群模式

伪集群模式就是在同一主机启动多个zookeeper并组成集群，下边以在192.168.220.128主机上创3个zookeeper组集群为例。

将通过第一大点安装的zookeeper，复制成zookeeper1/zookeeper2/zookeeper3三份
### 3.1、准备
```
cd /usr/local/zookeeper/
mkdir {zookeeper1,zookeeper2,zookeeper3}
mkdir -p /mnt/zookerper/{zookeeper1/{data,logs},zookeeper2/{data,logs},zookeeper3/{data,logs}}
```

### 3.2、zookeeper2配置

zookeeper1 配置文件conf/zoo.cfg修改如下：
```
tickTime=2000
dataDir=/mnt/zookerper/zookeeper1/data
dataLogDir=/mnt/zookerper/zookeeper1/logs
clientPort=2181
initLimit=5
syncLimit=2
server.1=192.168.220.128:2888:3888
server.2=192.168.220.128:4888:5888
server.3=192.168.220.128:6888:7888
```
zookeeper1的data/myid配置如下：
```
echo '1' > /mnt/zookerper/zookeeper1/data/myid
```
### 3.3、zookeeper2配置
zookeeper2 配置文件conf/zoo.cfg修改如下：
```
tickTime=2000
dataDir=/mnt/zookerper/zookeeper2/data
dataLogDir=/mnt/zookerper/zookeeper2/logs
clientPort=2181
initLimit=5
syncLimit=2
server.1=192.168.220.128:2888:3888
server.2=192.168.220.128:4888:5888
server.3=192.168.220.128:6888:7888
```
zookeeper2的data/myid配置如下：
```
echo '2' > /mnt/zookerper/zookeeper2/data/myid
```

### 3.4、zookeeper3配置
zookeeper3 配置文件conf/zoo.cfg修改如下：
```
tickTime=2000
dataDir=/mnt/zookerper/zookeeper3/data
dataLogDir=/mnt/zookerper/zookeeper3/logs
clientPort=2181
initLimit=5
syncLimit=2
server.1=192.168.220.128:2888:3888
server.2=192.168.220.128:4888:5888
server.3=192.168.220.128:6888:7888
```
zookeeper1的data/myid配置如下：
```
echo '3' > /mnt/zookerper/zookeeper3/data/myid
```
### 3.5、启动和停止

进入bin目录，启动、停止、重启分和查看当前节点状态（包括集群中是何角色）别执行：
```
./zkServer.sh start
./zkServer.sh stop
./zkServer.sh restart
./zkServer.sh status
```
<hr>

## 四、集群模式

集群模式就是在不同主机上安装zookeeper然后组成集群的模式；下边以在192.168.220.128/129/130三台主机为例。

将第1.1到1.3步中安装好的zookeeper打包复制到129和130上，并都解压到同样的目录下。

### 4.1、conf/zoo.cfg文件修改
三个zookeeper的conf/zoo.cfg修改如下：
```
tickTime=2000
dataDir=/usr/myapp/zookeeper-3.4.5/data
dataLogDir=/usr/myapp/zookeeper-3.4.5/logs
clientPort=2181
initLimit=5
syncLimit=2
server.1=192.168.220.128:2888:3888
server.2=192.168.220.129:2888:3888
server.3=192.168.220.130:2888:3888
```
对于129和130，由于安装目录都是zookeeper-3.4.5所以dataDir和dataLogDir不需要改变，又由于在不同机器上所以clientPort也不需要改变

所以此时129和130的conf/zoo.cfg的内容与128一样即可。

### 4.2、data/myid文件修改

128 data/myid修改如下：
```
echo '1' > data/myid
```
129 data/myid修改如下：
```
echo '2' > data/myid
```
130 data/myid修改如下：
```
echo '3' > data/myid
```

<hr>

## 五、测试集群是否启动成功

```
bin/zkCli.sh  -server 127.0.0.1:2181,127.0.0.1:2182,127.0.0.1:2183

ls /brokers/ids
[1, 2, 3]
```



<hr>

## 六、配置文件详解

```
tickTime=2000:
tickTime这个时间是作为Zookeeper服务器之间或客户端与服务器之间维持心跳的时间间隔,也就是每个tickTime时间就会发送一个心跳；

initLimit=10:
initLimit这个配置项是用来配置Zookeeper接受客户端（这里所说的客户端不是用户连接Zookeeper服务器的客户端,而是Zookeeper服务器集群中连接到Leader的Follower 服务器）初始化连接时最长能忍受多少个心跳时间间隔数。
当已经超过10个心跳的时间（也就是tickTime）长度后 Zookeeper 服务器还没有收到客户端的返回信息,那么表明这个客户端连接失败。总的时间长度就是 10*2000=20 秒；

syncLimit=5:
syncLimit这个配置项标识Leader与Follower之间发送消息,请求和应答时间长度,最长不能超过多少个tickTime的时间长度,总的时间长度就是5*2000=10秒；

dataDir=/export/search/zookeeper-cluster/zookeeper-3.4.6-node1/data
dataDir顾名思义就是Zookeeper保存数据的目录,默认情况下Zookeeper将写数据的日志文件也保存在这个目录里；
datailogDir=/usr/local/zookeeper-cluster/zookeeper-3.5.2-node1/datalog
事物日志的存储路径，如果不配置这个那么事物日志会默认存储到dataDir制定的目录，这样会严重影响zk的性能，当zk吞吐量较大的时候，产生的事物日志、快照日志太多
clientPort=2181
clientPort这个端口就是客户端连接Zookeeper服务器的端口,Zookeeper会监听这个端口接受客户端的访问请求；

server.1=localhost:2887:3887
server.2=localhost:2888:3888
server.3=localhost:2889:3889
server.A=B：C：D：
A是一个数字,表示这个是第几号服务器,B是这个服务器的ip地址
C第一个端口用来集群成员的信息交换,表示的是这个服务器与集群中的Leader服务器交换信息的端口
D是在leader挂掉时专门用来进行选举leader所用

#autopurge.purgeInterval  这个参数指定了清理频率，单位是小时，需要填写一个1或更大的整数，默认是0，表示不开启自己清理功能。
#autopurge.snapRetainCount 这个参数和上面的参数搭配使用，这个参数指定了需要保留的文件数目。默认是保留3个。
```



## 七、supervisor管理

`vim bin/zkEnv.sh`在最上面增加环境路径

```
JAVA_HOME=/usr/local/java
export JAVA_HOME
```

`vim /etc/supervisor/zookeeper.conf`

```
[program:zookeeper]
command=/usr/local/zookeeper-3.5.2-alpha/bin/zkServer.sh start-foreground
autostart=true
autorestart=true
startsecs=10
stdout_logfile=/var/log/zookeeper.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=10
stdout_capture_maxbytes=1MB
stderr_logfile=/var/log/zookeeper.log
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=10
stderr_capture_maxbytes=1MB
```



##八、报错及处理

应用连接zookeepr报错：Session 0x0 for server 192.168.220.128/192.168.220.128:2181,unexpected error,closing socket connection and attempting reconnect；

先看端口能否telnet通，如果通则使用./zkServer.sh status查看zk是否确实已启动，没启查看bin/zookeeper.out中的报错。

bin/zookeeper.out中报错：“zookeeper address already in use”；显然端口被占用，要么是其他进程占用了配置的端口，要么是上边配置的clientPort和server中的端口有重复。

bin/zookeeper.out中报错：Cannot open channel to 2 at election address /192.168.220.130:3888；这应该只是组成集群的130节点未启动，到130启动起来zk即会正常。

