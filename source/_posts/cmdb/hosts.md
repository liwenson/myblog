---
title: 主机管理设计
date: 2020-10-13 14:17
categories:
- cmdb
tags:
- cmdb
---
  
  
摘要: desc
<!-- more -->


创建数据库
```
CREATE DATABASE cmdb
use cmdb
```

idc表
CREATE TABLE `idc` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `location` varchar(128) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

|  字段   | 描述  |
|  ----  | ----  |
| id  | id |
| name  | 名称 |
| location | 位置 |


物理机表
server
CREATE TABLE `server_hw` (
  `id` int(11) NOT NULL AUTO_INCREMENT comment '物理机id',
  `hostname` varchar(128) NOT NULL  comment '主机名' ,
  `serial_num` varchar(128)   comment '序列号',
  `CPU` varchar(128)   comment 'CPU',
  `memory` varchar(58)   comment '内存',
  `disk` varchar(128)   comment '磁盘',
  `mg_ip` varchar(128)  comment '管理ip',
  `net_ip` varchar(128)  comment 'IP',
  `ops` varchar(128)  comment '操作系统',
  `asset_numb` varchar(128)  comment '资产编号',
  `location` varchar(128)  comment 'idc',
  `purchase_at` TIMESTAMP  comment '采购时间',
  `over_at` TIMESTAMP  comment '过保时间',
  `desc` varchar(128)  comment '描述',
  `guarantee_status` int(2)  comment '保修状态',
  `status` int(8)  comment '状态',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

| 字段 | 描 述 |  属性 | 参数 | 
|  ----  | ----  | ---- | ---- |
| id | id |  uuid | |
| hostname| 主机名 | str | |
| serial_num | 序列号 |  str | |
| CPU | CPU |  str | |
| memory | 内存 |  str | |
| disk | 磁盘 | dict | |
| net | 网卡 |  dict | |
| mg_ip | 管理ip |  str | |
| ops | 操作系统 |  str | |
| asset_numb | 资产编号 | str | |
| purchase_at | 采购时间 | time | |
| over_at| 过保时间 | time |  |
| desc | 备注 | str |  |
| guarantee_status | 保修状态 | bit | 0, 1|
| status | 状态 | bit | 0 , 1 , 2 , 3 |
| location | 位置 | int |  |


guarantee_status | 保修状态 | bit | 
0  在保
1  过保

status | 状态 | bit |
0 下架     000000
1 上架     000001
2 上线     000010
3 下线     000100
4 故障     001000

下架        000000
下架, 下线  000100
下架，故障  001000

上架        000001
上架，下线  000101
上架，故障  001001




虚拟机表
server_vm

CREATE TABLE `server_vm` (
  `id` int(11) NOT NULL AUTO_INCREMENT comment '虚拟机id',
  `hostname` varchar(128)   comment '主机名' ,
  `serial_num` varchar(128)   comment '序列号',
  `CPU` varchar(128)   comment 'CPU',
  `memory` varchar(58)   comment '内存',
  `disk` varchar(128)   comment '磁盘',
  `mg_ip` varchar(128)  comment '管理ip',
  `net_ip` varchar(128)  comment 'IP',
  `ops` varchar(128)  comment '操作系统',
  `asset_numb` varchar(128)  comment '资产编号',
  `location` int  comment '宿主机',
  `status` int  comment '状态',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;


| 字段 | 描 述 |  属性 | 参数 | 
|  ----  | ----  | ---- | ---- |
| id | id |  uuid | |
| hostname| 主机名 | str | |
| serial_num | 序列号 |  str | |
| CPU | CPU |  str | |
| memory | 内存 |  str | |
| disk | 磁盘 | dict | |
| mg_ip | 管理ip |  str | |
| net_ip | ip | dict | |
| ops | 操作系统 |  str | |
| asset_numb | 资产编号 | str | |
| desc | 备注 | str |  |
| location | 位置 | str | |



status : 
  200     成功
  204     失败


idc  crud 

/add    post 
{
  "name":"",
  "location":""
}


### 项目创建
```
mkdir gocmdb
cd gocmdb
go mod init gocmdb

mkdir -p conf middleware models pkg routers runtime
```

```
conf：         用于存储配置文件
middleware：   应用中间件
models：       应用数据库模型
pkg：          第三方包
routers        路由逻辑处理
runtime        应用运行时数据
datasource     数据库连接和初始化表
```

```
conf                配置文件
controllers         控制器 入参处理 api的入口
datasource          数据库配置 
models              结构体
db                  sql数据文件 postman接口文件
repo                数据库的操作
middleware          中间件 jwt实现
route               注册路由
service             业务逻辑代码
utils               工具类
config.json         配置文件的映射
main.go             主程序入口
```

## 计划

- cmdb
- java 应用监控
  <https://gitee.com/monitoring-platform/phoenix>
- 数据库托管平台
  <https://coolify.io/>
- dns web
- kafka 管理平台
  <https://github.com/didi/KnowStreaming>
- ConsulManager
  <https://github.com/starsliao/ConsulManager>
- ldap 管理平台
 <https://github.com/eryajf/go-ldap-admin>
- go-zero casbin
<https://learnku.com/articles/75158>

- Canonical maas 搭建
  模型即服务
  [安装文档](https://maas.io/docs/how-to-install-maas)
