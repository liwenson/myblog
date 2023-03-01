---
title: nginx 基础防护
date: 2022-09-27 16:11
categories:
- nginx
tags:
- nginx
---
  
  
摘要: nginx 基础防护
<!-- more -->

## 配置nginx基础防护

```bash
cd /etc/nginx/config   # nginx
或者
cd /usr/local/openresty/nginx/config  # openresty
```

```nginx
vim safe.conf

# 黑名单  黑名单脚本
#access_by_lua_file "/data/nginx/lua/blacklist.lua";

#
#if ( $request_method !~* GET|POST|DELETE|UPDATE) { 
#    return 444; 
#}

# 禁止空host 请求
set $block_host_null 0;
if ( $host = '' ) {
    set $block_host_null 1;
}
if ( $http_host = '' ) {
}
if ( $host != $server_name ) {
    set $block_host_null 1;
}

if ( $block_host_null = 1 ) {
    return 441;
}

# 禁SQL注入 Block SQL injections
set $block_sql_injections 0;
if ($query_string ~ "[;'<>].*") {
    set $block_sql_injections 1;
}

if ($query_string ~ "(cost\()|(concat\().*") {
    set $block_sql_injections 1;
}
if ($query_string ~ "[+|(%20)]union[+|(%20)]") {
    set $block_sql_injections 1;
}
if ($query_string ~ "[+|(%20)]and[+|(%20)]") {
    set $block_sql_injections 1;
}
if ($query_string ~ "[+|(%20)]select[+|(%20)]") {
    set $block_sql_injections 1;
}
if ($query_string ~ "[+|(%20)]delete[+|(%20)]") {
    set $block_sql_injections 1;
}
###
if ($query_string ~ "union.*select.*(.*)") {
    set $block_sql_injections 1;
}

if ($request_uri ~* "select((/\*+/)|[+ ]+|(%20)+)") {
    set $block_sql_injections 1;
}

if ($request_uri ~* "union((/\*+/)|[+ ]+|(%20)+)") {
    set $block_sql_injections 1;
}

if ($request_uri ~* "order((/\*+/)|[+ ]+|(%20)+)by") {
    set $block_sql_injections 1;
}

#匹配"group/**/by", "group+by", "group by"
if ($request_uri ~* "group((/\*+/)|[+ ]+|(%20)+)by") {
    set $block_sql_injections 1;
}

#  
if ($request_uri ~* "group((/\*+/)|[+ ]+|(%20)+)by") {
    set $block_sql_injections 1;
}

#if ($document_uri ~* "(insert|select|delete|update|count|master|truncate|declare|exec|\*|\')(.*)$") {
#    set $block_sql_injections 1;
#}

if ($block_sql_injections = 1) {
    return 442;
}

# 屏蔽url中的字符
set $block_url_injections 0;
if ($document_uri  ~* "/(.*)/\.\.\/(.*)") {
    set $block_url_injections 1;
}

if ($document_uri  ~* "/(.*)\/..%2f..(.*)") {
    set $block_url_injections 1;
}

if ($block_url_injections = 1) {
    return 443;
}

# 根据后缀名屏蔽掉 
if ( $document_uri ~* "\.(php|asp|aspx|jsp|swp|git|env|yaml|yml|sql|db|bak|ini|docx|doc|rar|tar|gz|log)$" ) {
    return 444;
}

# 禁掉文件注入
set $block_file_injections 0;
if ($query_string ~ "[a-zA-Z0-9_]=http://") {
    set $block_file_injections 1;
}

if ($query_string ~ "[a-zA-Z0-9_]=(..//?)+") {
    set $block_file_injections 1;
}

if ($query_string ~ "[a-zA-Z0-9_]=/([a-z0-9_.]//?)+") {
    set $block_file_injections 1;
}

if ($block_file_injections = 1) {
    return 445;
}

# 禁掉溢出攻击
set $block_common_exploits 0;
if ($query_string ~ "(<|%3C).*script.*(>|%3E)") {
    set $block_common_exploits 1;
}

if ($query_string ~ "GLOBALS(=|[|%[0-9A-Z]{0,2})") {
    set $block_common_exploits 1;
}

if ($query_string ~ "_REQUEST(=|[|%[0-9A-Z]{0,2})") {
    set $block_common_exploits 1;
}

if ($query_string ~ "proc/self/environ") {
    set $block_common_exploits 1;
}

if ($query_string ~ "mosConfig_[a-zA-Z_]{1,21}(=|%3D)") {
    set $block_common_exploits 1;
}

if ($query_string ~ "base64_(en|de)code(.*)") {
    set $block_common_exploits 1;
}

if ($block_common_exploits = 1) {
    return 446;
}

# 禁spam字段
set $block_spam 0;
if ($query_string ~ "b(ultram|unicauca|valium|viagra|vicodin|xanax|ypxaieo)b") {
    set $block_spam 1;
}

if ($query_string ~ "b(erections|hoodia|huronriveracres|impotence|levitra|libido)b") {
    set $block_spam 1;
}

if ($query_string ~ "b(ambien|bluespill|cialis|cocaine|ejaculation|erectile)b") {
    set $block_spam 1;
}

if ($query_string ~ "b(lipitor|phentermin|pro[sz]ac|sandyauer|tramadol|troyhamby)b") {
    set $block_spam 1;
}

if ($block_spam = 1) {
    return 447;
}

# 禁掉user-agents
set $block_user_agents 0;

#禁止agent为空
if ($http_user_agent ~ ^$) {
    set $block_user_agents 1;
}

# Don’t disable wget if you need it to run cron jobs!
if ($http_user_agent ~ "Wget") {
    set $block_user_agents 1;
}

# Disable Akeeba Remote Control 2.5 and earlier
if ($http_user_agent ~ "Indy Library") {
    set $block_user_agents 1;
}

# Common bandwidth hoggers and hacking tools.
if ($http_user_agent ~ "libwww-perl") {
    set $block_user_agents 1;
}

if ($http_user_agent ~ "GetRight") {
    set $block_user_agents 1;
}

if ($http_user_agent ~ "GetWeb!") {
    set $block_user_agents 1;
}

if ($http_user_agent ~ "Go!Zilla") {
    set $block_user_agents 1;
}

if ($http_user_agent ~ "Download Demon") {
    set $block_user_agents 1;
}

if ($http_user_agent ~ "Go-Ahead-Got-It") {
    set $block_user_agents 1;
}

if ($http_user_agent ~ "TurnitinBot") {
    set $block_user_agents 1;
}

if ($http_user_agent ~ "GrabNet") {
    set $block_user_agents 1;
}

if ($block_user_agents = 1) {
    return 448;
}

#spider
set $spider '2';
if ( $http_user_agent ~ .+Baiduspider.+ ){
    set $spider '0';
}

if ( $http_user_agent ~ .+Googlebot.+){
    set $spider '0';
}

if ( $http_user_agent ~ .+bingbot.+){
    set $spider '0';
}

if ( $http_user_agent ~ .+JikeSpider.+){
    set $spider '0';
}

if ( $http_user_agent ~ .+YoudaoBot.+){
    set $spider '0';
}

if ( $http_user_agent ~ .+Sosospider.+){
    set $spider '0';
}

if ( $http_user_agent ~ Yahoo!.+){
    set $spider '0';
}

if ( $http_user_agent ~ Sogou.+){
    set $spider '0';
}

if ( $http_user_agent ~ .+msnbot.+){
    set $spider '0';
}

if ( $http_user_agent ~ .+YandexBot.+){
    set $spider '0';
}

if ( $http_user_agent ~ .+Spider.+){
    set $spider '0';
}

if ( $http_user_agent ~ YisouSpider){
    set $spider '1';
}

#if ( $http_user_agent ~ LBBROWSER){
#	set $spider '1';
#}
if ( $spider = '1' ) {
    return 449;
}

```

在需要防护的域名下，引入

```txt
# 安全配置
include safe.conf;
```

## nginx禁用ip访问

```nginx
vim nginx.conf

    server {
        listen 80 default;
        listen 443 default_server;
        server_name _;
        return 403;

        #SSL-START SSL相关配置，请勿删除或修改下一行带注释的404规则
        #error_page 404/404.html;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
        ssl_session_cache builtin:1000 shared:SSL:10m;
        resolver 8.8.8.8 8.8.4.4 valid=300s;
        resolver_timeout 5s;
        ssl_prefer_server_ciphers on;
        ssl_certificate /data/nginx/cert/data-com.pem;
        ssl_certificate_key /data/nginx/cert/data-com.key;
        ssl_session_timeout 5m;
        ssl_session_tickets on;
        ssl_stapling on;
        ssl_stapling_verify on;
        error_page 497  https://$host$request_uri;
        #SSL-END
    }

```

## nginx 日志分割

`openresty` 日期获取不到的频率会低很多

```nginx
vim log_format.conf


set $fmt_localtime '';
log_by_lua_block {
   ngx.var.fmt_localtime = ngx.today();
}

access_log /data/nginx/logs/$server_name-$fmt_localtime.log main;
```

引入日志配置

```txt
# 日志配置
include log_format.conf;
```

---

`nginx`  有时日期获取不到

```nginx
# 在配置中添加

if ($time_iso8601 ~ "^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})") {
    set $day $1$2$3;
}

access_log /data/nginx/logs/$server_name-$day.log main;
```
