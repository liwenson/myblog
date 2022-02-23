---
title: init-connect+binlog实现mysql审计
date: 2019-12-13 14:00:00
categories: 
- mysql
tags:
- flume
---

**一、简介**

1、概述

mysql本身已经提供了详细的sql执行记录–general log ，但是开启它有以下几个缺点：

1）无论sql有无语法错误，只要执行了就会记录，导致记录大量无用信息，后期的筛选有难度。

2）sql并发量很大时，log的记录会对io造成一定的印象，是数据库效率降低。

3）日志文件很容易快速膨胀，不妥善处理会对磁盘空间造成一定影响。

2、原理

1） 由于审计的关键在于DML语句，而所有的DML语句都可以通过binlog记录。

2）不过遗憾的是目前MySQL binlog 中只记录，产生这条记录的connection id（随连接数自增，循环使用），这对之后的反查没有任何帮助。

3）因此考虑通过init-connect，在每次连接的初始化阶段，记录下这个连接的用户，和connection_id信息。

4）在后期审计进行行为追踪时，根据binlog记录的行为及对应的connection-id 结合 之前连接日志记录 进行分析，得出最后的结论。

**备注：根据自己的实际环境使用审计方式，切记谨慎使用。**

3、相对于audit审计插件

 缺点：只对有低级权限的用户的操作有记录，权限高的则没有 。

 优点：日志信息比较小，对性能影响小



**二、安装审计功能**

1、创建审计用的库表。

```
mysql> create database db_monitor charset utf8;
mysql> use db_monitor
CREATE TABLE accesslog
( thread_id int(11) DEFAULT NULL,  #进程id
log_time datetime default null,  #登录时间
localname varchar(50) DEFAULT NULL, #登录名称，带详细ip
matchname varchar(50) DEFAULT NULL,  #登录用户
key idx_log_time(log_time)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
```





2、配置init-connect参数

\# vim /etc/my.cnf

[mysqld]

server-id = 130

federated

log-bin = mysql-bin

binlog_format = mixed

init_connect='insert into db_monitor.accesslog(thread_id,log_time,localname,matchname) values(connection_id(),now(),user(),current_user());'

3、删除默认用户：

mysql> delete from user where Host='localhost' and User='';

4、创建普通用户，不能有super权限，而且用户必须有对access_log库的access_log表的insert权限，否则会登录失败。

mysql> GRANT CREATE,DROP,ALTER,INSERT,DELETE,UPDATE,SELECT ON *.* TO audi01@'%' IDENTIFIED BY '147258';

mysql> flush privileges;

5、赋予用户access_log的insert、select权限，然后重新赋予权限：

mysql> GRANT SELECT,INSERT ON db_monitor.* TO audi01@'%';

mysql> flush privileges;

6、查看，使用audi01用户登录查看

mysql> select * from accesslog;

mysql> delete from accesslog where thread_id=10;