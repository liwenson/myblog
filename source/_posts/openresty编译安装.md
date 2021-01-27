---
title: openresty 编译安装
date: 2020-04-1 14:00:00
categories: 
- openresty
tags:
- linux
- nginx
---



### 环境安装

```
yum install pcre pcre-devel openssl-devel gcc curl
yum install GeoIP-devel GeoIP  -y
yum install gcc-c++ make gcc -y
yum install -y gcc gcc-c++ zlib-devel pcre-devel openssl-devel readline-devel
yum -y install gd-devel
```

### 下载安装包

```
cd /usr/loca/src
wget https://www.openssl.org/source/openssl-1.1.1f.tar.gz  下载最新版
wget https://openresty.org/download/openresty-1.15.8.3.tar.gz   下载最新版
wget https://github.com/vozlt/nginx-module-vts/archive/v0.1.18.tar.gz

tar xf openresty-1.15.8.3.tar.gz 
tar xf openssl-1.1.1f.tar.gz
tar xf v0.1.18.tar.gz
```



### 安装

```
cd openresty-1.15.8.3

./configure  --prefix=/usr/local/openresty  \
  --user=nobody  --group=nobody \
  --http-client-body-temp-path=client_temp  \
  --http-proxy-temp-path=proxy_temp \
  --http-fastcgi-temp-path=fastcgi_temp \
  --http-uwsgi-temp-path=uwsgi_temp  \
  --with-http_ssl_module \
  --with-http_gunzip_module     \
  --with-http_gzip_static_module    \
  --with-file-aio    \
  --with-openssl=/usr/local/src/openssl-1.1.1f    \
  --with-poll_module       \
  --with-http_geoip_module       \
  --with-http_sub_module      \
  --with-http_v2_module      \
  --with-pcre       \
  --with-stream    \
  --with-http_realip_module \
  --with-http_geoip_module --with-mail \
  --with-http_mp4_module  \
  --with-http_flv_module \
  --with-http_auth_request_module  \
  --with-http_realip_module  \
  --with-http_image_filter_module \
  --add-module=/usr/local/src/nginx-module-vts-0.1.18
  
 
 gmake -j `grep processor /proc/cpuinfo | wc -l` && make install
 
 
```



systemctl 管理文件

```
cat  <<EOF >> /usr/lib/systemd/system/nginx.service
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
```

### nginx 编译安装 错误

第一个错误 : `/configure: error: C compiler cc is not found `缺少gcc编译器。

```
yum -y install gcc-c++ autoconf automake
```

第二个错误：`/configure: error: the HTTP rewrite module requires the PCRE library.`确少PCRE库

```
yum   -y install pcre pcre-devel
```

 第三个错误：`./configure: error: the HTTP cache module requires md5 functions from OpenSSL library. You can either disable the module by using --without-http-cache option, or install the OpenSSL library into the system, or build the OpenSSL library statically from the source with nginx by using --with-http_ssl_module --with-openssl=<path> options. `缺少ssl错误。

```
yum -y install openssl openssl-devel
```

第四个错误：`./configure: error: the HTTP gzip module requires the zlib library. `缺少zlib库

```
yum install -y zlib-devel
```

第五个错误信息：`./configure: error: the HTTP XSLT module requires the libxml2/libxslt  `缺少libxml2

```
yum -y install libxml2 libxml2-dev && yum -y install libxslt-devel
```

第六个错误信息：`./configure: error: the HTTP image filter module requires the GD library. You can either do not enable the module or install the libraries.`

解决方法：http_image_filter_module是nginx提供的集成图片处理模块，需要gd-devel的支持

```
  yum -y install gd-devel
```

第七个错误信息：`./configure: error: perl module ExtUtils::Embed is required` 缺少ExtUtils

```
yum -y install perl-devel perl-ExtUtils-Embed
```

第八个错误信息：`./configure: error: the GeoIP module requires the GeoIP library. You can either do not enable the module or install the library. `缺少GeoIP

```
yum -y install GeoIP GeoIP-devel GeoIP-data
```





### nginx 开启 nginx-module-vts 监控

```
http {
    include       mime.types;
    default_type  application/octet-stream;
    vhost_traffic_status_zone;     
    vhost_traffic_status_filter_by_host on;
    #vhost_traffic_status_dump logs/vts.db;   #持久化数据
    
    server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm;
        }
        location /status {
            vhost_traffic_status_display;
            vhost_traffic_status_display_format html;
        }
    }
}

在浏览器打开   http://ip/status
```

```

打开vhost过滤：
vhost_traffic_status_filter_by_host on;
开启此功能，在Nginx配置有多个server_name的情况下，会根据不同的server_name进行流量的统计，否则默认会把流量全部计算到第一个server_name上。
在不想统计流量的server区域禁用vhost_traffic_status，配置示例：
server {
...
vhost_traffic_status off;
...
}
```



配置监控数据采集模块 nginx-vts-exporter

```
https://github.com/hnlq715/nginx-vts-exporter



nginx-vts-exporter-0.9.1.linux-amd64/nginx-vts-exporter -nginx.scrape_timeout 10 -nginx.scrape_uri http://127.0.0.1/status/format/json


nginx_vts_exporter的默认端口号：9913，对外暴露监控接口http://xxx:9913/metrics.
```

监控采集指标说明

```
nginx_server_requestMsec： 统计nginx，各个server请求转发的平均处理时间，精确到host
nginx_server_requests：统计nginx各个host 各个请求的总数，精确到状态码

```

nginx_server_bytes：统计nginx进出的字节计数可以精确到每个host，in进，out出

```

nginx_server_bytes{direction="in",host="*"} 466638
nginx_server_bytes{direction="in",host="127.0.0.1"} 21031
nginx_server_bytes{direction="in",host="9.56.39.66"} 445607
nginx_server_bytes{direction="out",host="*"} 8.089076e+06
nginx_server_bytes{direction="out",host="127.0.0.1"} 1.993122e+06
nginx_server_bytes{direction="out",host="9.56.39.66"} 6.095954e+06
```

nginx_server_cache：统计nginx缓存计算器，精确到每一种状态和转发type

```
nginx_server_cache{host="*",status="bypass"} 0
nginx_server_cache{host="*",status="expired"} 0
nginx_server_cache{host="*",status="hit"} 0
nginx_server_cache{host="*",status="miss"} 0
nginx_server_cache{host="*",status="revalidated"} 0
nginx_server_cache{host="*",status="scarce"} 0
nginx_server_cache{host="*",status="stale"} 0
nginx_server_cache{host="*",status="updating"} 0
nginx_server_cache{host="9.56.39.66",status="bypass"} 0
nginx_server_cache{host="9.56.39.66",status="expired"} 0
nginx_server_cache{host="9.56.39.66",status="hit"} 0
nginx_server_cache{host="9.56.39.66",status="miss"} 0
nginx_server_cache{host="9.56.39.66",status="revalidated"} 0
nginx_server_cache{host="9.56.39.66",status="scarce"} 0
nginx_server_cache{host="9.56.39.66",status="stale"} 0
nginx_server_cache{host="9.56.39.66",status="updating"} 0
```

nginx_server_connections： 统计nginx几种连接状态type的连接数

```
nginx_server_connections{status="accepted"} 98
nginx_server_connections{status="active"} 1
nginx_server_connections{status="handled"} 98
nginx_server_connections{status="reading"} 0
nginx_server_connections{status="requests"} 942
nginx_server_connections{status="waiting"} 0
nginx_server_connections{status="writing"} 1
```

nginx_server_requestMsec： 统计nginx，各个server请求转发的平均处理时间，精确到host 

```
nginx_server_requestMsec{host="*"} 0
nginx_server_requestMsec{host="127.0.0.1"} 0
nginx_server_requestMsec{host="9.56.39.66"} 0
```

nginx_server_requests：统计nginx各个host 各个请求的总数，精确到状态码

```
nginx_server_requests{code="1xx",host="*"} 0
nginx_server_requests{code="1xx",host="9.56.39.66"} 0
nginx_server_requests{code="2xx",host="*"} 940
nginx_server_requests{code="2xx",host="9.56.39.66"} 745
nginx_server_requests{code="3xx",host="*"} 0
nginx_server_requests{code="3xx",host="9.56.39.66"} 0
nginx_server_requests{code="4xx",host="*"} 1
nginx_server_requests{code="4xx",host="9.56.39.66"} 1
nginx_server_requests{code="5xx",host="*"} 0
nginx_server_requests{code="5xx",host="9.56.39.66"} 0
nginx_server_requests{code="total",host="*"} 941
nginx_server_requests{code="total",host="9.56.39.66"} 746
```

nginx_upstream_bytes： 统计nginx各个 upstream 分组的字节总数，细分到进出

```
nginx_upstream_bytes{direction="in",upstream="server_java_weixin"} 0
nginx_upstream_bytes{direction="out",upstream="server_java_weixin"} 0
```

nginx_upstream_requestMsec： 统计nginx 转发每个upstream中各个节点的请求的处理时间ms，不足1ms，会被标记为0

```
nginx_upstream_requestMsec{backend="9.56.39.66:8700",upstream="server_java_weixin"} 0
nginx_upstream_requestMsec{backend="9.56.39.66:8800",upstream="server_java_weixin"} 0
nginx_upstream_requestMsec{backend="9.56.39.66:8900",upstream="server_java_weixin"} 0
nginx_upstream_requestMsec{backend="9.56.39.66:8901",upstream="server_java_weixin"} 0
nginx_upstream_requestMsec{backend="9.56.39.66:8902",upstream="server_java_weixin"} 0
nginx_upstream_requestMsec{backend="9.56.39.66:8903",upstream="server_java_weixin"} 0
```

nginx_upstream_requests： 统计各个upstream 请求总数，精确到状态码

```
nginx_upstream_requests{code="1xx",upstream="server_java_weixin"} 0
nginx_upstream_requests{code="2xx",upstream="server_java_weixin"} 0
nginx_upstream_requests{code="3xx",upstream="server_java_weixin"} 0
nginx_upstream_requests{code="4xx",upstream="server_java_weixin"} 0
nginx_upstream_requests{code="5xx",upstream="server_java_weixin"} 0
nginx_upstream_requests{code="total",upstream="server_java_weixin"} 0
```

nginx_upstream_responseMsec：统计各个upstream 平均响应时长，精确到每个节点

```
nginx_upstream_responseMsec{backend="9.56.39.66:8700",upstream="server_java_weixin"} 293
nginx_upstream_responseMsec{backend="9.56.39.66:8800",upstream="server_java_weixin"} 293
nginx_upstream_responseMsec{backend="9.56.39.66:8900",upstream="server_java_weixin"} 292
nginx_upstream_responseMsec{backend="9.56.39.66:8901",upstream="server_java_weixin"} 297
nginx_upstream_responseMsec{backend="9.56.39.66:8902",upstream="server_java_weixin"} 295
nginx_upstream_responseMsec{backend="9.56.39.66:8903",upstream="server_java_weixin"} 296
```

