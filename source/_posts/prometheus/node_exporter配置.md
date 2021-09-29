---
title: node_exporter 配置
date: 2020-09-21 16:34
categories:
- prometheus
tags:
- prome
- node_exporter
---


node_exporter是prometheus官方提供的agent，项目被托管在prometheus的账号之下。我们也可以通过官方提供的链接下载最新的版本。在官方的github里面已经提供了非常详细使用说明，我们这里带大家梳理一下


### node_exporte基本信息配置

```
-- web.listen-address=":9100"
# 监听的端口，默认是9100，若需要修改则通过此参数

--web.telemetry-path="/metrics"  
#获取metric信息的url，默认是/metrics，若需要修改则通过此参数

--log.level="info" 
#设置日志级别

--log.format="logger:stderr"  
#设置打印日志的格式，若有自动化日志提取工具可以使用这个参数规范日志打印的格式
```


### 通过正则表达式来屏蔽或选择某些监控项
```
--collector.diskstats.ignored-devices="^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$"
#通过正则表达式忽略某些磁盘的信息收集

--collector.filesystem.ignored-mount-points="^/(dev|proc|sys|var/lib/docker/.+)($|/)"  
#通过正则表达式忽略某些文件系统挂载点的信息收集

--collector.filesystem.ignored-fs-types="^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"  
#通过正则表达式忽略某些文件系统类型的信息收集

--collector.netclass.ignored-devices="^$"  
#通过正则表达式忽略某些网络类的信息收集

--collector.netdev.ignored-devices="^$"  
#通过正则表达式忽略某些网络设备的信息收集

  --collector.netstat.fields="^$"
 #通过正则表达式配置需要获取的网络状态信息
 
--collector.vmstat.fields="^(oom_kill|pgpg|pswp|pg.*fault).*" 
#通过正则表达式配置vmstat返回信息中需要收集的选项
```

```

````

### 添加用户名和密码验证

我们直接可以使用 htpasswd 来生成 密码(在httpd-tools当中)
```
yum install httpd-tools -y

htpasswd -nBC 12 '' | tr -d ':\n'       
New password:
Re-type new password:                                              
$2y$12$WLw2sYa.NYZoBVoCOE84qe3xNm7kbSoKVIBXP.PvqNDna60vnZhEW
#这个密码可以用作其他的服务器上，自己输入的密码要记住，
#用户名可以任意给一个，配置文件格式是如下，注意username前面有两个空格

basic_auth_users:
  # 当前设置的用户名为 prometheus ， 可以设置多个
  prometheus: $2y$12$WLw2sYa.NYZoBVoCOE84qe3xNm7kbSoKVIBXP.PvqNDna60vnZhEW
```



### TLS的配置
```bash
# mkdir -p prometheus-tls
# cd prometheus-tls
# openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout node_exporter.key -out node_exporter.crt -subj "/C=CN/ST=Beijing/L=Beijing/O=Moelove.info/CN=localhost"

# ls
node_exporter.crt  node_exporter.key
```


我们默认暴露的都是http的请求的，也没有验证，也就是明文传输，很容易存在安全隐患，如果需要对数据加密，我们就要使用参数`./node_exporter --web.config=web-config.yml`，这个文件的内容如下
```
tls_server_config:
  # Certificate and key files for server to use to authenticate to client.
  cert_file: node_exporter.crt   # <filename>
  key_file: node_exporter.key    #<filename>

  # Server policy for client authentication. Maps to ClientAuth Policies.
  # For more detail on clientAuth options: [ClientAuthType](https://golang.org/pkg/crypto/tls/#ClientAuthType)
  [ client_auth_type: <string> | default = "NoClientCert" ]

  # CA certificate for client certificate authentication to the server.
  [ client_ca_file: <filename> ]

  # Minimum TLS version that is acceptable.
  [ min_version: <string> | default = "TLS12" ]

  # Maximum TLS version that is acceptable.
  [ max_version: <string> | default = "TLS13" ]

  # List of supported cipher suites for TLS versions up to TLS 1.2. If empty,
  # Go default cipher suites are used. Available cipher suites are documented
  # in the go documentation:
  # https://golang.org/pkg/crypto/tls/#pkg-constants
  [ cipher_suites:
    [ - <string> ] ]

  # prefer_server_cipher_suites controls whether the server selects the
  # client's most preferred ciphersuite, or the server's most preferred
  # ciphersuite. If true then the server's preference, as expressed in
  # the order of elements in cipher_suites, is used.
  [ prefer_server_cipher_suites: <bool> | default = true ]

  # Elliptic curves that will be used in an ECDHE handshake, in preference
  # order. Available curves are documented in the go documentation:
  # https://golang.org/pkg/crypto/tls/#CurveID
  [ curve_preferences:
    [ - <string> ] ]

http_server_config:
  # Enable HTTP/2 support. Note that HTTP/2 is only supported with TLS.
  # This can not be changed on the fly.
  [ http2: <bool> | default = true ]

# Usernames and hashed passwords that have full access to the web
# server via basic authentication. If empty, no basic authentication is
# required. Passwords are hashed with bcrypt.
basic_auth_users:
  [ <string>: <secret> ... ]
```


不能直接 curl 进行请求了，我们可以将证书传递给 curl ，用来验证刚才的配置是否正确
```
curl -s  --cacert node_exporter.crt https://localhost:9100/metrics  |grep node_exporter_build_info
```

当然，除了通过 --cacert 参数将证书传递给 curl 外，也可以通过 -k 参数来忽略证书检查。
```
curl -s -k https://localhost:9100/metrics  |grep node_exporter_build_info        
```

### 配置 Prometheus 使用 TLS
要修改下配置文件，让 Prometheus 可以抓取 Node Exporter 暴露的 metrics 。

```
global:
  scrape_interval:     15s 
  evaluation_interval: 15s 

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    scheme: https
    tls_config:
      ca_file: node_exporter.crt
    static_configs:
    - targets: ['localhost:9100']
```

这里额外增加了 `scheme: https`  表示通过 HTTPS 建立连接，tls_config 中指定了所用的证书文件。完整的配置可以参考 官方文档中对 [tls_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#tls_config) 的说明 。



### 配置 Prometheus 使用 Basic Auth
```
global:
  scrape_interval:     15s 
  evaluation_interval: 15s 

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    scheme: https
    tls_config:
      ca_file: node_exporter.crt
    basic_auth:
      username: prometheus
      password: moelove.info
    static_configs:
    - targets: ['localhost:9100']
```

在生产中使用时，建议更加规范化操作，比如 CA 的选择，密码的管理等，比如 Node Exporter 的 Basic Auth 其实支持配置多个用户名密码的。

