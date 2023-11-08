---
title: centos7安装polardb
date: 2023-06-27 18:19
categories:
- polardb
tags:
- polardb
---
  
  
摘要: desc
<!-- more -->


## 简介

PolarDB-X 是一款面向超高并发、海量存储、复杂查询场景设计的云原生分布式数据库系统。其采用 Shared-nothing 与存储计算分离架构，支持水平扩展、分布式事务、混合负载等能力，具备企业级、云原生、高可用、高度兼容 MySQL 系统及生态等特点。

开源地址：https://github.com/polardb/polardbx-sql 

## 架构简介

PolarDB-X 采用 Shared-nothing 与存储分离计算架构进行设计，系统由5个核心组件组成。

- 计算节点（CN, Compute Node）
计算节点是系统的入口，采用无状态设计，包括 SQL 解析器、优化器、执行器等模块。负责数据分布式路由、计算及动态调度，负责分布式事务 2PC 协调、全局二级索引维护等，同时提供 SQL 限流、三权分立等企业级特性。

- 存储节点（DN, Data Node）
存储节点负责数据的持久化，基于多数派 Paxos 协议提供数据高可靠、强一致保障，同时通过 MVCC 维护分布式事务可见性。

- 元数据服务（GMS, Global Meta Service）
元数据服务负责维护全局强一致的 Table/Schema, Statistics 等系统 Meta 信息，维护账号、权限等安全信息，同时提供全局授时服务（即 TSO）。

- 日志节点（CDC, Change Data Capture）
日志节点提供完全兼容 MySQL Binlog 格式和协议的增量订阅能力，提供兼容 MySQL Replication 协议的主从复制能力。

- 列存节点 (Columnar)
列存节点负责提供列式存储数据，基于行列混存 + 分布式计算节点构建HTAP架构，预计在今年底或者明年初会正式开源 


![PolarDB-X 架构](image/architecture.png)


## 部署

### 最低部署规格 (建议>=2c8g)

|组件|CPU|内存|磁盘类型|网卡|最低数量|
|---|---|---|---|---|---|
|CN|2C|8G+|SSD,200G+|万兆网卡|2|
|DN||2C|8G+|SSD,1T+(推荐2块)|万兆网卡|2.5|
|GMS|2C|8G+|SSD,200G+|万兆网卡|2.5|
|CDC|2C|8G+|SSD,200G+|万兆网卡|2(可选)|

**GMS 和 DN 2.5 倍资源说明**：GMS 和 DN 是基于多数派 Paxos 协议构建的高可靠存储服务，因此一个 GMS（DN）会包括三个角色的节点：Leader，Follower，Logger。 Leader 与 Follower 资源要求相同，保证高可用切换后的服务质量，而 Logger 节点，只存储日志，不回放日志，固定为2核4GB的资源规格，即可满足常见百万级TPS的需求。因此一个 GMS（DN）需要 2.5 倍的资源，其中 2 是 Leader 和 Follower的资源，0.5 是 Logger的资源。 


[参考文档](https://doc.polardbx.com/deployment/topics/environment-requirement.html)

### 快速部署

[参考文档](https://doc.polardbx.com/quickstart/topics/quickstart.html)


#### 安装python3

```
yum install -y python3
```

### 安装docker

集群模式下，docker engine 版本需要大于等于18.04。 

```bash
curl -o /etc/yum.repos.d/docker-ce.repo  http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo


yum install docker-ce -y
```

#### 安装 PXD

PXD 是 PolarDB-X 的部署工具，除了支持在本地一键快速拉起测试环境外，也支持在 Linux 集群中通过指定的拓扑的方式部署 PolarDB-X 分布式数据库。

创建一个 Python3 的 virtual environment 环境并激活

```
python3 -m venv venv
source venv/bin/activate
```

> 官方文档推荐使用 virtual environment 安装 PXD 工具


```
# 安装前建议先执行如下命令升级pip
pip install --upgrade pip

# 安装 pxd
pip install pxd

或者,国内用户从 pypi 下载包的速度较慢, 可以使用如下命令从阿里云的镜像安装

pip install -i http://mirrors.aliyun.com/pypi/simple/ pxd
```

#### 部署 PolarDB-X

##### 镜像准备

网络不好的情况，可以通过代理提前准备好镜像

```
polardbx/polardbx-cdc           latest        d312b26b6305   32 hours ago    1.16GB
polardbx/polardbx-engine-2.0    latest        44825bcb5546   3 weeks ago     2.14GB
polardbx/polardbx-sql           latest        9bc2cf4f5a5b   2 months ago    1.24GB
polardbx/xstore-tools           latest        ed9dc35016c6   2 months ago    1.87GB
polardbx/polardbx-init          latest        6f6f1947f2d3   2 months ago    10.2MB
```

快速部署
```
# 直接运行 pxd tryout 命令会创建一个最新版本的 PolarDB-X 数据库，其中 GMS, CN, DN, CDC 节点各 1 个：

pxd tryout
```

[更多配置查看官方文档](https://doc.polardbx.com/quickstart/topics/quickstart.html#%E9%83%A8%E7%BD%B2-polardb-x)

部署完成

```
Processing  [###########-------------------------]   30%    create gms node
Processing  [#############-----------------------]   38%    create gms db and tables
Processing  [################--------------------]   46%    create PolarDB-X root account
Processing  [###################-----------------]   53%    create dn
Processing  [######################--------------]   61%    register dn to gms
Processing  [########################------------]   69%    create cn
Processing  [###########################---------]   76%    wait cn ready
Processing  [##############################------]   84%    create cdc containers
Processing  [#################################---]   92%    wait PolarDB-X ready
Processing  [####################################]  100%


PolarDB-X cluster create successfully, you can try it out now.
Connect PolarDB-X using the following command:

    mysql -h127.0.0.1 -P55755 -upolardbx_root -pMtbYwNRe
(venv) [root@centos-7 polardbx]# 

```

#### 安装mysql client 连接测试

```
rpm -ivh https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022

yum install mysql-community-client.x86_64 -y
```

测试

```
mysql -h127.0.0.1 -P55755 -upolardbx_root -pMtbYwNRe

mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 15
Server version: 5.6.29 Tddl Server (ALIBABA)

Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| DATABASE           |
+--------------------+
| information_schema |
+--------------------+
1 row in set (0.02 sec)
```


### 创建数据库

```
# 创建数据库
create database priv_test;

#使用数据库
use priv_test;

#创建表
create table test (id int primary key, value int);
```

### 授权

#### 查看所有用户

```
mysql> select * from mysql.user\G;
```

#### 创建用户

```
mysql> CREATE USER 'test01'@'127.0.0.1' IDENTIFIED BY '123456';

mysql> CREATE USER IF NOT EXISTS 'test02'@'%' identified by '123456';
```

#### 修改账号密码

```
mysql> SET PASSWORD FOR 'test01'@'127.0.0.1' = PASSWORD('654321');
```

#### 删除账号

```
mysql> DROP USER 'test02'@'%';
```

#### 授予账号权限

```
mysql> GRANT SELECT,UPDATE ON `priv_test`.* TO 'test01'@'127.0.0.1';
```

#### 查看账号权限

```
mysql> SHOW GRANTS FOR 'test01'@'127.0.0.1';

+------------------------------------------------------+
| GRANTS FOR 'TEST1'@'127.0.0.1'                       |
+------------------------------------------------------+
| GRANT USAGE ON *.* TO 'test01'@'127.0.0.1'            |
| GRANT SELECT, UPDATE ON priv_test.* TO 'test01'@'127.0.0.1' |
+------------------------------------------------------+
```

#### 回收账号权限

```
mysql> REVOKE UPDATE ON priv_test.* FROM 'test01'@'127.0.0.1';
mysql> SHOW GRANTS FOR 'test01'@'127.0.0.1';

+----------------------------------------------+
| GRANTS FOR 'TEST1'@'127.0.0.1'               |
+----------------------------------------------+
| GRANT USAGE ON *.* TO 'test01'@'127.0.0.1'    |
| GRANT SELECT ON priv_test.* TO 'test01'@'127.0.0.1' |
+----------------------------------------------+
```


### 角色

#### 查看所有角色

```
mysql> select host, user, plugin from mysql.user;

+------+---------------+--------+
| host | user          | plugin |
+------+---------------+--------+
| %    | polardbx_root | NULL   |
| %    | test02        | NULL   |
+------+---------------+--------+
2 rows in set (0.04 sec)
```










