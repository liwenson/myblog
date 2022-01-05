---
title: centos7使用clamav扫描挖矿
date: 2021-02-01 10:38
categories:
- centos7
tags:
- clamav
---
  
  
摘要: 记录一次centos7扫描挖矿病毒
<!-- more -->


## 安装clamav
#### 1、下载clamav源码包
```
#下载地址
http://www.clamav.net/downloads

cd /usr/local/src/
wget https://clamav-site.s3.amazonaws.com/production/release_files/files/000/000/584/original/clamav-0.103.0.tar.gz?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIY6OSGQFGUNJQ7GQ%2F20210201%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20210201T023706Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=6aeefb9c748ac872bb11732317913ac36ffb4204f32886bda0f1154d897f1a1e
```
#### 2、安装编译依赖
```
yum install gcc-c++ openssl openssl-devel -y
yum install bzip2-devel -y
```
#### 3、编译clamav
```
cd /usr/local/src/
tar xf clamav-0.103.0.tar.gz
cd clamav-0.103.0
./configure --prefix=/usr/local/clamav-103  --sysconfdir=/etc
# 将clamav安装到 /usr/local/clamav-0.103.0 将配置文件放到 /etc 目录
```
```
...
config.status: executing libtool commands
configure: Summary of detected features follows
              OS          : linux-gnu
              pthreads    : yes (-lpthread)
configure: Summary of miscellaneous features
              check       : no (auto)
              fanotify    : yes
              fdpassing   : 1
              IPv6        : yes
              openssl     : /usr
              libcurl     : /usr
configure: Summary of optional tools
              clamdtop    : no (missing ncurses / pdcurses) (disabled)
              milter      : no (missing libmilter) (disabled)
              clamsubmit  : no (missing libjson-c-dev. Use the website to submit FPs/FNs.) (disabled)
              clamonacc   : yes (auto)
configure: Summary of engine performance features
              release mode: yes
              llvm        : no (disabled)
              mempool     : yes
configure: Summary of engine detection features
              iconv       : yes
              bzip2       : ok
              zlib        : yes (from system)
              unrar       : yes
              preclass    : no (missing libjson-c-dev) (disabled)
              pcre        : /usr
              libmspack   : yes (Internal)
              libxml2     : no
              yara        : yes
              fts         : yes (internal, libc's is not LFS compatible)

```
#### 4、安装
```
make -j4 && make check && make install
```

### 配置clamav
#### 创建软连接
```
ln -s /usr/local/clamav-103/bin/* /usr/local/bin/
ln -s /usr/local/clamav-103/sbin/* /usr/local/sbin/
```
#### 创建相关文件
```
cd /usr/local/clamav-103
mkdir logs updata
mkdir /var/lib/clamav
cd logs
touch clamd.log freshclam.log
```

#### 修改配置文件
```
cd /etc
cp clamd.conf.sample clamd.conf
cp freshclam.conf.sample freshclam.conf

cat >> clamd.conf <<-eof
LocalSocket /usr/local/clamav-103/clamd.socket
PidFile /usr/local/clamav-103/updata/clamd.pid
DatabaseDirectory /usr/local/clamav-103/updata
LogFile /usr/local/clamav-103/logs/clamd.log
eof

cat >> freshclam.conf <<-eof
DatabaseDirectory /usr/local/clamav-103/updata
UpdateLogFile /usr/local/clamav-103/logs/freshclam.log
PidFile /var/lib/clamav/freshclam.pid
eof

```
将 Example 进行注释
```
cd /etc
sed -i 's/Example/#Example/g' clamd.conf freshclam.conf
grep -n "#Example" clamd.conf freshclam.conf
```

#### 创建clamav用户并授权
```
useradd -M -s /sbin/nologin clamav
chown -R clamav:clamav /usr/local/clamav-103
chown -R clamav:clamav /var/lib/clamav
```



### 启动clamd

##### systemd 
```
vim /usr/lib/systemd/system/clam-freshclam.service

# Run the freshclam as daemon
[Unit]
Description = freshclam scanner
After = network.target

[Service]
Type = forking
ExecStart = /usr/local/clamav-103/bin/freshclam -d -c 4
Restart = on-failure
PrivateTmp = true

[Install]
WantedBy=multi-user.target

```

```
sudo systemctl enable clam-freshclam.service
sudo systemctl start clam-freshclam.service
sudo systemctl status clam-freshclam.service
```


##### 更新病毒库
```
freshclam   #如果下载慢,使用 错误二中的地址手动下载放入到病毒库目录中
```

```
clamd start   # 如果报错，提示 'LibClamAV Error: cl_load(): No such file or directory:' 参数错误二
```

### 使用clamav

参数说明
```
-r    递归扫描子文件
–i    只显示被感染的文件
-l    指定日志文件
--remove    删除被感染文件
--move    隔离被感染文件
```

使用示例
```
clamscan -ri / -l clamscan.log  --remove   #这里递归扫描根目录 / ，发现感染文件立即删除
```


| 选项                     | 适用的文件类型                  | 执行命令示例                      |
| ------------------------ | ------------------------------- | --------------------------------- |
| -r                       | 所有文件                        | clamscan -r                       |
| --unrar                  | .rar 文件                       | clamscan --unrar                  |
| --arj                    | .arj 文件                       | clamscan --arj                    |
| --unzoo                  | .zoo 文件                       | clamscan --unzoo                  |
| --lha                    | .lzh 文件                       | clamscan --lha                    |
| --jar                    | .jar 文件                       | clamscan --jar                    |
| --deb                    | .deb 安装包                     | clamscan --deb                    |
| --tar                    | .tar 文件                       | clamscan --tar                    |
| --tgz                    | .tar.gz                         | clamscan --tgz                    |
| --log=FILE/-l FILE       | 增加扫描日志                    | clamscan -l /var/log/clamscan.log |
| --move=directory         | 把病毒文件移动到目录directory下 | clamscan --move /tmp              |
| --copy=directory         | 把病毒文件复制到目录directory下 | clamscan --copy /tmp              |
| --remove                 | 删除病毒文件                    | clamscan --move /abc              |
| --quiet                  | 输出错误消息                    | clamscan --quiet                  |
| --infected/-i            | 输出感染文件                    | clamscan -i                       |
| --suppress-ok-results/-o | 跳过扫描OK的文件                | clamscan -o                       |
| –-no-summary             | 不显示统计信息 (只显示找到的病毒信息)    |                              |
| --bell                   | 扫描到病毒文件发出警报声音      |                                   |
| --unzip(unrar)           |  解压压缩文件扫描              |                                   |


```
----------- SCAN SUMMARY -----------
Known viruses: 6490986
Engine version: 0.99.4
Scanned directories: 20172
Scanned files: 72378
Infected files: 0       # 被感染的文件数
Total errors: 23809
Data scanned: 4067.18 MB
Data read: 4244.65 MB (ratio 0.96:1) 
Time: 1343.190 sec (22 m 23 s)

```

### 检查配置文件
```
./clamconf -n


Checking configuration files in /etc

Config file: clamd.conf
-----------------------
LogFile = "/usr/local/clamav-103/logs/clamd.log"
PidFile = "/usr/local/clamav-103/updata/clamd.pid"
DatabaseDirectory = "/usr/local/clamav-103/updata"
LocalSocket = "/usr/local/clamav-103/clamd.socket"

Config file: freshclam.conf
---------------------------
PidFile = "/usr/local/clamav-103/updata/freshclam.pid"
DatabaseDirectory = "/usr/local/clamav-103/updata"
UpdateLogFile = "/usr/local/clamav-103/logs/freshclam.log"
DatabaseMirror = "database.clamav.net"

clamav-milter.conf not found

Software settings
-----------------
Version: 0.103.0
Optional features supported: MEMPOOL IPv6 AUTOIT_EA06 PCRE ICONV RAR 

Database information
--------------------
Database directory: /usr/local/clamav-103/updata
main.cvd: version 62, sigs: 6647427, built on Thu Sep 16 20:32:42 2021
daily.cvd: version 26384, sigs: 1950259, built on Sun Dec 12 17:24:43 2021
bytecode.cvd: version 333, sigs: 92, built on Mon Mar  8 23:21:51 2021
Total number of signatures: 8597778

Platform information
--------------------
uname: Linux 3.10.0-862.11.6.el7.x86_64 #1 SMP Tue Aug 14 21:49:04 UTC 2018 x86_64
OS: linux-gnu, ARCH: x86_64, CPU: x86_64
zlib version: 1.2.7 (1.2.7), compile flags: a9
platform id: 0x0a2179790800000000040805

Build information
-----------------
GNU C: 4.8.5 20150623 (Red Hat 4.8.5-44) (4.8.5)
CPPFLAGS: 
CFLAGS: -g -O2 -fno-strict-aliasing  -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64
CXXFLAGS: -g -O2
LDFLAGS: 
Configure: '--prefix=/usr/local/clamav-103' '--sysconfdir=/etc' --enable-ltdl-convenience
sizeof(void*) = 8
Engine flevel: 121, dconf: 121

```


### 报错处理
错误一
```
...
checking for ncurses/ncurses.h... no
configure: unable to compile/link with ncurses
checking ncurses.h usability... no
checking ncurses.h presence... no
checking for ncurses.h... no
configure: unable to compile/link with ncurses
checking curses.h usability... no
checking curses.h presence... no
checking for curses.h... no
configure: unable to compile/link with pdcurses
configure: WARNING: ****** not building clamdtop: ncurses not found
checking for llvm-config... no
checking LFS safe fts implementation... no
checking for libcurl installation... configure: error: libcurl not found. libcurl (e.g. libcurl-devel) is required in order to build freshclam and clamsubmit.
```
处理
```
yum install libcurl-devel -y
```

错误二
```
clamd start
LibClamAV Error: cli_loaddbdir(): No supported database files found in /usr/local/clamav-103/updata
ERROR: Can't open file or directory
```
处理
```
原因分析
原因：没有病毒库！
yum安装的ClamAv，病毒库默认路径是:
/var/lib/clamav

源码安装时，默认的病毒库路径是:
/usr/local/share/clamav

而我在/etc/clamav.conf 中配的是 /usr/local/clamav-103/updata
下载病毒库时，由于使用"freshclam"命令下载太慢，换成了wget的方式手动下载病毒库，如下:
cd /usr/local/clamav-103/updata
wget http://database.clamav.net/main.cvd
wget http://database.clamav.net/daily.cvd
wget http://database.clamav.net/bytecode.cvd
```

错误三
```
LibClamAV Warning: fmap_readpage: pread fail: asked for 4077 bytes @ offset 19, got 0
```
解决方法：
扫描/sys/会产生大量报错,跳过此文件夹即可
-i 代表只报出infected的文件
-r 代表子文件夹也要扫描,/就是根目录了
```
clamscan --exclude-dir=/sys/ -i -r /
```

错误四
```
LibClamAV Warning: cli_scanbzip: bzip2 support not compiled in
```
解决方法
```
yum install bzip2-devel

之后，卸载并重新安装 ClamAV
```