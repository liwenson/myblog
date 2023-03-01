---
title: nginx黑名单
date: 2023-02-28 11:34
categories:
- nginx
tags:
- lua
---
  
  
摘要: nginx 黑名单
<!-- more -->

## nginx通lua实现黑名单

```lua
-- 日志文件路径
local logfile='/ztocwst/nginx/lua/lua.log'
--local logfile='lua.log'
-- 黑名单路径
local blacklist='/ztocwst/nginx/lua/ips.txt'
--local blacklist='ips.txt'
-- 当前时间
local dateNow=os.date("%Y-%m-%d %H:%M:%S")
-- 域名
local host=ngx.var.http_host
--获取IP地址
local ip = ngx.var.HTTP_X_FORWARDED_FOR
if ip == nil then
  ip = ngx.var.remote_addr
end
--取出ip 第一组
local _,comma_index=string.find(ip,",",plain)
if comma_index ~= nil then
    ip=string.sub(ip,1,comma_index-1)
end

if ip == nil then
  ip = ngx.var.remote_addr
  ngx.log(ngx.ERR, "error log "..ip)
end


-- 日志写入函数
local function outLog(fileName,content)
  local f = assert(io.open(fileName,'a'))
  f:write(content)
  f:close()
end

local tag=nil
-- 禁止名单中的ip访问
local f = io.open(blacklist, "r")
local ctx = f:read("*all")
f:close()


local a,b
a = string.find(ctx, "#"..ip)
if a ~= nil then
  goto NOTHING
end

b = string.find(ctx, ip)
if b ~= nil then
  outLog(logfile,dateNow.." 禁止访问--> "..host.."  "..ip.."\n")
  tag=false
end


if tag == false then
  ngx.exit(491)
end

-- 结束标记
::NOTHING::

```

黑名单文件，一行一个ip允许使用#注释

```bash
vim ips.txt
```
