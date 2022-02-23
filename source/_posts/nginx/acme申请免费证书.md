---
title: acme 申请免费证书
date: 2022-02-22 14:33
categories:
- nginx
tags:
- acme
- ssl
---
  
  
摘要: acme 申请免费证书
<!-- more -->


## 说明
acme 脚本默认 CA 为 ZeroSSL

ZeroSSL 经常要等很久而且还会各种失败
通过命令修改默认 CA 为  letsencrypt
```
acme.sh --set-default-ca  --server letsencrypt
```

## 安装

### 安装依赖工具
```
yum install curl socat  -y
```

### 安装acme
1、脚本安装
```
curl  https://get.acme.sh | sh
```

2、源码安装
```
git clone https://github.com/acmesh-official/acme.sh.git
cd ./acme.sh 
./acme.sh --install -m my@example.com
```
邮箱可以关联到已有的zeroSSL账号。关联成功后，通过acme.sh生成的zeroSSL证书会在zeroSSL网站的控制面板上显示


### 高级安装

仅做参考，会导致未知错误
```
[ ! -d /srv/www/ssl/ ] ; mkdir -p /srv/www/ssl
git clone https://github.com/Neilpang/acme.sh.git
cd acme.sh
./acme.sh --install  \
--home ~/.acme.sh \
--config-home ~/.acme.sh/data \
--certhome  /srv/www/ssl \
--accountemail  "admin@lvmoo.com" \
--accountkey  /srv/www/ssl/myaccount.key \
--accountconf /srv/www/ssl/myaccount.conf \
--useragent  "this is my client."
```




## 签证

acme.sh 实现了 acme 协议支持的所有验证协议，一般有 HTTP 方式、手动 DNS 方式和 DNS API 方式。由于泛域名证书的解析目前仅支持 DNS 方式验证，下面我们将通过 DNS 方式来验证你的域名所有权。


### 使用手动DNS 验证，

**dns 手动模式不能自动更新证书，需要手动去添加TXT 记录来验证更新证书**

```
acme.sh --issue -d example.com -d "*.example.com" --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please --insecure
```

不加 --insecure 会报错
```
Please refer to https://curl.haxx.se/libcurl/c/libcurl-errors.html for error code: 60
```

网络故障，无法访问到github
```
Please refer to https://curl.haxx.se/libcurl/c/libcurl-errors.html for error code: 7
```

手动添加 TXT 记录到dns中
```
[Tue Feb 22 15:01:04 CST 2022] Please refer to https://curl.haxx.se/libcurl/c/libcurl-errors.html for error code: 7
[Tue Feb 22 15:01:04 CST 2022] Can not init api for: https://acme.zerossl.com/v2/DV90.
[Tue Feb 22 15:01:04 CST 2022] Sleep 10 and retry.
[Tue Feb 22 15:01:30 CST 2022] Using CA: https://acme.zerossl.com/v2/DV90
[Tue Feb 22 15:01:30 CST 2022] Registering account: https://acme.zerossl.com/v2/DV90
[Tue Feb 22 15:01:46 CST 2022] Registered
[Tue Feb 22 15:01:46 CST 2022] ACCOUNT_THUMBPRINT='TPUf_Y9OMRWzB5iwTVDWn34LtfozLJ_mr7La4-DIoUo'
[Tue Feb 22 15:01:46 CST 2022] Creating domain key
[Tue Feb 22 15:01:46 CST 2022] The domain key is here: /root/.acme.sh/example.net/example.net.key
[Tue Feb 22 15:01:46 CST 2022] Multi domain='DNS:example.net,DNS:*.example.net'
[Tue Feb 22 15:01:46 CST 2022] Getting domain auth token for each domain
[Tue Feb 22 15:02:07 CST 2022] Getting webroot for domain='example.net'
[Tue Feb 22 15:02:07 CST 2022] Getting webroot for domain='*.example.net'
[Tue Feb 22 15:02:08 CST 2022] Add the following TXT record:
[Tue Feb 22 15:02:08 CST 2022] Domain: '_acme-challenge.example.net'
[Tue Feb 22 15:02:08 CST 2022] TXT value: 'xY4ldDSYI0llEmQ9drHJSX7OKx8hCd6Cxg86qWDAUUo'
[Tue Feb 22 15:02:08 CST 2022] Please be aware that you prepend _acme-challenge. before your domain
[Tue Feb 22 15:02:08 CST 2022] so the resulting subdomain will be: _acme-challenge.example.net
[Tue Feb 22 15:02:08 CST 2022] Please add the TXT records to the domains, and re-run with --renew.
[Tue Feb 22 15:02:08 CST 2022] Please add '--debug' or '--log' to check more details.
[Tue Feb 22 15:02:08 CST 2022] See: https://github.com/acmesh-official/acme.sh/wiki/How-to-debug-acme.sh
```

TXT 记录查询

```
linux

dig @114.114.114.114 _acme-challenge.example.net txt +short
```

```
windows

nslookup -type=txt www.domain.com 223.5.5.5
```

```
mac

nslookup -type=txt www.domain.com 223.5.5.5
```

添加记录之后执行命令
#### 生成证书
```
acme.sh --renew -d example.com -d "*.example.com" --yes-I-know-dns-manual-mode-enough-go-ahead-please

```


### DNS API 验证
官方文档 https://github.com/acmesh-official/acme.sh/wiki/dnsapi


这种方式将自动为你的域名添加一条 txt 解析，验证成功后，这条解析记录会被删除，所以对你来说是无感的，就是要等大约 120秒。

以 阿里云dns 为例

添加 dns api  kay 
```
# 腾讯云
export DP_Id="YourId"
export DP_Key="YourToken"

# 阿里云
export Ali_Key="YourAccessKeyId"
export Ali_Secret="YourAccessKeySecret"


更多支持，参考官方文档
```


生成 ecc 证书
```
# 腾讯云
acme.sh --issue --dns dns_dp -d example.com -d *.example.com

# 阿里云
acme.sh --issue --dns dns_ali -d example.com -d *.example.com --keylength ec-256
```

keylength 支持的协议
```
ec-256 (prime256v1, "ECDSA P-256")
ec-384 (secp384r1, "ECDSA P-384")
ec-521 (secp521r1, "ECDSA P-521", which is not supported by Let's Encrypt yet.)
```


**完成后会自动生成证书**


## 将证书安装到 Apache/Nginx 
生成证书后，您可能希望将证书安装/复制到您的 Apache/Nginx 或其他服务器。 
您 必须 使用此命令将证书复制到目标文件， 请勿 使用 ~/.acme.sh/ 文件夹中的证书文件，它们仅供内部使用，文件夹结构将来可能会更改。

Apache
```
acme.sh --install-cert -d example.com --cert-file /example/nginx/example.net/cert.pem  --key-file /example/nginx/example.net/key.pem --fullchain-file /example/nginx/example.net/fullchain.pem  --reloadcmd  "service apache2 force-reload"
```


Nginx
```
acme.sh --install-cert -d example.com --key-file  /example/nginx/example.net/key.pem  --fullchain-file /example/nginx/example.net/cert.pem --reloadcmd "nginx -s reload"

## ecc
acme.sh --install-cert -d example.com --key-file  /example/nginx/example.net/key.pem  --fullchain-file /example/nginx/example.net/cert.pem --reloadcmd "nginx -s reload" --ecc
```


## 证书更新

### 手动dns 模式的更新
需要将 TXT记录手动添加的dns
```
acme.sh --renew -d example.com --yes-I-know-dns-manual-mode-enough-go-ahead-please --force
```

ecc
```
acme.sh --renew --force -d example.com --yes-I-know-dns-manual-mode-enough-go-ahead-please --ecc 
```

```
acme.sh --renew --force --issue --dns dns_ali  -d *.ztocwst.net --yes-I-know-dns-manual-mode-enough-go-ahead-please --ecc
```
### 自动模式

acme 会在系统计划任务添加更新任务，但是证书需要手动安装到指定路径

#### 方案一:
使用软链接的方式，将目录链接到指定位置


#### 方案二:
使用脚本的方式，手动更新证书。将脚本添加到计划任务中
```
vim updateSSl.sh


#!/bin/bash

acme.sh --renew --force --issue --dns dns_ali  -d *.ztocwst.net --yes-I-know-dns-manual-mode-enough-go-ahead-please --ecc

acme.sh --install-cert -d ztocwst.net --key-file  /ztocwst/nginx/ztocwst.net/key.pem  --fullchain-file /ztocwst/nginx/ztocwst.net/cert.pem --ecc


systemctl restart openresty

```


## acme 常用命令

### 查看已经生成的证书
```
acme.sh list
```

### 删除弃用的证书
```
acme.sh  --remove  -d example.com
```
### 吊销证书
如果申请好的证书不需要了，可以手动进行吊销
```
acme.sh --revoke -d *.example.com --ecc
```


### acme更新
手动更新
```
acme.sh --upgrade
```

自动更新
```
acme.sh --upgrade --auto-upgrade
```

禁用更新
```
acme.sh --upgrade --auto-upgrade 0
```
