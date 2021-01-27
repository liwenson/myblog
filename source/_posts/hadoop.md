---
title: hadoop 安装
date: 2019-12-13 14:00:00
categories: 
- bigdata
tags:
- hadoop
---

##hadoop 安装

官方文档`http://hadoop.apache.org/docs/current/`

```
我们建议您下载以下镜像站点：

http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz

其他镜像站点如下所示。
http://mirrors.hust.edu.cn/apache/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz 

http://mirrors.shu.edu.cn/apache/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz 

http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz 

```

### 下载

```
下载地址：https://archive.apache.org/dist/hadoop/common/hadoop-3.0.0-alpha4/  这里找

我们建议您下载以下镜像站点：
http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz
其他镜像站点如下所示。
http://mirrors.hust.edu.cn/apache/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz 
http://mirrors.shu.edu.cn/apache/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz 
http://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.0.1/hadoop-3.0.1.tar.gz 
```

### 关闭防火墙和色linux

```

```



###环境要求

安装jdk,并且Java版本不低于Hadoop要求，并配置环境变量

### 修改hosts

```
192.168.1.12 node1
192.168.1.12 node2
192.168.1.12 node3
```

创建ssh 秘钥，并发送到其他节点

```
ssh-keygen -t rsa
ssh-copy-id node1
```

### 创建目录

在/usr/hadoop/目录下，建立tmp、hdfs/name、hdfs/data目录，执行如下命令 

```
mkdir -p /mnt/hadoop/{tmp,hdfs/{data,name}}
```



###安装

在网站hadoop.apache.org下载稳定版本的Hadoop包

解压压缩包

```
tar xf hadoop-3.0.1.tar.gz
mv hadoop-3.0.1 /usr/local/hadoop
```

### 添加hadoop环境变量

```
设置环境变量，  vim /etc/profile 

# set hadoop path
export HADOOP_HOME=/usr/local/hadoop/
export PATH=$PATH:$HADOOP_HOME/bin
```

###检查Hadoop是否可用

```
hadoop version

Hadoop 3.0.1
Source code repository Unknown -r 496dc57cc2e4f4da117f7a8e3840aaeac0c1d2d0
Compiled by lei on 2018-03-16T23:00Z
Compiled with protoc 2.5.0
From source with checksum 504d49cc3bcf4e2b56e2fd44ced8572
This command was run using /root/hadoop-3.0.1/share/hadoop/common/hadoop-common-3.0.1.jar
```

### 修改配置文件

##### 配置hadoop-env.sh

`vim /usr/local/hadoop/etc/hadoop/hadoop-env.sh `  hadoop配置环境

```
#第27行
export JAVA_HOME=/usr/local/java
```

##### 配置yarn-env.sh

`vim /usr/local/hadoop/etc/hadoop/yarn-env.sh`

```
export JAVA_HOME=/usr/local/java
```

Hadoop配置以.xml文件形式存在

##### 配置core-site.xml  

`/usr/local/hadoop/etc/hadoop/core-site.xml`   hadoop 核心配置文件

`http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/core-default.xml`

```
<configuration>
        <property>
        <!-- 指定hadoop运行时产生文件的存储目录 -->
                <name>hadoop.tmp.dir</name>
                <value>/mnt/hadoop/tmp</value>
        </property>
        <property>
        <!-- 指定HADOOP所使用的文件系统schema（URI），HDFS的老大（NameNode）的地址 -->
                <name>fs.default.name</name>
                <value>hdfs://node1:9000</value>
        </property>
</configuration>
```

##### 配置hdfs-site.xml

 `/usr/local/hadoop/etc/hadoop/hdfs-site.xml`   hdfs服务的 –> 会起进程

`http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml`

```
<configuration>
        <property>
        <!-- datanode上数据块的物理存储位置 -->
                <name>dfs.datanode.data.dir</name>
                <value>/mnt/hadoop/hdfs/data</value>
        </property>
        <property>
        <!-- namenode上存储hdfs名字空间元数据  -->
                <name>dfs.namenode.name.dir</name>
                <value>/mnt/hadoop/hdfs/name</value>
        </property>
        <property>
        <!-- hdfs web 管理界面 -->
                <name>dfs.http.address</name>
                <value>0.0.0.0:8100</value>
        </property>
        <property>
        <!-- 副本个数，配置默认是3,应小于datanode机器数量 -->
                <name>dfs.replication</name>
                <value>1</value>
        </property>
</configuration>
```

##### 配置mapred-site.xml

（注：若没有mapred-site.xml，则需要将mapred-site.xml.template改为mapred-site.xml，并设置hadoop为属主属组）

`/usr/local/hadoop/etc/hadoop/mapred-site.xml`   mapred计算所需要的配置文件] 只当在jar计算时才有

`http://hadoop.apache.org/docs/current/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml`

```
<configuration>  
<property>  
        <name>mapreduce.framework.name</name>  
        <value>yarn</value>  
</property>  
<property>
  <name>mapred.job.tracker.http.address</name>
  <value>0.0.0.0:50030</value>
</property>
<property>
  <name>mapred.task.tracker.http.address</name>
  <value>0.0.0.0:50060</value>
</property>
</configuration> 
```

##### 配置yarn-site.xml

`/usr/local/hadoop/etc/hadoop/yarn-site.xml`  yarn服务的 –> 会起进程

`http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-common/yarn-default.xml`

```
<configuration>  
<property>  
        <name>yarn.nodemanager.aux-services</name>  
        <value>mapreduce_shuffle</value>  
</property>  
<property>  
        <name>yarn.resourcemanager.webapp.address</name>  
        <value>192.168.1.12:8099</value>  
        <description>这个地址是mr管理界面的</description>  
</property>  
</configuration>  
```

### 格式化namenode

```
hdfs namenode -format

成功的话，会看到 "successfully formatted" 和 "Exitting with status 0" 的提示，若为 "Exitting with status 1" 则是出错
```

### 启动

启动NameNode 和 DataNode 守护进程及secondary namenodes

```
sbin/start-dfs.sh
```

启动ResourceManager 和 NodeManager 守护进程

```
sbin/start-yarn.sh
```



```
#! /bin/sh    
rm -rf  /mnt/hadoop/hdfs/data/*  
rm -rf  /mnt/hadoop/hdfs/name/*  
#启动NameNode 和 DataNode 守护进程及secondary namenodes  
sh /usr/local/hadoop/sbin/start-dfs.sh  
#启动ResourceManager 和 NodeManager 守护进程  
sh /usr/local/hadoop/sbin/sbin/start-yarn.sh 
```





###HDFS的使用

HDFS的命令执行格式：hadoop fs -cmd，其中cmd是类shell的命令

```
hadoop fs -ls /                //查看hdfs根目录的文件树
hadoop fs -mkdir /test         //创建test文件夹
hadoop fs -cp 文件 文件        //拷贝文件
hadoop fs -help <cmd>          //#查看帮助
hadoop fs -cat <hdfs上的路径>    //查看文件内容
hadoop fs -put <linux上文件> <hdfs上的路径>   //上传
hadoop fs -get <hdfs上的路径> <linux上文件>   //下载文件

//上传文件到hdfs文件系统上
例如： hadoop fs -put /root/install.log hdfs://localhost:9000/
//删除hdfs系统文件  
例如： hadoop fs -rm hdfs://localhost:9000/install.log  
```

### 测试yarn

**上传一个文件到HDFS**

```
hadoop fs -put  words.txt  hdfs://localhost:9000/
```

让Yarn来统计一下文件信息

```
cd  /$HADOOP_HOME/share/hadoop/mapreduce/
```

测试命令

```
hadoop jar /usr/hadoop/hadoop-3.0.0/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.0.0.jar wordcount /ha.txt /myorder/  
```



### 问题

namenode格式化的时候遇到JAVA_HOME环境变量问题

```
解决办法：hadoop/etc/hadoop/hadoop-env.xml文件中有变量的设置，但是不能满足要求，还要修改一下hadoop/libexec/hadoop-config.sh   文件中大概160行，新增：

export JAVA_HOME=/usr/local/java/
```

datanode无法启动

出现该问题的原因：在第一次格式化dfs后，启动并使用了hadoop，后来又重新执行了格式化命令（hdfs namenode -format)，这时namenode的clusterID会重新生成，而datanode的clusterID 保持不变。

```
解决办法：将hadoop/name/current下的VERSION中的clusterID复制到hadoop/data/current下的VERSION中，覆盖掉原来的clusterID，让两个保持一致然后重启，启动后执行jps，查看进程
```

##### 启动报错

如果运行脚本报如下错误,

ERROR: Attempting to launch hdfs namenode as root
ERROR: but there is no HDFS_NAMENODE_USER defined. Aborting launch.
Starting datanodes
ERROR: Attempting to launch hdfs datanode as root
ERROR: but there is no HDFS_DATANODE_USER defined. Aborting launch.
Starting secondary namenodes [localhost.localdomain]
ERROR: Attempting to launch hdfs secondarynamenode as root
ERROR: but there is no HDFS_SECONDARYNAMENODE_USER defined. Aborting launch.

`解决方案`

（缺少用户定义而造成的）因此编辑启动和关闭

```
vim sbin/start-dfs.sh
vim sbin/stop-dfs.sh
```

顶部空白处

```
HDFS_DATANODE_USER=root
HADOOP_SECURE_DN_USER=hdfs
HDFS_NAMENODE_USER=root
HDFS_SECONDARYNAMENODE_USER=root
```



**如果启动时报如下错误，**

**Starting resourcemanagerERROR: Attempting to launch yarn resourcemanager as rootERROR: but there is no YARN_RESOURCEMANAGER_USER defined. Aborting launch.**



**解决方案**

（也是由于缺少用户定义）

是因为缺少用户定义造成的，所以分别编辑开始和关闭脚本 

```
vim sbin/start-yarn.sh
vim sbin/stop-yarn.sh 
```

```
YARN_RESOURCEMANAGER_USER=root  
HADOOP_SECURE_DN_USER=yarn  
YARN_NODEMANAGER_USER=root 
```