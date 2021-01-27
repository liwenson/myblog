---
title: MySQL审计工具Audit插件使用
date: 2019-12-13 14:00:00
categories: 
- mysql
tags:
- mysql
---

## MySQL审计工具Audit插件使用

### 一、介绍MySQL AUDIT

`MySQL AUDIT Plugin`是一个 `MySQL`安全审计插件，由McAfee提供，设计强调安全性和审计能力。该插件可用作独立审计解决方案，或配置为数据传送给外部监测工具。支持版本为`MySQL (5.1, 5.5, 5.6, 5.7)，MariaDB (5.5, 10.0, 10.1) ，Platform (32 or 64 bit)`。从Mariadb 10.0版本开始audit插件直接内嵌了，名称为server_audit.so，可以直接加载使用。

源码地址：https://github.com/mcafee/mysql-audit/

WIKI地址：https://github.com/mcafee/mysql-audit/wiki

二进制地址：https://bintray.com/mcafee/mysql-audit-plugin/release

macfee的mysql audit插件虽然日志信息比较大，对性能影响大，但是如果想要开启审计，那也应该忍受了。



<hr/>
### 二、安装使用MySQL AUDIT

1、下载mysql 对应版本的 audit插件

https://bintray.com/mcafee/mysql-audit-plugin/release#files

```

```

2、查看MySQL的插件目录

```
> SHOW GLOBAL VARIABLES LIKE 'plugin_dir'

+---------------+------------------------------+
| Variable_name | Value                        |
+---------------+------------------------------+
| plugin_dir    | /usr/local/mysql/lib/plugin/ |
+---------------+------------------------------+
1 row in set (0.02 sec)
```

3、复制库文件到MySQL库目录下

```
cp cp audit-plugin-mysql-5.7-1.1.4-725/lib/libaudit_plugin.so /usr/local/mysql/lib/plugin/
```

4、加载Audit插件

```
> install plugin audit soname 'libaudit_plugin.so';
```

5、查看版本

```
> show plugins;
......
| BLACKHOLE                  | ACTIVE   | STORAGE ENGINE     | NULL               | GPL     |
| partition                  | ACTIVE   | STORAGE ENGINE     | NULL               | GPL     |
| AUDIT                      | ACTIVE   | AUDIT              | libaudit_plugin.so | GPL     |
+----------------------------+----------+--------------------+--------------------+---------+
43 rows in set (0.09 sec)

> show global status like '%audit%';
+------------------------+-----------+
| Variable_name          | Value     |
+------------------------+-----------+
| Audit_protocol_version | 1.0       |
| Audit_version          | 1.1.7-866 |
+------------------------+-----------+
2 rows in set (0.08 sec)

```

6、开启Audit功能：

```
> SET GLOBAL audit_json_file=ON;
Query OK, 0 rows affected (0.00 sec)

```

7、查看插件有哪些可配置的参数：

```
>  SHOW GLOBAL VARIABLES LIKE '%audi%'; 
```



```
其中我们需要关注的参数有：

1. audit_json_file
是否开启audit功能。

2. audit_json_log_file
记录文件的路径和名称信息（默认放在mysql数据目录下）。

3. audit_record_cmds
audit记录的命令，默认为记录所有命令。可以设置为任意dml、dcl、ddl的组合。如：audit_record_cmds=select,insert,delete,update。还可以在线设置set global audit_record_cmds=NULL。(表示记录所有命令)

4. audit_record_objs
audit记录操作的对象，默认为记录所有对象，可以用SET GLOBAL audit_record_objs=NULL设置为默认。也可以指定为下面的格式：audit_record_objs=,test.*,mysql.*,information_schema.*。

5. audit_whitelist_users
用户白名单。


https://github.com/mcafee/mysql-audit/wiki/Configuration
```

### 三、[libaudit_plugin.so安装]



1、上传audit到mysql的plugin目录

2、配置my.cnf 文件

```
vim /etc/my.cnf
[mysqld]
plugin-load=AUDIT=libaudit_plugin.so
audit_json_file=1
audit_json_file=ON
audit_record_cmds=connect,Quit,show,select,insert,update,delete
audit_whitelist_users=blacklist,mysql2,gmetric,procdb

```

3、启动登录mysql

```
INSTALL PLUGIN AUDIT SONAME 'libaudit_plugin.so';
SET GLOBAL audit_json_file=ON;
SET GLOBAL audit_whitelist_users='qrr,mysql2,gmetric,procdb,{}'

{}:表示空用户
```



