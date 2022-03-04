---
title: centos7安装dnsmasq
date: 2022-03-04 14:04
categories:
- center7
tags:
- dns
- dnsmasq
---
  
  
摘要: desc
<!-- more -->



## 简述

Dnsmasq提供DNS缓存和DHCP服务、tftp服务功能。作为域名解析服务器(DNS)，Dnsmasq可以通过缓存DNS请求来提高对访问过的网址的连接速度。作为DHCP服务器，Dnsmasq可以为局域网电脑提供内网ip地址和路由。DNS和DHCP两个功能可以同时或分别单独实现。Dnsmasq轻量且易配置，适用于个人用户或少于50台主机的网络。此外它还自带了一个PXE服务器。


## DNSmasq 主要作用

1、将Dnsmasq作为本地DNS服务器使用，直接修改电脑的本地DNS的IP地址即可。

2、应对ISP的DNS劫持(反DNS劫持)，输入一个不存在的域名，正常的情况下浏览器是显示无法连接，DNS劫持会跳转到一个广告页面。先随便nslookup 一个不存在的域名，看看ISP商劫持的IP地址。

3、智能DNS加快解析速度，打开/etc/dnsmasq.conf文件，server=后面可以添加指定的DNS，例如国内外不同的网站使用不同的DNS。


## DNSmasq 原理

dnsmasq先去解析hosts文件， 再去解析`/etc/dnsmasq.d/`下的*.conf文件，并且这些文件的优先级要高于`dnsmasq.conf`，我们自定义的`resolv.dnsmasq.conf`中的DNS也被称为上游DNS，这是最后去查询解析的;

如果不想用hosts文件做解析，我们可以在/etc/dnsmasq.conf中加入no-hosts这条语句，这样的话就直接查询上游DNS了，如果我们不想做上游查询，就是不想做正常的解析，我们可以加入no-reslov这条语句。


## 安装

Linux 软件仓库已经提供了 DNSmasq,相关命令如下
```
yum -y install dnsmasq
```

dnsmasq 的配置文件在`/etc/dnsmasq.conf` ,这个配置文件包含大量的选项注释


## 配置

```
#上游服务器
resolv-file=/etc/dnsmasq.d/resolv.dnsmasq.conf

# 不允许 Dnsmasq 通过轮询 /etc/resolv.conf 或者其他文件来动态更新上游 DNS 服务列表
no-poll

# 默认情况下Dnsmasq会发送查询到它的任何上游DNS服务器上，如果取消注释，
# 则Dnsmasq则会严格按照/etc/resolv.conf中的DNS Server顺序进行查询。
strict-order

#不读取系统hosts，读取你设定的
no-hosts

#域名映射
addn-hosts=/etc/dnsmasq.d/dnsmasq.hosts

# 引入配置
# conf-file=/

# 引入配置目录,自动导入这个目录下的配置文件,星号表示包含，不加星号表示排除
# conf-dir=/etc/dnsmasq.d/,*.conf

#dnsmasq日志设置,谨慎启用，性能影响较大
# 开启debug模式，记录客户端查询记录到/var/log/debug中
#log-queries
#log-facility=/data/dnsmasq/dnsmasq.log
# 异步log，缓解阻塞
#log-async=20

#dnsmasq缓存设置,设置dns缓存大小,默认为150条
cache-size=4096
dns-forward-max=100000

#单设置127只为本机使用，加入本机IP为内部全网使用
listen-address=172.16.102.210,10.200.88.200

#智能DNS加快解析速度
#阿里云dns
#server=/qq.com/223.5.5.5
#国外域名dns
server=/google.com/223.5.5.5
#内部域名使用dns
#server=/ops.com/172.16.102.210
```


dnsmasq 语法检查
```
$ dnsmasq --test

dnsmasq: syntax check OK.
```


## dhcp
略 
## tftp
略
