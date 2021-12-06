---
title: centos7 普通用户下安装nginx
date: 2021-09-28 15:21
categories:
- centos7
tags:
- nginx
---
	
	
摘要: centos7 普通用户下安装nginx
<!-- more -->

## 依赖包依然需要离线下载 

### 下载nginx
```
http://nginx.org/en/download.html
```
### zlib下载地址：  
```
http://www.zlib.net/
```

### prce下载地址
注意别下pcre2
```
ftp://ftp.pcre.org/pub/pcre/
```

### openssl下载地址
```
http://www.openssl.org
```

## 安装
```
mkdir soft
mkdir apps

mv *.gz soft 
```
### 解压安装 pcre 
```
tar xf pcre-8.45.tar.gz
cd pcre-8.45
./configure --prefix=/home/baseuser/apps/pcre
make && make install
```

### 解压安装 zlib
```
tar xf zlib-1.2.11.tar.gz
cd zlib-1.2.11
./configure --prefix=/home/baseuser/apps/zlib
make && make install
```
### nginx
两个依赖都装好后，可以开始正式的nginx编译前检查

```
tar xf nginx-1.20.1.tar.gz
cd nginx-1.20.1/
./configure --prefix=/home/baseuser/apps/nginx --with-http_stub_status_module --with-pcre=/home/baseuser/soft/pcre-8.45 --with-zlib=/home/baseuser/soft/zlib-1.2.11

检查ok，编译和安装一般没问题：

make && make install
```

## 启动
```
cd /home/baseuser/apps/nginx/sbin
sbin/nginx 

nginx: [emerg] bind() to 0.0.0.0:80 failed (13: Permission denied)
　　报错原因：在linux下，普通用户只能用1024以上的端口，而1024以内的端口只能由root用户才可以使用，所以这里80端口只能由root才能使用。
```






