---
title: Centos7安装bind9
date: 2021-02-25 09:50
categories:
- centos7
tags:
- dns
---
  
  
摘要: centos7安装bind9
<!-- more -->

[TOC]

## 编译前环境准备

### 下载bind9
[bind官网](https://www.isc.org/bind/)
前往官网下载源码，当前有3个版本

|VERSION	|STATUS|	RELEASE DATE|	EOL DATE|
|---|---|---|---|
|9.17.10	|Development	|February 2021	|TBD|
|9.16.12	|Current-Stable	|February 2021	|TBD|
|9.11.28	|Current-Stable, ESV	|February 2021	|December 2021|

- Development 为开发版，不适用于生产环境
- Current-Stable 稳定版本
- Approaching EOL 即将停更版本
- Current-Stable, ESV 带扩展功能的的稳定版本
- Unscheduled Releases  非计划版本
```

如果在稳定性压倒一切的生产环境运行BIND，选择一个版本部署后，你希望软件尽量不要变动（仍然可以收到补丁更新），推荐ESV版本。这会有一个更长的支持生命周期，并且可以升级解决安全和重要BUG，但是其他方面改动很小。我们会提前提供下个主要版本的信息，稳定后，将称为ESV版本。


cd /usr/local/src
wget https://downloads.isc.org/isc/bind9/9.16.12/bind-9.16.12.tar.xz
```

## 编译安装

### 安装依赖
```
yum install -y libuv libuv-devel libcap-devel pcre-devel zlib-devel gcc gcc-c++ autoconf automake make pcre-devel zlib-devel openssl-devel openldap-devel unixODBC-devel gcc libtool openssl  bind-utils python-pip
```

XML 统计通道需要使用 libxml2
```
yum install libxml2 libxml2-devel
```

```
pip install ply
```

解压
```
cd /usr/local/src
tar -xvf bind-9.16.12.tar.xz
```
### 安装

XML 统计通道需要使用 libxml2 构建 BIND

```
cd bind-9.16.12
./configure --prefix=/usr/local/bind9 --sysconfdir=/etc/named/ --enable-largefile --with-tuning=large --with-openssl --with-libxml2
```
```
make && make install
```

### 编译错误处理

`错误一`
```
configure: error: Python >= 2.7 or >= 3.2 and the PLY package are required for dnssec-keymgr and other Python-based tools. 
PLY may be available from your OS package manager as python-ply or python3-ply; it can also be installed via pip. To build without Python/PLY, use --without-python.
```
处理
执行pip install ply安装ply，安装前要确保此时setuptools和pip已经安装，如果未安装则需要单独安装。如果不安装ply模块，bind在编译时会报错如下。
```
pip install ply
```

`错误二`
```
checking for libuv... checking for libuv >= 1.0.0... no
configure: error: libuv not found
```
处理
```
yum install -y epel-release
yum install libuv
yum install libuv-devel
```

`错误三`
```
configure: error: sys/capability.h header is required for Linux capabilities support. Either install libcap or use --disable-linux-caps.
```
处理
```
yum install libcap-devel
```


### 添加环境变量
```
vim /etc/profile.d/named.sh
export PATH=/usr/local/bind9/bin:/usr/local/bind9/sbin:$PATH

. /etc/profile.d/named.sh
```

### 导出库文件搜索路径
```
$ vim /etc/ld.so.conf.d/named.conf
/usr/local/bind9/lib
$ ldconfig -v
```

### 导出头文件搜索路径
```
$ ln -sv /usr/local/bind9/include /usr/include/named

"/usr/include/named" -> "/usr/local/bind9/include"
```

### 导出帮助文档搜索路径（非必须）
```
$ vim /etc/man.config
MANPATH /usr/local/bind9/share/man
```



## 配置

### 准备


创建服务专用账户named，禁止本地登陆户
```
useradd -d /usr/local/bind9 -s /sbin/nologin named
```

接下来我们更改所有配置文件的用户为named用户
```
mkdir /run/named
mkdir -p /var/named/{dynamic,data,zone}


```

在联网的情况下直接将查询根的结果导入根区域配置文件,如果是把bind当作递归查询服务器使用，默认情况下的bind是会自动启用了hint类型的解析

```
$ dig -t NS . > /var/named/named.ca
```

配置会把所有匹配到这个zone的DNS查询请求转发到/var/named/named.ca文件中的13个根DNS服务器节点，为了减少不必要的干扰，我们可以把文件中的的AAAA记录注释掉。



### rndc配置
rndc是一个管理程序，可以用它来刷新配置，停止服务，强制同步等
```
rndc-confgen  > /etc/named/rndc.conf
```
打开rndc.conf文件，找到# Use with the following in named.conf, adjusting the allow list as needed:注释，复制其下所有行到named.conf并放开注释。
```
tail -10 /etc/named/rndc.conf | head -9 | sed s/#\ //g > named.conf
```
最终的named.conf文件像下面这样
```
key "rndc-key" {
  algorithm hmac-sha256;
  secret "...";
};

controls {
  inet 127.0.0.1 port 953
  allow { 127.0.0.1; } keys { "rndc-key"; };
};

```

### 主配置

将配置文件追加到  named.conf
```
$ cd /etc/named
$ vim named.conf

options {
  listen-on port 53 { any; };
  listen-on-v6 port 53 { ::1; };
  directory "/var/named";   # zone配置根目录
  dump-file "/var/named/data/cache_dump.db";
  statistics-file "/var/named/data/named_stats.txt";
  memstatistics-file "/var/named/data/named_mem_stats.txt";
  allow-query { any; };
  recursion yes; # 允许递归查询
  allow-new-zones yes;  #允许添加zone
  max-cache-size 70%;
  dnssec-validation no;   # 指定是否提供使用dnssec认证的资源记录.默认为yes.

  forward first;
  forwarders {
    114.114.114.114; # 电信DNS
  };

  /* Path to ISC DLV key */
  bindkeys-file "/etc/named/bind.keys";

  managed-keys-directory "/var/named/dynamic";

  pid-file "/run/named/named.pid";
  session-keyfile "/run/named/session.key";

};

## 开启日志会影响查询速度
logging {
  channel queries_log {
    file "data/named.run" versions 3 size 300m; # 这里的路径是相对于上面的directory路径
    print-time yes;                  # 日志文件每300MB切割一次
    print-category yes;
    print-severity yes;
    severity info;
  };

  channel query-errors_log {
    file "data/query-errors.run" versions 5 size 20m;
    print-time yes;
    print-category yes;
    print-severity yes;
    severity dynamic;
  };

  category queries { queries_log; };
  category resolver { queries_log; };
  category query-errors {query-errors_log; };
};


zone "." IN { # 根域名
  type hint;
  file "named.ca";
};

#include "/etc/named/named.rfc1912.zones";
```

### zones 配置
```
$ vim /var/named/abc.com.zone

$TTL 10M  ;time to live  信息存放在高速缓存中的时间长度，以秒为单位
@       IN      SOA     abc.com.      admin.abc.com. (
                        1   ;序列号
                        1H  ;1小时后刷新
                        5M  ;15分钟后重试
                        7D  ;1星期后过期
                        1D );否定缓存TTL为1天
        IN      NS      ns.abc.com.
ns      IN      A       192.168.7.134
www       IN      A      192.168.7.133
@         IN      A      192.168.7.133
api       IN      A      192.168.7.133
a         IN      A      192.168.7.134
```

## 启动

### 权限配置

```
chown -R named:named /usr/local/bind9/
chown -R named:named /etc/named
chown -R named:named /var/named/
chown -R named:named /run/named
```

### 检查配置

实时日志
```
named -u named -g
```

```
vim  /usr/lib/systemd/system/named.service

[Unit]
Description=Berkeley Internet Name Domain (DNS)
Wants=nss-lookup.target
Wants=named-setup-rndc.service
Before=nss-lookup.target
After=network.target
After=named-setup-rndc.service

[Service]
Type=forking
Environment=NAMEDCONF=/etc/named/named.conf
EnvironmentFile=-/etc/sysconfig/named
Environment=KRB5_KTNAME=/etc/named.keytab
PIDFile=/run/named/named.pid

ExecStartPre=/bin/bash -c 'if [ ! "$DISABLE_ZONE_CHECKING" == "yes" ]; then /usr/local/bind9/sbin/named-checkconf -z "$NAMEDCONF"; else echo "Checking of zone files is disabled"; fi'
ExecStart=/usr/local/bind9/sbin/named -u named -c ${NAMEDCONF} $OPTIONS

ExecReload=/bin/sh -c '/usr/local/bind9/sbin/rndc reload > /dev/null 2>&1 || /bin/kill -HUP $MAINPID'

ExecStop=/bin/sh -c '/usr/local/bind9/sbin/rndc stop > /dev/null 2>&1 || /bin/kill -TERM $MAINPID'

PrivateTmp=true

[Install]
WantedBy=multi-user.target

```

```
systemctl status named
systemctl enable named
systemctl start named
systemctl stop named
```

## 配置检查
主配置检查
```
named-checkconf /etc/named/named.conf

```

zone配置检查
```
named-checkzone wxl.com /var/named/zone/wxl.com.zone
```

## 测试

主配置文件
```
vim named.conf

zone "test.com" IN {
  type master;
  file "zone/test.com.zone";
  allow-update { none; };
};
```

区域配置文件
```
vim /var/named/zone/test.com.zone

$TTL      86400
@     IN SOA      test.com root.test.com (
                                  42                ; serial (d. adams)
                                  3H                ; refresh
                                  15M               ; retry
                                  1W                ; expiry
                                  1D )              ; minimum
                IN NS           @
                IN A            127.0.0.1
                IN AAAA         ::1
www IN A 172.16.100.200
```

重启
```
systemctl restart named
```

解析测试
```
nslookup

> server 10.200.192.13
Default server: 10.200.192.13
Address: 10.200.192.13#53
> www.test.com
Server:		10.200.192.13
Address:	10.200.192.13#53

Name:	www.test.com
Address: 172.16.100.200
> exit

```

## 压测


```
yum install dnsperf
```
```
yum install -y epel-release
```

### Dnsperf 支持下面的这些命令行参数:
 -s    用来指定DNS服务器的IP地址，默认值是127.0.0.1
 -p    用来指定DNS服务器的端口，默认值是53
 -d    用来指定DNS消息的内容文件，该文件中包含要探测的域名和资源记录类型
 -t    用来指定每个请求的超时时间，默认值是3000ms
 -Q    用来指定本次压测的最大请求数，默认值是1000
 -c    用来指定并发探测数，默认值是100. dnsperf会从-d指定的文件中随机选取100个座位探测域名来发送DNS请求
 -l    用来指定本次压测的时间，默认值是无穷大
 -e    本选项通过EDNS0，在OPT资源记录中运用edns-client-subnet来指定真实的client ip
 -i    用来指定前后探测的时间间隔，因为dnsperf是一个压测工具，所以本选项目前还不支持
 -P    指定用哪个传输层协议发送DNS请求，udp或者tcp。默认值是udp
 -f    指定用什么地址类型发送DNS请求，inet或者inet6。默认值是inet
 -v    除了标准的输出外，还输出每个相应码的个数
 -h    打印帮助


```
vim domain.txt

www.test.com A
```

```
dnsperf -d domain.txt -s 10.200.88.202 -l 120


DNS Performance Testing Tool
Version 2.7.1

[Status] Command line: dnsperf -d domain.txt -s 10.200.88.202 -l 120
[Status] Sending queries (to 10.200.88.202:53)
[Status] Started at: Thu Feb 17 10:53:23 2022
[Status] Stopping after 120.000000 seconds
[Status] Testing complete (time limit)

Statistics:

  Queries sent:         8875078        ## 指本次探测发送的总请求数
  Queries completed:    8875078 (100.00%)     ## 本次探测收到响应的请求数
  Queries lost:         0 (0.00%)

  Response codes:       NOERROR 8875078 (100.00%)      ## 本次探测的成功率
  Average packet size:  request 30, response 46
  Run time (s):         120.001024
  Queries per second:   73958.352222      ## 本次探测的QPS

  Average Latency (s):  0.001242 (min 0.000503, max 0.003700)
  Latency StdDev (s):   0.000202

```


## rndc 

rndc（Remote Name Domain Controllerr）是一个远程管理bind的工具，通过这个工具可以在本地或者远程了解当前服务器的运行状况，也可以对服务器进行关闭、重载、刷新缓存、增加删除zone等操作。

使用rndc可以在不停止DNS服务器工作的情况进行数据的更新，使修改后的配置文件生效。在实际情况下，DNS服务器是非常繁忙的，任何短时间的停顿都会给用户的使用带来影响。因此，使用rndc工具可以使DNS服务器更好地为用户提供服务。在使用rndc管理bind前需要使用rndc生成一对密钥文件，一半保存于rndc的配置文件中，另一半保存于bind主配置文件中。rndc的配置文件为/etc/rndc.conf，在CentOS或者RHEL中，rndc的密钥保存在/etc/rndc.key文件中。rndc默认监听在953号端口（TCP），其实在bind9中rndc默认就是可以使用，不需要配置密钥文件。

rndc与DNS服务器实行连接时，需要通过数字证书进行认证，而不是传统的用户名/密码方式。在当前版本下，rndc和named都只支持HMAC-MD5认证算法，在通信两端使用预共享密钥。在当前版本的rndc 和 named中，唯一支持的认证算法是HMAC-MD5，在连接的两端使用共享密钥。它为命令请求和名字服务器的响应提供 TSIG类型的认证。所有经由通道发送的命令都必须被一个服务器所知道的 key_id 签名。为了生成双方都认可的密钥，可以使用rndc-confgen命令产生密钥和相应的配置，再把这些配置分别放入named.conf和rndc的配置文件rndc.conf中。


### 指令

|命令|解释|
|---|---|
|status |#显示bind服务器的工作状态|
|reload |#重新加载配置文件和区域文件|
|reload zone_name |#重新加载指定区域|
|reconfig   |#重读配置文件并加载新增的区域|
|querylog   |#关闭或开启查询日志   比较有用将查询日志写入named.conf log 字段定义的file 中|
|dumpdb |#将高速缓存转储到转储文件 (named_dump.db)|
|freeze    |#暂停更新所有动态zone|
|freeze zone [class [view]] |#暂停更新一个动态zone|
|flush [view]  |#刷新服务器的所有高速缓存|
|flushname name   |#为某一视图刷新服务器的高速缓存|
|stats   |#将服务器统计信息写入统计文件中   将统计信息写入statistics-file "/var/named/data/named_stats.txt";|
|stop   |#将暂挂更新保存到主文件并停止服务器|
|halt   |#停止服务器，但不保存暂挂更新|
|trace   |#打开debug, debug有级别的概念，每执行一次提升一次级别|
|trace LEVEL   |#指定 debug 的级别, trace 0 表示关闭debug|
|notrace |#将调试级别设置为 0|
|restart |#重新启动服务器（尚未实现）|
|addzone zone [class [view]] { zone-options } |#增加一个zone|
|delzone zone [class [view]] |#删除一个zone|
|tsig-delete keyname [view]  |#删除一个TSIG key|
|tsig-list  |#查询当前有效的TSIG列表|
|validation newstate [view]  |#开启/关闭dnssec|


**说明**：rndc命令后面可以跟  "-s"和 "-p" 选项连接到远程DNS服务器，以便对远程DNS服务器进行管理，但此时双方的密钥要一致才能正常连接。在设置rndc.conf时一定要注意key的名称和预共享密钥一定要和named.conf相同，否则rndc工具无法正常工作


在reload动态zone的时候，需要先freeze 再 reload

在zone配置中如果 allow-update 的值不是none，那么这个zone就是一个动态zone
如果没有填写 allow-update或者值为none，那么这个zone为静态static


动态zone 的记录保存在 _default.nzf 文件中

### 更新key

```
生成 key 文件
rndc-confgen -a

wrote key file "/etc/rndc.key"
```

```
rndc status

rndc: connection to remote host closed
This may indicate that
* the remote server is using an older version of the command protocol,
* this host is not authorized to connect,
* the clocks are not synchronized,
* the key signing algorithm is incorrect, or
* the key is invalid.

```

### 产生/etc/rndc.conf文件

```
rndc-confgen > /etc/rndc.conf  
```

### 配置 named.conf使用rndc秘钥
```
tail -10 /etc/named/rndc.conf | head -9 | sed s/#\ //g >> named.conf
```

```
cat /etc/named/named.conf 

key "rndc-key" {
    algorithm hmac-sha256;
    secret "1PX8tBVLFLrCcIhkcQ5r0t9hiPSihtakLkj3s2k3OeU=";
};

controls {
  inet 127.0.0.1 port 953
  allow { 127.0.0.1; } keys { "rndc-key"; };
};

```

### 测试 RNDC 设置
```
rndc status

version: BIND 9.16.12 (Stable Release) <id:aeb943d>
running on hz01-base-dns-01: Linux x86_64 3.10.0-1160.25.1.el7.x86_64 #1 SMP Wed Apr 28 21:49:45 UTC 2021
boot time: Thu, 03 Jun 2021 02:45:44 GMT
last configured: Thu, 03 Jun 2021 09:10:43 GMT
configuration file: /etc/named/named.conf
CPUs found: 4
worker threads: 4
UDP listeners per interface: 4
number of zones: 105 (99 automatic)
debug level: 0
xfers running: 0
xfers deferred: 0
soa queries in progress: 0
query logging is ON
recursive clients: 0/900/1000
tcp clients: 0/150
TCP high-water: 2
server is up and running
```


## nsupdate 

nsupdate工具是一个交互式的命令工具, 对应的区配置部分需要配置allow-update语句:  allow-update { any; };
```
zone "test.com" {
	type master;
	allow-update { any; };
	file "test.com.zone";
};
```

```
nsupdate

> server 127.0.0.1
> zone test.com
> update add xxx.test.com 300 A 3.3.3.3
> update detale  abc.test.com 300 A
> send
> show
> quit
```

### nsupdate 参数
-d 调试模式。
-k 从keyfile文件中读取密钥信息。
-y keyname是密钥的名称,secret是以base64编码的密钥。
-v 使用TCP协议进行nsupdate.默认是使用UDP协议。

命令格式:
server servername [ port ]
送请求到servername服务器的port端口.如果不指定servername,nsupdate将把请求发送给当前去的主DNS服务器.
如:
server 192.168.36.54 53

local address [ port ]           发送nsupdate请求时,使用的本地地址和端口.
zone zonename                    指定需要更新的区名.
class classname                 指定默认类别.默认的类别是IN.
key name secret                 指定所有更新使用的密钥.
prereq nxdomain domain-name               要求domain-name中不存在任何资源记录.
prereq yxdomain domain-name                 要求domain-name存在,并且至少包含有一条记录.
prereq nxrrset domain-name [ class ] type        要求domain-name中没有指定类别的资源记录.
prereq yxrrset domain-name [ class ] type   要求存在一条指定的资源记录.类别和domain-name必须存在.
update delete domain-name [ ttl ] [ class ] [ type [ data... ] ]     删除domain-name的资源记录.如果指定了type和data,仅删除匹配的记录.

update add domain-name ttl [ class ] type data…      添加一条资源记录.
show      显示自send命令后,所有的要求信息和更新请求.
send     将要求信息和更新请求发送到DNS服务器.等同于输入一个空行.



### 通过TSIG key实现nsupdate功能
```
1、使用` dnssec-keygen -a HMAC-MD5 -b 128 -n USER testkey `命令来生成密钥。
  dnssec-keygen：用来生成更新密钥。
    -a HMAC-MD5：采用HMAC-MD5加密算法。
    -b 128：生成的密钥长度为128位。
    -n USER testkey：密钥的用户名为testkey。

2、密钥生成后，会在当前目录下自动生成两个密钥文件***.+157+xxx.key和***.+157+xxx.private。
3、查看两个密钥文件的内容：
  cat ***.+157+xxx.key
  cat ***.+157+xxx.private
4、通过同样的方法生成test2key。
5、添加密钥信息到DNS主配置文件中 
6、将test.com区域中的allow-update { none; }中的"none"改成"key testkey";
  将"none"改成"key testkey"的意思是指明采用"key testkey"作为密钥的用户可以动态更新“t
```

例子:
```
view "view-test" in{
	match-clients{
		key testkey;
		acl1;
		};//keytestkey;以及acl1;
  zone"test.com"{
    type master;
    file "test.zone";
    allow-update{
        key testkey;
      };
	};
};
```

```
nsupdate 增删改查

server 192.168.0.49 53
删除
    删除NS记录
        update delete huiselantian.com  IN NS ns2.huiselantian.com.
        update delete huiselantian.com  IN NS ns3.huiselantian.com.
        update delete huiselantian.com  IN NS ns4.huiselantian.com.
        update delete huiselantian.com  IN NS ns5.huiselantian.com.
    删除A记录
        update delete ns2.huiselantian.com  A
        update delete ns3.huiselantian.com  A
        update delete ns4.huiselantian.com  A
        update delete ns5.huiselantian.com  A
增加
    增加NS记录
        update add huiselantian.com 600 IN NS ns2.huiselantian.com.
        update add huiselantian.com 600 IN NS ns3.huiselantian.com.
        update add huiselantian.com 600 IN NS ns4.huiselantian.com.    
    增加A记录
        update add ns3.huiselantian.com 600 IN A 192.168.0.236
        update add ns4.huiselantian.com 600 IN A 192.168.0.237
        update add ns5.huiselantian.com 600 IN A 192.168.1.125    
查询:
    查询NS记录
         dig NS @192.168.0.49 huiselantian.com 
    查询A记录
        dig A @192.168.0.49 ns1.huiselantian.com
    查询SOA记录
        dig SOA @192.168.0.49 huiselantian.com
改:
    先删除后新增
send
nsupdate处理ns的时候(如不规范,会报错)
    添加：
        先添加A 再添加NS记录 
    删除
        先删除ns 再删除A记录

```



## 监控
使用Prometheus监控bind9的DNS服务
[bind_exporter](https://github.com/prometheus-community/bind_exporter/releases)

### 下载
```
mkdir /opt/bind_exporter
cd /opt/bind_exporter

chmod +x bind_exporter
```

### systemctl server

```
vim /etc/systemd/system/bind_exporter.service

[Unit]
Description=bind_exporter
Documentation=https://github.com/digitalocean/bind_exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=named
Group=named
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/opt/bind_exporter/bind_exporter \
  --bind.pid-file=/run/named/named.pid \
  --bind.timeout=20s \
  --web.listen-address=0.0.0.0:9119 \
  --web.telemetry-path=/metrics \
  --bind.stats-url=http://localhost:8053/ \
  --bind.stats-groups=server,view,tasks

SyslogIdentifier=bind_exporter
Restart=always

[Install]
WantedBy=multi-user.target
```

### 启动
```
systemctl daemon-reload
systemctl restart bind_exporter.service
```

### 添加named 配置 
在` /etc/named/named.conf `中添加如下内容，注意"statistics-channels"是与"options"并列的，而不是位于"options"内部
```
statistics-channels {
  inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
};

options {
  ......
}
```
重新启动named

```
# 检查配置
named-checkconf /etc/named/named.conf

# 重启
systemctl restart named
```

检查
```
curl -v http://127.0.0.1:8053/xml/v3/server
```


### Prometheus  job

```
  - job_name: dns-master
    static_configs:
      - targets: ['10.85.6.66:9119']
        labels:
          alias: dns-master
```

[grafana 展示](https://grafana.com/grafana/dashboards/12309)

