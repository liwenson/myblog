---
title: go 项目初始化
date: 2020-10-13 16:42
categories:
- go
tags:
- go
---
  
  
摘要: go项目初始化
<!-- more -->

### 项目创建
```
mkdir gocmdb
cd gocmdb
go mod init gocmdb


mkdir -p  {conf,middleware,models,pkg,routers,runtime,sql}    // unix
mkdir  conf,middleware,models,pkg,routers,runtime,sql    // windows
```

```
conf：         用于存储配置文件
middleware：   应用中间件
models：       应用数据库模型
logs:          运行日志
pkg：          第三方包
routers        路由逻辑处理
runtime        应用运行时数据
```




