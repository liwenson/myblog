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

|服务器编号	|服务器 IP 地址 |	LF 通信端口 |	LF 选举端口	| 客户端端口|	
|---|---|---|---|---|
|1	|10.200.75.177	|2010	|6008|	2180|
|2	|10.200.75.178	|2010	|6008|	2180|
|3	|10.200.75.179	|2010	|6008|	2180|


目录创建
```
mkdir -p /opt/zookeeper/
```

```
tar xf apache-zookeeper-3.7.0-bin.tar.gz -C /opt/zookeeper/
```

mylog、mydata

目录创建
```
mkdir -p /opt/zookeeper/apache-zookeeper-3.7.0-bin/{mylog,mydata}
```

配置JVM, java.env 文件需要创建
vim conf/java.env
```
#!/bin/sh
export JAVA_HOME=/opt/jdk1.8.0_161/
export JVMFLAGS="-Xms512m -Xmx4096m $JVMFLAGS"
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