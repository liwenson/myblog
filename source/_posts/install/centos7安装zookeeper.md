---
title: centos7安装zk集群
date: 2021-07-24 14:34
categories:
- centos7
tags:
- zookeeper
---
	
	
摘要: centos7 安装zookeeper集群
<!-- more -->

|服务器编号 |服务器 IP 地址 | LF 通信端口 | LF 选举端口 | 客户端端口|
|---|---|---|---|---|
|1 |10.200.75.177 |2010 |6008| 2180|
|2 |10.200.75.178 |2010 |6008| 2180|
|3 |10.200.75.179 |2010 |6008| 2180|

目录创建

```bash
mkdir -p /opt/zookeeper/
```

```bash
tar xf apache-zookeeper-3.7.0-bin.tar.gz -C /opt/zookeeper/
```

mylog、mydata

目录创建

```bash
mkdir -p /opt/zookeeper/apache-zookeeper-3.7.0-bin/{mylog,mydata}
```

配置JVM, java.env 文件需要创建

vim conf/java.env

```bash
#!/bin/sh
export JAVA_HOME=/opt/jdk1.8.0_161/
export JVMFLAGS="-Xms512m $JVMFLAGS"
```

改 -Xmx

```bash
vim bin/zkEnv.sh 

ZK_SERVER_HEAP="${ZK_SERVER_HEAP:-1000}"

改为
ZK_SERVER_HEAP="${ZK_SERVER_HEAP:-4096}"
```


配置文件

vim conf/zoo.cfg
```
# tickTime:客户端与服务器、服务器与服务器之间维持心跳的时间间隔,也就是每一个 tickTime 会发送一次心跳,单位为毫秒
tickTime=2000
# initLimit:集群中 Leader 和 Follow 初始化连接时最多能容忍的心跳数
# 也就是初始化过程中,如果 Leader 和 Follow 在 (10*tickTime)ms的时间内还没有连接上,则认为连接失败
initLimit=10
# syncLimit:同步通信实现, Leader 和 Follow 服务器之间发送请求和接收应答最多能容忍的心跳数
# 也就是 Leader 和 Follow 如果发送的请求在 (5*tickTime)的时间没没有应答,那么就认为 Leader 和 Follow 之间连接失败
syncLimit=5
# 自定义的 zookeeper 数据存放目录
dataDir=/opt/zookeeper/apache-zookeeper-3.7.0-bin/mydata
# 自定义的 zookeeper 的日志存放目录
dataLogDir=/opt/zookeeper/apache-zookeeper-3.7.0-bin/mylog
# 客户端连接的端口
clientPort=2180
# Zookeeper集群中节点个数一般为奇数个(>=3),若集群中 Master 挂掉,剩余节点个数在半数以上时,就可以推举新的主节点,继续对外提供服务
# Zookeeper集群配置项的格式比较特殊,具体规则如下: server:N=YYYY:A:B
# N:表示服务器编号,例如 0、1、2......
# YYYY:表示服务器的IP地址.
# A:为LF的通信端口,表示该服务器与集群中的 Leader 交换信息的端口
# B:为选举端口,表示选举新 Leader 时,服务器之间相互通信的端口(当 Leader 挂掉时,其它的服务器会相互通信,选择出新的 Leader)
# 一般来说,集群中的 A 和 B 都是一样的,只有伪集群的时候 A 和 B 才不一样
server.1=10.200.75.177:2010:6008
server.2=10.200.75.178:2010:6008
server.3=10.200.75.179:2010:6008
```


新建 myid 文件,并编辑 myid 文件,并且在里面写入对应的 server 的数字
```
echo "1" > /opt/zookeeper/apache-zookeeper-3.7.0-bin/mydata/myid
echo "2" > /opt/zookeeper/apache-zookeeper-3.7.0-bin/mydata/myid
echo "3" > /opt/zookeeper/apache-zookeeper-3.7.0-bin/mydata/myid
```

zk启动文件
```
vim /lib/systemd/system/zookeeper.service

[Unit]
Description=Zookeeper
Requires=network.target
After=network.target

[Service]
Type=forking
Environment=JAVA_HOME=/opt/jdk1.8.0_161
WorkingDirectory=/opt/zookeeper/apache-zookeeper-3.7.0-bin
ExecStart=/opt/zookeeper/apache-zookeeper-3.7.0-bin/bin/zkServer.sh start /opt/zookeeper/apache-zookeeper-3.7.0-bin/conf/zoo.cfg
ExecStop=/opt/zookeeper/apache-zookeeper-3.7.0-bin/bin/zkServer.sh stop /opt/zookeeper/apache-zookeeper-3.7.0-bin/conf/zoo.cfg
ExecReload=/opt/zookeeper/apache-zookeeper-3.7.0-bin/bin/zkServer.sh restart /opt/zookeeper/apache-zookeeper-3.7.0-bin/conf/zoo.cfg
Restart=always
RestartSec=10
TimeoutSec=360

[Install]
WantedBy=multi-user.target
```

```
systemctl daemon-reload
systemctl start zookeeper

systemctl enable zookeeper
systemctl is-enabled zookeeper
```

查找集群状态
```
/opt/zookeeper/apache-zookeeper-3.7.0-bin/bin

./zkServer.sh status
```

测试链接zookeeper
```
/opt/zookeeper/apache-zookeeper-3.7.0-bin/bin

./zkCli.sh -server 10.200.75.177:2180
```

zk选举策略

全新集群，无数据情况下

假设有五台服务器组成zookeeper集群，它们的id从1-5，全新的zk集群，没有历史数据。
1、服务器 1 启动，此时只有它一台服务器启动了，它发出去的报文没有任何响应，所以它的选举状态一直是Looking 状态
2、服务器 2 启动，它与最开始的服务器 1 进行通讯，互相交换自己的选举结果，由于两者都没有历史数据，所以id 值大的服务器 2 胜出，但是没有超过半数以上的服务器都同意选举它（zk集群规则 2N+1 台，最好是基数，不然选举不平衡）,所以此时服务器 1 2 还是继续保持 LOOKING 状态。
3、服务器 3 启动，根据前面的分析，服务器 3 的id值最大，启动的服务器达到了例子中的半数以上（zk集群最小数量要求为3），此时有三台服务器选举了它，成为Leader。
4、服务器 4 启动，根据前面的分析，理论上服务器 4 的id应该是 服务器 1 2 3 4 中最大的，但是前面已经有半数以上的服务器选举了服务器 3 ，所以它成为了 Follower。
5、服务器 4 启动，同 4 一样成为 Follower。

注意，如果按照 5,4,3,2,1 的顺序启动，那么服务器 5 将成为 Leader ,因为在满足半数条件后，zk 集群启动，5 的ID 最大，被选举为Leader


可以理解为，根据服务器ID（sid）的大小，结合服务器启动顺序，在达到半数服务器启动的状态下，服务器id（sid）值大的被选举为 leader 

有数据情况下

在有数据的情况下，选举的过程就相对复杂了，需要加入数据id，leader id和逻辑时钟。
数据id（zxid）: 数据新的id就大，数据每次更新都会更新id
myid(sid)： zk配置中的 myid的值，每个机器一个
逻辑时钟（Epoch）： 这个值从0开始递增,每次选举对应一个值,如果在同一次选举中,那么这个值应该是一致的 ; 逻辑时钟值越大,说明这一次选举leader的进程更新.

选举的标准
1、逻辑时钟小的选举结果被忽略，重新投票
2、统一逻辑时钟后，数据id大的胜出
3、数据id相同的情况下， myid大的胜出

步骤
1、统计逻辑时钟是否相同，逻辑时钟小，说明途中可能存在宕机的问题，因此数据不完整，那么该次的选举结果被忽略，重新投票选举
2、统一时钟后，对比数据id(zxid)值，数据id值反应数据的新旧程度，因此数据id大的胜出。
3、如果逻辑时钟和数据id都相同的情况下，那么比较服务器id（sid）,值大的胜出。

非全新集群选举时是优中选优，保证Leader是Zookeeper集群中数据最完整、最可靠的一台服务器


