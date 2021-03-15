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

### 编译前环境准备 
下载bind9
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
```
cd /usr/local/src
wget https://downloads.isc.org/isc/bind9/9.16.12/bind-9.16.12.tar.xz
```

### 编译安装
安装依赖
```
yum install -y libuv libuv-devel pcre-devel zlib-devel gcc gcc-c++ autoconf automake make pcre-devel zlib-devel openssl-devel openldap-devel unixODBC-devel gcc libtool openssl  bind-utils python-pip
```
```
pip install ply
```
解压
```
cd /usr/local/src
tar -xvf bind-9.16.12.tar.xz
```
编译安装
```
cd bind-9.16.12
./configure --prefix=/usr/local/bind9 --sysconfdir=/etc/named/ --enable-largefile --with-tuning=large --with-openssl
```
```
make && make install
```

### 编译错误处理
错误一
```
configure: error: Python >= 2.7 or >= 3.2 and the PLY package are required for dnssec-keymgr and other Python-based tools. 
PLY may be available from your OS package manager as python-ply or python3-ply; it can also be installed via pip. To build without Python/PLY, use --without-python.
```
处理
执行pip install ply安装ply，安装前要确保此时setuptools和pip已经安装，如果未安装则需要单独安装。如果不安装ply模块，bind在编译时会报错如下。
```
pip install ply
```
错误二
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
错误三
```
configure: error: sys/capability.h header is required for Linux capabilities support. Either install libcap or use --disable-linux-caps.
```
处理
```
yum install libcap-devel
```


添加环境变量
```
vim /etc/profile.d/named.sh
export PATH=/usr/local/bind9/bin:/usr/local/bind9/sbin:$PATH

. /etc/profile.d/named.sh
```
导出库文件搜索路径
```
$ vim /etc/ld.so.conf.d/named.conf
/usr/local/bind9/lib
$ ldconfig -v
```

导出头文件搜索路径
```
$ ln -sv /usr/local/bind9/include /usr/include/named
"/usr/include/named" -> "/usr/local/bind9/include"
```

导出帮助文档搜索路径（非必须）
```
$ vim /etc/man.config 
MANPATH /usr/local/bind9/share/man
```



### 配置
#### 主配置
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
  max-cache-size 60%;

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

include "/etc/named/named.rfc1912.zones";
```

#### rndc配置
rndc是一个管理程序，可以用它来刷新配置，停止服务，强制同步等
```
rndc-confgen  > /etc/named/rndc.conf
```
打开rndc.conf文件，找到# Use with the following in named.conf, adjusting the allow list as needed:注释，复制其下所有行到named.conf并放开注释。

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

options {
  ...
};

logging {
  ...
};


zone "." IN { # 根
  type hint;
  file "named.ca";
};

include "/etc/named/named.rfc1912.zones";
```

#### zones 配置
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

#### 根区域配置
在联网的情况下直接将查询根的结果导入根区域配置文件，我们在named.rfc1912.zones文件中配置了根文件named.ca

```
mkdir -p /var/named/data
$ dig -t NS . > /var/named/named.ca
```

创建服务专用账户named，禁止本地登陆户
```
useradd -d /usr/local/bind9 -s /sbin/nologin named
```

接下来我们更改所有配置文件的用户为named用户
```
mkdir /run/named
chown -R named:named /usr/local/bind9/
chown -R named:named /etc/named
chown -R named:named /var/named
chown -R named:named /run/named
```
