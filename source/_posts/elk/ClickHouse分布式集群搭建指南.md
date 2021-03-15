---
title: ClickHouse分布式集群搭建指南
date: 2021-03-12 14:35
categories:
- elk
tags:
- clickhouse
---
  
  
摘要: ClickHouse分布式集群搭建指南
<!-- more -->

## ClickHouse是什么

ClickHouse 是 Yandex（俄罗斯最大的搜索引擎）开源的一个用于实时数据分析的基于列存储的数据库，其处理数据的速度比传统方法快 100-1000 倍。ClickHouse 的性能超过了目前市场上可比的面向列的 DBMS，每秒钟每台服务器每秒处理数亿至十亿多行和数十千兆字节的数据。

#### ClickHouse的一些特性
- 快速：ClickHouse 会充分利用所有可用的硬件，以尽可能快地处理每个查询。单个查询的峰值处理性能超过每秒 2 TB（解压缩后，仅使用的列）。在分布式设置中，读取是在健康副本之间自动平衡的，以避免增加延迟。
- 容错：ClickHouse 支持多主机异步复制，并且可以跨多个数据中心进行部署。所有节点都相等，这可以避免出现单点故障。单个节点或整个数据中心的停机时间不会影响系统的读写可用性。
- 可伸缩：ClickHouse 可以在垂直和水平方向上很好地缩放。ClickHouse 易于调整以在具有数百或数千个节点的群集上或在单个服务器上，甚至在小型虚拟机上执行。当前，每个单节点安装的数据量超过数万亿行或数百兆兆字节。
- 易用：ClickHouse 简单易用，开箱即用。它简化了所有数据处理：将所有结构化数据吸收到系统中，并且立即可用于构建报告。SQL 允许表达期望的结果，而无需涉及某些 DBMS 中可以找到的任何自定义非标准 API。
- 充分利用硬件：ClickHouse 与具有相同的可用 I/O 吞吐量和 CPU 容量的传统的面向行的系统相比，其处理典型的分析查询要快两到三个数量级。列式存储格式允许在 RAM 中容纳更多热数据，从而缩短了响应时间。
- 提高 CPU 效率：向量化查询执行涉及相关的 SIMD 处理器指令和运行时代码生成。处理列中的数据会提高 CPU 行缓存的命中率。
- 优化磁盘访问：ClickHouse 可以最大程度地减少范围查询的次数，从而提高了使用旋转磁盘驱动器的效率，因为它可以保持连续存储数据。最小化数据传输：ClickHouse 使公司无需使用专门针对高性能计算的专用网络即可管理其数据


## 架构

#### 服务器
centos 7 三台机器（ZooKeeper,clickhouse 高可用）

| 主机 | IP | 应用 | 备注 |
|---|---|---|---|
|logch01.ztyc.com| 10.200.76.11 | ClickHouse-server<br/> ClickHouse-client<br/> jdk1.8<br/> ZooKeeper | |
|logch02.ztyc.com| 10.200.76.12 | ClickHouse-server<br/> ClickHouse-client<br/> jdk1.8<br/> ZooKeeper | |
|logch03.ztyc.com| 10.200.76.13 | ClickHouse-server<br/> ClickHouse-client<br/> jdk1.8<br/> ZooKeeper | |

#### host 文件解析

设置hosts文件解析（ck同步表数据的时候会去ZooKeeper 里面查询，ZooKeeper 里面存储的是hosts域名，不是IP，不解析会导致可以同步表但是无法同步表数据）,三台操作 vi /etc/hosts
```
vim /etc/hosts

10.200.76.11 logch01.ztyc.com
10.200.76.12 logch02.ztyc.com
10.200.76.13 logch03.ztyc.com
```

## 部署zk集群
#### 安装jdk1.8
```
```

#### 安装zk
```
cd /opt/soft
wget https://downloads.apache.org/zookeeper/zookeeper-3.6.2/apache-zookeeper-3.6.2.tar.gz && tar -xf apache-zookeeper-3.6.2.tar.gz 
ln -s apache-zookeeper-3.6.2 /opt/zookeeper
cd /opt/zookeeper
cp conf/zoo_sample.cfg conf/zoo.cfg
mkdir data

```
修改配置文件 `conf/zoocfg` 三台一样
```
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/opt/zookeeper/data
clientPort=2181
server.1=10.200.76.11:2888:3888
server.2=10.200.76.12:2888:3888
server.3=10.200.76.13:2888:3888
```
创建myid在ZooKeeper 数据目录,三台不一样，对应上面server.1这个数字
```
echo 1 > /opt/zookeeper/data/myid  # 其他机器分别是2 3
```
启动并检查
```
./bin/zkServer.sh start
./bin/zkServer.sh status
```


## 搭建clickhouse集群
一分片一副本集群

### 安装clickhouse
```
yum install yum-utils
rpm --import https://repo.yandex.ru/ClickHouse/ClickHouse-KEY.GPG
yum-config-manager --add-repo https://repo.yandex.ru/ClickHouse/rpm/stable/x86_64
yum install ClickHouse-server ClickHouse-client
mkdir /opt/ClickHouse
chown -R ClickHouse.ClickHouse /opt/ClickHouse/  #修改权限
```

### 配置
修改vim /etc/ClickHouse-server/config.xml
修改 listen_host
```
<!-- Listen specified host. use :: (wildcard IPv6 address), if you want to accept connections both with IPv4 and IPv6 from everywhere. -->
    <!-- <listen_host>::</listen_host> -->
    <!-- Same for hosts with disabled ipv6: -->
    <!-- <listen_host>0.0.0.0</listen_host> -->

    <!-- Default values - try listen localhost on ipv4 and ipv6: -->
    <!--
    <listen_host>::1</listen_host>
    <listen_host>127.0.0.1</listen_host>
    -->
    <listen_host>0.0.0.0</listen_host> <!-- 新增所有地址可以访问 -->
    <!-- Don't exit if ipv6 or ipv4 unavailable, but listen_host with this protocol specified -->
    <!-- <listen_try>0</listen_try> -->

    <!-- Allow listen on same address:port -->
    <!-- <listen_reuse_port>0</listen_reuse_port> -->

    <!-- <listen_backlog>64</listen_backlog> -->
```

修改存储路径
```
<!-- Path to data directory, with trailing slash. -->
    <path>/data/ClickHouse/</path>  <!-- 修改存储路径 -->

    <!-- Path to temporary data for processing hard queries. -->
    <tmp_path>/data/ClickHouse/tmp/</tmp_path>
```
添加集群配置
```
<remote_servers>
    <bigdata> <!-- 集群名字，自定义 -->
        <shard> <!-- 定义一个分片 -->
            <!-- Optional. Shard weight when writing data. Default: 1. -->
            <weight>1</weight>
            <!-- Optional. Whether to write data to just one of the replicas. Default: false (write data to all replicas). -->
            <internal_replication>false</internal_replication>
            <replica> <!-- 这个分片的副本存在在哪些机器上 -->
                <host>172.20.1.39</host>
                <port>9000</port>
            </replica>
            <replica>
                <host>172.20.1.246</host>
                <port>9000</port>
            </replica>
        </shard>
      <!--  
        <shard>
            <weight>2</weight>
            <internal_replication>true</internal_replication>
            <replica>
                <host>172.20.1.39</host>
                <port>9000</port>
            </replica>
            <replica>
                <host>172.20.1.246</host>
                <port>9000</port>
            </replica>
        </shard>
        -->
    </bigdata>
</remote_servers>
```

添加zk 配置
```
<!-- ZooKeeper is used to store metadata about replicas, when using Replicated tables.
Optional. If you don't use replicated tables, you could omit that.
 
See https://clickhouse.yandex/docs/en/table_engines/replication/
-->
 
<zookeeper incl="zookeeper-servers" optional="true" />
<zookeeper>
    <node index="1">
        <host>10.200.76.11</host>
        <port>2181</port>
    </node>
    <node index="2">
        <host>10.200.76.12</host>
        <port>2181</port>
    </node>
    <node index="3">
        <host>10.200.76.13</host>
        <port>2182</port>
    </node>
</zookeeper>
```

配置分片macros变量
```
 <macros incl="macros" optional="true" />
    <!-- 配置分片macros变量，在用client创建表的时候回自动带入 -->
    <macros>
      <shard>1</shard>
      <replica>172.20.1.39</replica> <!-- 这里指定当前集群节点的名字或者IP -->
    </macros>
```
启动
```
systemctl start ClickHouse-server.service
systemctl enable ClickHouse-server.service
```
检测
```
[root@bgdata zookeeper]# ClickHouse-client -h 172.20.1.246 -m
ClickHouse client version 20.3.2.1 (official build).
Connecting to 172.20.1.246:9000 as user default.
Connected to ClickHouse server version 20.3.2 revision 54433.
bgdata.operate.ck-0002 :) select * from system.clusters ;

SELECT *
FROM system.clusters

┌─cluster─┬─shard_num─┬─shard_weight─┬─replica_num─┬─host_name────┬─host_address─┬─port─┬─is_local─┬─user────┬─default_database─┬─errors_count─┬─estimated_recovery_time─┐
│ bigdata │         1 │            1 │           1 │ 172.20.1.39  │ 172.20.1.39  │ 9000 │        0 │ default │                  │            0 │                       0 │
│ bigdata │         1 │            1 │           2 │ 172.20.1.246 │ 172.20.1.246 │ 9000 │        1 │ default │                  │            0 │                       0 │
└─────────┴───────────┴──────────────┴─────────────┴──────────────┴──────────────┴──────┴──────────┴─────────┴──────────────────┴──────────────┴─────────────────────────┘

2 rows in set. Elapsed: 0.001 sec.
```


## 测试

两台都分别创建数据库 create database test1;
一台建表建立数据
```
CREATE TABLE t1 ON CLUSTER bigdata
(
    `ts` DateTime,
    `uid` String,
    `biz` String
)
ENGINE = ReplicatedMergeTree('/ClickHouse/test1/tables/{shard}/t1', '{replica}')
PARTITION BY toYYYYMMDD(ts)
ORDER BY ts
SETTINGS index_granularity = 8192
######说明 {shard}自动获取对应配置文件的macros分片设置变量 replica一样  ENGINE = ReplicatedMergeTree，不能为之前的MergeTree
######'/ClickHouse/test1/tables/{shard}/t1' 是写入zk里面的地址，唯一，注意命名规范

INSERT INTO t1 VALUES ('2019-06-07 20:01:01', 'a', 'show');
INSERT INTO t1 VALUES ('2019-06-07 20:01:02', 'b', 'show');
INSERT INTO t1 VALUES ('2019-06-07 20:01:03', 'a', 'click');
INSERT INTO t1 VALUES ('2019-06-08 20:01:04', 'c', 'show');
INSERT INTO t1 VALUES ('2019-06-08 20:01:05', 'c', 'click');
```

第二台机器查看数据，如果数据查询到了 ，并且一致，则成功，否则需重新检查配置

3. 总结
- 副本集是针对的表，不是库也不上整个ck，所以可以一些表用ReplicatedMergeTree也可以直接不复制，所以数据库都需要创建
- 和ES分片和副本机器分布有区别，CK的每台机器只能一个分片的副本，所以如果要搭建2分片2副本需要2*2的机器，不然报错
- 测试读写数据的时候发现，新建的表会同步，但是数据没有同步，通过查CK log以及zk里面对应host发现 zk存储的是主机名，不是ip，所以就无法找到主机写入，需要改hosts文件
- 测试python ClickHouse_driver连接集群，发现需要高版本的ClickHouse_driver，不然没有alt_hosts参数
- 增删数据库每台需要手动执行，增删表需要加上ON CLUSTER bigdata，增删数据是实时异步


#### python连接ck集群范例

```
from ClickHouse_driver import Client
client = Client("172.20.1.39",database="test1",alt_hosts="172.20.1.246") # 这里alt_hosts代表其他副本机器以,分割，shit源码看到的
print(client.execute("show tables"))
```

