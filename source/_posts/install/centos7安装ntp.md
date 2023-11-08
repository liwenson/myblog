---
title: centos7安装ntp
date: 2023-04-03 09:17
categories:
- cenots7
tags:
- ntp
---
  
  
摘要: desc
<!-- more -->

## 安装ntp

```
yum install ntp -y
```

## 配置上游ntp地址

查找当前地区，最适合的时间服务器 

[pool.ntp.org: NTP Servers in Asia, asia.pool.ntp.org ](https://www.pool.ntp.org/zone/asia)

复制最优的服务器地址

vim /etc/ntp.conf

```
server 0.asia.pool.ntp.org
server 1.asia.pool.ntp.org
server 2.asia.pool.ntp.org
server 3.asia.pool.ntp.org
```

启动服务
```
systemctl start ntpd 
systemctl enable ntpd.service        #设置开机启动服务
```

## 同步远程时间服务

```
ntpdate -q 2.asia.pool.ntp.org 3.asia.pool.ntp.org

server 212.138.72.43, stratum 3, offset 0.020799, delay 0.36508
server 5.189.141.35, stratum 2, offset 0.031922, delay 0.32562
server 103.130.217.41, stratum 2, offset -0.097812, delay 0.29593
server 212.26.18.43, stratum 3, offset -0.025376, delay 0.39539
server 194.186.237.38, stratum 2, offset -0.022392, delay 0.48201
 3 Apr 09:21:24 ntpdate[5019]: adjust time server 5.189.141.35 offset 0.031922 sec
```

## 验证服务

```
ntpq -p 

     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
+103.83.142.30   203.123.48.219   2 u   33   64   77  288.155   53.531   8.091
*ntp-b2.nict.go. .NICT.           1 u   42   64   77   75.637   -9.559   2.739
-230.subnet-8.he 103.28.56.14     3 u   39   64   77  227.696   71.319   8.525
+time.cloudflare 10.189.8.229     3 u   30   64   77  183.742   -3.892   2.903
```


查看当前时间：
```
date -R
```

同步硬件时间
```
hwclock -w 
```