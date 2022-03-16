---
title: rsync 实时同步文件
date: 2022-03-08 10:34
categories:
- linux
tags:
- rsync
---
  
  
摘要: rsync 实时同步文件
<!-- more -->


## 服务介绍

### 一、为什么要用rsync+sersync架构？
1、sersync是基于inotify开发的，类似于inotify-tools的工具

2、sersync可以记录下被监听目录中发生变化的（包括增加、删除、修改）具体某一个文件或者某一个目录的名字，然后使用rsync同步的时候，只同步发生变化的文件或者目录

3、因为服务异常导致的同步失败有记录，便于恢复，确保高可用！


### 二、rsync+inotify-tools与rsync+sersync架构的区别？

1、rsync+inotify-tools

- a、inotify只能记录下被监听的目录发生了变化（增，删，改）并没有把具体是哪个文件或者哪个目录发生了变化记录下来；

- b、rsync在同步的时候，并不知道具体是哪个文件或目录发生了变化，每次都是对整个目录进行同步，当数据量很大时，整个目录同步非常耗时（rsync要对整个目录遍历查找对比文件），因此效率很低

2、rsync+sersync

- a、sersync可以记录被监听目录中发生变化的（增，删，改）具体某个文件或目录的名字；

- b、rsync在同步时，只同步发生变化的文件或目录（每次发生变化的数据相对整个同步目录数据来说很小，rsync在遍历查找对比文件时，速度很快），因此效率很高。

## 同步原理

### 同步过程：

1. 在同步服务器上开启sersync服务，sersync负责监控配置路径中的文件系统事件变化;

2. 调用rsync命令把更新的文件同步到目标服务器;

3. 需要在主服务器配置sersync，在同步目标服务器配置rsync server（注意：是rsync服务）

### 同步过程和原理：

    1. 用户实时的往sersync服务器上写入更新文件数据；

    2. 此时需要在同步主服务器上配置sersync服务；

    -3. 在另一台服务器开启rsync守护进程服务，以同步拉取来自sersync服务器上的数据；

通过rsync的守护进程服务后可以发现，实际上sersync就是监控本地的数据写入或更新事件；然后，在调用rsync客户端的命令，将写入或更新事件对应的文件通过rsync推送到目标服务器

## 安装 rsync

Rsync是Linux系统下的数据镜像备份工具，使用快速增量备份工具Remote Sync可以远程同步，可以在不同主机之间进行同步，可实现全量备份与增量备份，保持链接和权限，传输前执行压缩，因此非常适合用于架构集中式备份或异地备份等应用。

### Rsync数据备份

与SCP的比较：scp无法备份大量数据，类似Windows的复制。

而rsync边复制，边统计，边比较。

### Rysnc特性和优点

1.可以镜像保存整个目录树和文件系统。

2.可以很容易做到保持原来文件的属性、权限、时间、软硬链接等等。

3.无须特殊权限即可安装。

4.快速：第一次同步时 rsync 复制全部内容，但在下一次只传输修改过的文件。

5.压缩传输：rsync 在传输数据的过程中可以实行压缩及解压缩操作，因此可以使用更少的带宽。

6.安全性：可以使用scp、ssh等方式来传输文件，当然也可以通过直接的socket连接。选择性保持：符号连接，硬链接，文件属性，权限，时间等。

### Rsync原理

1.运行模式和端口:

采用C/S模式（客户端/服务器模式）[ 实际上是一个点到点的传输，直接使用rsync命令即可完成 ]

rsync监听的端口：873

2.四个名词的解释:

发起端：负责发起rsync同步操作的客户机叫做发起端，通知服务器我要备份你的数据。

备份源：负责响应来自客户机rsync同步操作的服务器叫做备份源，需要备份的服务器。

服务端：运行rsyncd服务，一般来说，需要备份的服务器。

客户端：存放备份数据。

3.数据同步方式:

推push：一台主机负责把数据传送给其他主机，服务器开销很大，比较适合后端服务器少的情况。

拉pull：所有主机定时去找一台主机拉数据，可能就会导致数据缓慢。

推：目的主机配置为rsync服务器，源主机周期性的使用rsync命令把要同步的目录推过去（需要备份的机器是客户端，存储备份的机器是服务端）。

拉：源主机配置为rsync服务器，目的主机周期性的使用rsync命令把要同步的目录拉过来（需要备份的机器是服务端，存储备份的机器是客户端）。

两种方案，rsync都有对应的命令来实现。


### rsync命令的基本用法：

格式：rsync 【选项】 源文件 目标文件

常见的选项：
```
-a，–archive(存档) 归档模式，表示以递归的方式传输文件，并且保持文件属性，等同于加了参数-rlptgoD

-v：显示rsync过程中详细信息。

-r，–recursive 对子目录以递归模式处理

-l,–links 表示拷贝链接文件

-p , –perms 表示保持文件原有权限

-t , –times 表示保持文件原有时间

-g , –group 表示保持文件原有属用户组

-o , –owner 表示保持文件原有属主

-D , –devices 表示块设备文件信息

-z , –compress 表示压缩传输

-H 表示硬连接文件

-A 保留ACL属性信息

-P 显示传输进度

–delete 删除那些目标位置有而原始位置没有的文件
```

### 安装
```
yum -y install rsync
```

### 模式
rsync 命令有三种用法，对应三种工作模式：

`本机同步`，类似于cp命令
```
rsync [选项] SRC DEST
```

`-shell远程同步`，类似于scp命令
```
# 远程主机文件同步到主机
rsync [选项] USER@HOST:SRC DEST
# 本机文件同步到远程主机
rsync [选项] SRC USER@HOST:DEST
```

`-daemon远程同步`
```
# 远程主机文件同步到本地，可使用::或用rsync://指定daemon模式
rsync [选项] USER@HOST::SRC DEST
rsync [选项] rsync://USER@HOST/SRC DEST

# 本机文件同步到远程主机
rsync [选项] SRC USER@HOST::DEST
rsync [选项] SRC rsync://USER@HOST/DEST
```

shell和daemon模式的区别是shell模式使用一个冒号:，而daemon模式使用两个冒号::或用rsync://显式指定。

前两种工作模式比较简单，直接输入源和目标路径即可进行数据同步。第三种用法区分客户端和服务端，需要在服务端配置才能正常工作。

## 配置rsync

### rsyncd.conf配置文件：

配置文件分为两部分：全局参数、模块参数。

全局参数：对rsync服务器生效，如果模块参数和全局参数冲突，冲突的地方模块参数最终生效。

模块参数：定义需要通过rsync输出的目录定义的参数。

### 常见的全局参数：
```
port：指定后台程序使用的端口号，默认为873。

uid：该选项指定当该模块传输文件时守护进程应该具有的uid，配合gid选项使用可以确定哪些可以访问怎么样的文件权限，默认值是” nobody”。

gid：该选项指定当该模块传输文件时守护进程应该具有的gid。默认值为” nobody”。

max connections：指定该模块的最大并发连接数量以保护服务器，超过限制的连接请求将被告知随后再试。默认值是0，也就是没有限制。

lock file：指定支持max connections参数的锁文件，默认值是/var/run/rsyncd.lock。

motd file：” motd file”参数用来指定一个消息文件，当客户连接服务器时该文件的内容显示给客户，默认是没有motd文件的。

log file：” log file”指定rsync的日志文件，而不将日志发送给syslog。

pid file：指定rsync的pid文件，通常指定为“/var/run/rsyncd.pid”，存放进程ID的文件位置。

hosts allow：单个IP地址或网络地址，允许访问的客户机地址。
```
### 常见的模块参数：

主要是定义服务器哪个要被同步输出，其格式必须为“ [ 共享模块名 ]” 形式，这个名字就是在 rsync 客户端看到的名字，其实很像 samba 服务器提供的共享名。而服务器真正同步的数据是通过 path 来指定的。
```
Comment：给模块指定一个描述，该描述连同模块名在客户连接得到模块列表时显示给客户。默认没有描述定义。

path：指定该模块的供备份的目录树路径，该参数是必须指定的。

read only：是否为只读模式true/false。true无法上传写入。

exclude：用来指定多个由空格隔开的多个文件或目录(相对路径)，将其添加到exclude列表中。这等同于在客户端命令中使用―exclude或—-filter来指定某些文件或目录不下载或上传（既不可访问）

exclude from：指定一个包含exclude模式的定义的文件名，服务器从该文件中读取exclude列表定义，每个文件或目录需要占用一行

include：用来指定不排除符合要求的文件或目录。这等同于在客户端命令中使用–include来指定模式，结合include和exclude可以定义复杂的exclude/include规则。

include from：指定一个包含include模式的定义的文件名，服务器从该文件中读取include列表定义。

auth users：该选项指定由空格或逗号分隔的用户名列表，只有这些用户才允许连接该模块。这里的用户和系统用户没有任何关系。如果” auth users”被设置，那么客户端发出对该模块的连接请求以后会被rsync请求challenged进行验证身份这里使用的challenge/response认证协议。用户的名和密码以明文方式存放在” secrets file”选项指定的文件中。默认情况下无需密码就可以连接模块（也就是匿名方式）。

secrets file：该选项指定一个包含定义用户名:密码对应的文件。只有在” auth users”被定义时，该文件才有作用。文件每行包含一个username:passwd对。一般来说密码最好不要超过8个字符。没有默认的secures file名，注意：该文件的权限一定要是600，否则客户端将不能连接服务器。

hosts allow：指定哪些IP的客户允许连接该模块。定义可以是以下形式：
单个IP地址，例如：192.167.0.1，多个IP或网段需要用空格隔开。整个网段，例如：192.168.0.0/24，也可以书写为192.168.0.0/255.255.255.0 ,"*" 则表示所有，默认是允许所有主机连接。

hosts deny：指定不允许连接rsync服务器的机器，可以使用hosts allow的定义方式来进行定义。默认是没有hosts deny定义。

list：该选项设定当客户请求可以使用的模块列表时，该模块是否应该被列出。如果设置该选项为false，可以创建隐藏的模块。默认值是true。

timeout：通过该选项可以覆盖客户指定的IP超时时间。通过该选项可以确保rsync服务器不会永远等待一个崩溃的客户端。超时单位为秒钟，0表示没有超时定义，这也是默认值。对于匿名rsync服务器来说，一个理想的数字是600。
```

### daemon模式常用配置

```
vim /etc/rsyncd.conf

log file = /var/log/rsyncd.log
pidfile = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
secrets file = /etc/rsync.pass

[ansible_config]
path = /etc/
comment = sync etc from client
uid = root
gid = root
port = 873
ignore errors
use chroot = no
read only = no
list = no
max connections = 200
timeout = 600
auth users = admin
```

## rsync 例子
### 安装
```
yum install rsync -y
```
### 配置服务端
```
vim /etc/rsyncd.conf

log file = /var/log/rsyncd.log
pidfile = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
secrets file = /etc/rsync.pass

[ansible_config]
path = /etc/
comment = sync etc from client
uid = root
gid = root
port = 873
ignore errors
use chroot = no
read only = no
list = no
max connections = 200
timeout = 600
auth users = admin
```
### 创建密码文件
```
echo "admin:123456" >> /etc/rsync.pass
chmod 600 /etc/rsync.pass
```

```
systemctl start rsyncd
```

### 客户端操作
#### 配置密码
```
echo "123456" >> /etc/rsync.pass
chmod 600 /etc/rsync.pass
```

#### 推送数据
```
rsync -avH --port 873 --progress --delete /etc/ansible admin@10.200.192.46::ansible_config --password-file=/etc/rsync.pass
```



## 安装sersync

