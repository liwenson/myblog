---
title: nginx  ssl 优化
date: 2022-02-23 11:37
categories:
- nginx
tags:
- ssl
---
  
  
摘要: nginx ssl优化
<!-- more -->

## 安装nginx

略

## 配置证书

略

## ssl优化

### 配置路径

```bash
mkdir -p /opt/nginx/params
```

### 生成 dhparam.pem

一般网站使用的SSL证书都是RSA证书，这种证书基本都是2048位的密钥，但是证书密钥交换密钥必须要比证书密钥更长才能安全，而默认的只有1024位，所以我们需要手动生成一个更强的密钥。

OpenSSL 的 dhparam 用于生成和管理 dh 文件。dh(Diffie-Hellman) 是著名的密钥交换协议，它可以保证通信双方安全地交换密钥。

使用如下命令生成一个 dhparam.pem 文件：

```bash
openssl dhparam -out /opt/nginx/params/dhparam.pem 2048
```

### SSL 参数

```bash
vim  ssl-params.conf
# ssl params setting
#

server_tokens   off;

ssl_session_cache        shared:SSL:10m;
ssl_session_timeout      60m;

ssl_session_tickets      on;

ssl_stapling             on;
ssl_stapling_verify      on;

resolver                 8.8.4.4 8.8.8.8  valid=300s;
resolver_timeout         10s;
ssl_prefer_server_ciphers on;

ssl_certificate          /etc/nginx/ssl/fullchain.cer;
ssl_certificate_key      /etc/nginx/ssl/godruoyi.key;

ssl_dhparam              /etc/nginx/ssl/dhparams.pem;
ssl_protocols            TLSv1 TLSv1.1 TLSv1.2;

ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";

add_header Strict-Transport-Security "max-age=31536000;includeSubDomains;preload";
add_header  X-Content-Type-Options  nosniff;
add_header x-xss-protection "1; mode=block";
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob: https:; connect-src 'self' https:; img-src 'self' data: https: blob:; style-src 'unsafe-inline' https:; font-src https:";
```

通用参数

```txt
ssl_protocols: 加密协议;
ssl_ciphers: 加密算法;
ssl_dhparam: DH交换秘钥文件位置
ssl_prefer_server_ciphers: 服务端加密算法优先;
ssl_session_cache: 会话缓存;
ssl_session_timeout: 用户会话缓存失效时间，对安全性有高要求的站点需要降低该值;
ssl_stapling: 启用 OCSP 可减少用户验证证书的时间;
ssl_session_tickets: 为复用会话创建或加载Ticket Key.
ssl_certificate:  证书
ssl_certificate_key: 证书私钥
```
