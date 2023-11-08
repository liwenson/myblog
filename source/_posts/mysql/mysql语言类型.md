---
title: mysql语言分类
date: 2023-06-17 09:45
categories:
- mysql
tags:
- mysql
---
  
  
摘要: desc
<!-- more -->

## 五种语言分类

### DDL(Data Define Language) 数据定义语言

包括 CREATE、DROP、ALTER 等对数据库数据结构进行操作的语言
DDL不需要commit（DDL都是被隐式提交，不能对DDL语句使用ROLLBACK命令）


CREATE  - 创建表,在数据库创建对象
use - 使用
ALTER -  修改表,修改数据库结构
DROP  删除表,从数据库中删除对象
TRUNCATE  删除表中所有行（无法回退）
COMMENT 注释（为数据字典添加备注）
RENAME 重命名表


CREATE INDEX  创建索引
DROP INDEX 删除索引


#### 数据库操作

create — 创建
use - 使用
drop — 删除
alter — 修改
show — 查询
rename — 重命名
comment — 注释

#### 数据表操作

create — 创建
drop — 删除
alter — 修改
show — 查询
truncate — 清空表数据
rename — 重命名
comment — 注释


### DML(Data Manipulation Language) 数据操作语言

insert — 插入
delete — 删除
update — 更新
call —调用存储过程和函数
explain plan —执行计划
lock — 加锁
merge(SQL Server、Oracle数据库中可用) — 合并update、delete（oracle 10g新增）和insert语句

### DQL(Data Query Language) 数据查询语言

select — 查询

### DCL(Data Control Language) 数据控制语言

grant — 授权
revoke — 取消授权


### TCL(Transaction Control Language) 事务控制语言

commit — 提交数据
rollback — 回滚
savepoint — 设置回滚点
set transaction —设置隔离级别

