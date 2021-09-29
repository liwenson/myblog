---
title: prometheus清除数据
date: 2021-05-17 18:10
categories:
- prometheus
tags:
- prome
---
  
  
摘要: prometheus 清除历史数据
<!-- more -->


## 开启管理时间序列的 API 
默认情况下，管理时间序列的 API 是被禁用的
```
 ./prometheus --storage.tsdb.retention=180d --web.enable-admin-api
```

## api 使用

### 清理某个key的全部的数据
```
curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]=up&match[]=mysql_global_status_threads_running{instance="test-db13:9104",job="mysql"}'
```

### 清理这个key指定时间段的数据 （清理的时间戳区间：1557903714 到 155790395 ）
```
curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?start=1557903714&end=1557903954&match[]=mysql_global_status_threads_running{instance="test-db13:9104",job="mysql"}'
```

### 删除某个标签匹配的数据
```
curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]={instance=".*"}'
```

### 删除某个指标数据
```
curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]={node_load1=".*"}'
```

### 清理db
```
curl -XPOST http://localhost:9090/api/v1/admin/tsdb/clean_tombstones
```

### 删除全部数据
```
curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]={__name__=~".+"}'
```

### 删除某个组下的所有数据
```
curl -X DELETE http://localhost:9090/metrics/job/pushgateway-microservice
```

