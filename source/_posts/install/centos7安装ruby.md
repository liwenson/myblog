---
title: centos7安装ruby
date: 2021-07-29 13:52
categories:
- linux
tags:
- ruby
---
	
	
摘要: centos7安装ruby
<!-- more -->


## 安装编译依赖工具
```
yum install gcc
yum install gcc-c++
yum install gdbm-devel
yum install readline-devel
yum install openssl-devel
```

## 编译安装ruby
```
cd /usr/local/ruby-2.7.0

./configure --prefix=/usr/local/ruby --enable-shared
make && make install
```

