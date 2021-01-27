---
title: spark 安装
date: 2019-12-13 14:00:00
categories: 
- bigdata
tags:
- spark
---

##准备

###环境要求

Java版本不低于Hadoop要求，并配置环境变量

### 安装

在网站hadoop.apache.org下载稳定版本的Hadoop包

解压压缩包并检查Hadoop是否可用

```
tar xf hadoop-3.0.1.tar.gz
hadoop-3.0.1/bin/hadoop version

Hadoop 3.0.1
Source code repository Unknown -r 496dc57cc2e4f4da117f7a8e3840aaeac0c1d2d0
Compiled by lei on 2018-03-16T23:00Z
Compiled with protoc 2.5.0
From source with checksum 504d49cc3bcf4e2b56e2fd44ced8572
This command was run using /root/hadoop-3.0.1/share/hadoop/common/hadoop-common-3.0.1.jar
```

### 修改配置文件

`hadoop-3.0.1/etc/hadoop/hadoop-env.sh`

```
#第27行
export JAVA_HOME=/usr/local/java
```



Hadoop配置以`.xml`文件形式存在

修改文件 `hadoop-3.0.1/etc/hadoop/core-site.xml` :

```
<configuration>
        <property>
                <!-- 指定hadoop运行时产生文件的存储目录 -->
                <name>hadoop.tmp.dir</name>
                <value>/home/users/hadoop/hadoop/tmp</value>
        </property>
        <property>
                <!-- 指定HADOOP所使用的文件系统schema（URI），HDFS的老大（NameNode）的地址 -->
                <name>fs.default.name</name>
                <value>hdfs://node1:9000</value>
        </property>
</configuration>
```

修改文件`hadoop-3.0.1/etc/hadoop/hdfs-site.xml`:

```
<configuration>
        <property>
                <name>dfs.datanode.data.dir</name>
                <value>/home/users/hadoop/hadoop/data</value>
        </property>
        <property>
                <name>dfs.namenode.name.dir</name>
                <value>/home/users/hadoop/hadoop/name</value>
        </property>
        <property>
                <name>dfs.http.address</name>
                <value>0.0.0.0:8100</value>
        </property>
        <property>
                <name>dfs.replication</name>
                <value>1</value>
        </property>
</configuration>
```

### namenode格式化

```
hadoop-3.0.1/bin/hdfs namenode -format
```

### 开启Namenode和Datanode

```
hadoop-3.0.1/sbin/start-dfs.sh
```

### HDFS的使用

HDFS的命令执行格式：`hadoop fs -cmd`， 其中cmd是类shell的命令(命令可以通过添加环境变量来简化)

```
hadoop fs -ls /        //查看hdfs根目录的文件树
hadoop fs -mkdir /test        //创建test文件夹
hadoop fs -cp 文件 文件        //拷贝文件
```