---
title: 禁止通过ip访问nginx
date: 2021-08-13 11:18
categories:
- nginx
tags:
- nginx
---
	
	
摘要: 禁止通过ip+端口的方式访问nginx 的80 和443 端口
<!-- more -->


在nginx 配置文件中添加如下配置

Nginx 上对于 SSL 服务器在不配置证书的时候会出现协议错误，哪怕端口上配置了其他网站也会报错。解决方法就是随便生成一个证书填进去就好。

nginx.conf
```
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
        ssl_certificate /ztocwst/nginx/cert/fullchain1.pem;
        ssl_certificate_key /ztocwst/nginx/cert/privkey1.pem;
        ssl_session_timeout 5m;
        ssl_session_tickets on;
        ssl_stapling on;
        ssl_stapling_verify on;
        error_page 497  https://$host$request_uri;
        #SSL-END
    }
```