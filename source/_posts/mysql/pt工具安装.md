---
title: pt 工具使用
date: 2023-06-28 19:26
categories:
- mysql
tags:
- pt
- Percona Toolkit
---
  
  
摘要: desc
<!-- more -->

Percona Toolkit 简称 pt 工具，是 Percona 公司开发用于管理 MySQL 的工具，里面有很多实用多脚本，可提高 DBA 的工作效率亦或是降低数据库运维风险。

[官网地址](https://www.percona.com/downloads/percona-toolkit/LATEST/)

## 下载并安装

```
wget -c  install https://www.percona.com/downloads/percona-toolkit/3.0.1/binary/redhat/7/x86_64/percona-toolkit-3.0.1-1.el7.x86_64.rpm


yum install percona-toolkit-3.0.1-1.el7.x86_64.rpm

wget -O https://downloads.percona.com/downloads/percona-toolkit/3.5.3/binary/redhat/7/x86_64/percona-toolkit-3.5.3-1.el7.x86_64.rpm

yum install percona-toolkit-3.5.3-1.el7.x86_64.rpm

```