---
title: centos7安装mysql
date: 2021-07-28 14:15
categories:
- centos7
tags:
- mysql
---
	
	
摘要: centos7安装mysql
<!-- more -->



## 创建目录
```
mkdir -p /data/
```

## 获取mysql
```
curl -O https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.24-linux-glibc2.12-x86_64.tar.gz
```

## 创建用户和用户组
```
useradd -M -s /sbin/nologin mysql
```

## 
```
yum remove mariadb-libs-5.5.68-1.el7.x86_64 -y

yum install libaio -y
```


## 解压mysql 
```
tar -xvzf mysql-5.7.24-linux-glibc2.12-x86_64.tar.gz
ln -s /opt/soft/mysql-5.7.26-linux-glibc2.12-x86_64 /opt/mysql
ln -s /opt/mysql/bin/mysql /usr/bin/mysql
```

## 创建目录
```
mkdir /opt/mysql/{data,binlog,logs,tmp,var}
```

## 初始化mysql,  这里会生成一个初始的临时密码，需要记录下来
```
./mysqld --initialize --user=mysql --basedir=/opt/mysql/ --datadir=/opt/mysql/data/ --lc_messages_dir=/opt/mysql/share --lc_messages=en_US


2021-07-29T10:08:10.580290Z 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
2021-07-29T10:08:12.397039Z 0 [Warning] InnoDB: New log files created, LSN=45790
2021-07-29T10:08:12.475903Z 0 [Warning] InnoDB: Creating foreign key constraint system tables.
2021-07-29T10:08:12.535095Z 0 [Warning] No existing UUID has been found, so we assume that this is the first time that this server has been started. Generating a new UUID: e20cf3d5-f054-11eb-b9fd-5254dc08bf38.
2021-07-29T10:08:12.537662Z 0 [Warning] Gtid table is not ready to be used. Table 'mysql.gtid_executed' cannot be opened.
2021-07-29T10:08:12.538134Z 1 [Note] A temporary password is generated for root@localhost: Nohso!AUs1ex

```
记录下密码


## 编辑my.cnf
```
vim /etc/my.cnf

[mysqld]
basedir=/opt/mysql/
datadir=/opt/mysql/data/
socket=/opt/mysql/data/mysql.sock
 
[client]
port=3306
socket=/opt/mysql/data/mysql.sock
```

### bms  my.cnf
```
[mysql]
port=3306
default-character-set=utf8mb4
no-auto-rehash

[client]
port=3306
socket=/opt/mysql/var/mysql.sock

[mysqld]
#dir
basedir=/opt/mysql
datadir=/opt/mysql/data
tmpdir=/opt/mysql/tmp
log-error=/opt/mysql/logs/alert.log
log_error_verbosity=1
slow_query_log_file=/opt/mysql/logs/slow.log
general_log_file=/opt/mysql/logs/general.log
socket=/opt/mysql/var/mysql.sock
user=mysql
sql_mode=strict_trans_tables
performance_schema=1

#innodb
innodb_data_home_dir=/opt/mysql/data
innodb_log_group_home_dir=/opt/mysql/data
innodb_data_file_path=ibdata1:10M:autoextend
innodb_buffer_pool_size=1G
innodb_buffer_pool_instances=4
innodb_log_files_in_group=2
innodb_log_file_size=1G
innodb_log_buffer_size=200M
innodb_flush_log_at_trx_commit=1
innodb_max_dirty_pages_pct=60
innodb_io_capacity=1000
innodb_thread_concurrency=16
innodb_read_io_threads=8
innodb_write_io_threads=8
innodb_open_files=60000
innodb_file_format=Barracuda
innodb_file_per_table=1
#innodb_flush_method=O_DIRECT
innodb_change_buffering=inserts
innodb_adaptive_flushing=1
innodb_old_blocks_time=1000
innodb_stats_on_metadata=0
innodb_read_ahead_threshold=0
innodb_use_native_aio=0
innodb_lock_wait_timeout=5
innodb_rollback_on_timeout=0
innodb_purge_threads=4
innodb_strict_mode=1
transaction-isolation=READ-COMMITTED

#myisam
key_buffer_size=64M
myisam_sort_buffer_size=64M
concurrent_insert=2
delayed_insert_timeout=300

#binlog
log-bin=/opt/mysql/binlog/mysql-bin
server_id=151
binlog_cache_size=32K
max_binlog_cache_size=2G
max_binlog_size=500M
binlog-format=ROW
sync_binlog=1000
log-slave-updates=1
expire_logs_days=8

#server
default-storage-engine=INNODB
character-set-server=utf8mb4
lower_case_table_names=1
skip-external-locking
open_files_limit=65536
safe-user-create
local-infile=1
#sqlmod="STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE"

log_slow_admin_statements=1
log_warnings=1
long_query_time=1
slow_query_log=1
general_log=0

query_cache_type=0
query_cache_limit=1M
query_cache_min_res_unit=1K

table_definition_cache=65536

thread_stack=512K
thread_cache_size=256
read_rnd_buffer_size=128K
sort_buffer_size=256K
join_buffer_size=128K
read_buffer_size=128K

port=3306
#skip-name-resolve
skip-ssl
max_connections=4500
max_user_connections=4000
max_connect_errors=65536
max_allowed_packet=128M
connect_timeout=8
net_read_timeout=30
net_write_timeout=60
back_log=1024

explicit_defaults_for_timestamp=true

default-time_zone='+8:00'
log_timestamps = system
```


## 授权
```
chown -R mysql /opt/mysql/*
```

```
vim /etc/security/limits.conf

## 增加
mysql hard nofile 65535
mysql soft nofile 65535
```

## 创建systemd管理项
```
vim /usr/lib/systemd/system/mysqld.service


[Unit]
Description=MySQL Server
Documentation=mysqld
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/opt/mysql/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 65535

```

```
systemctl daemon-reload

systemctl start mysqld.service
systemctl status mysqld.service
systemctl enable mysqld.service
```


## 设置mysql远程访问，输入之前生成的临时密码
修改临时密码
```
./mysql -uroot -p

ALTER USER USER() IDENTIFIED BY 'yF!kFXFd!hc9mZbB';
```

设置root远程访问

```
use mysql
GRANT ALL PRIVILEGES ON *.* TO'root'@'%' IDENTIFIED BY'pHE8HXGteTBw' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```
