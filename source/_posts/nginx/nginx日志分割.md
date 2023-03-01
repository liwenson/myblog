---
title: nginx 日志分割
date: 2023-02-28 11:32
categories:
- nginx
tags:
- log
---
  
  
摘要: desc
<!-- more -->

## 配置文件

```bash
cd nginx/conf

vim log_format.conf

#if ($time_iso8601 ~ "^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})") {
#    set $day $1$2$3;
#}

#access_log /ztocwst/nginx/logs/$server_name-$day.log main;

set $fmt_localtime '';
log_by_lua_block {
   ngx.var.fmt_localtime = ngx.today();
}


access_log /ztocwst/nginx/logs/$server_name-$fmt_localtime.log main;
```
