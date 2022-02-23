---
title: golang 碰到的错误
date: 2021-06-28 11:12
categories:
- go
tags:
- golang
---
	
	
摘要: desc
<!-- more -->


## Err01
### 错误
```
go mod tidy

verifying github.com/jackc/pgio@v1.0.0: checksum mismatch
        downloaded: h1:g12B9UwVnzGhueNavwioyEEpAmqMe1E/BN9ES+8ovkE=
        go.sum:     h1:g12B9UwVnzGhuePromeAlertwioyEEpAmqMe1E/BN9ES+8ovkE=

SECURITY ERROR
This download does NOT match an earlier download recorded in go.sum.
The bits may have been replaced on the origin server, or an attacker may
have intercepted the download attempt.

For more information, see 'go help module-auth'.
```

### 处理
```
go clean -modcache

cd project && rm go.sum

go mod tidy
```


### 原因
```
之前用 go 1.15的版本，现在又升级到 go 1.16，需要重新生成一次你的 mod 缓存，否则就会报错 checksum mismatch
```


## Err02

### 错误
```
exec: "gcc": executable file not found in %PATH%
```

### 处理
```
windows下载安装tdm-gcc 或者 Mingw 即可
```

### 原因
```
原因是sqlitle3是个cgo库，需要gcd编译c代码
```


## Err03
### 错误
```

x509: certificate signed by unknown authority

golang 在使用http请求https://**网站时，报了x509: certificate signed by unknown authority这个错误。经查阅，是由于目标网站的CA证书在本机没有
```

### 处理
#### 方式一，使用TLS

网上通常的方式是通过设置tls来跳过证书检测，即：
```
timeout = time.Duration(10 * time.Second) //超时时间50ms
client  = &http.Client{
    Timeout: timeout,
    Transport: &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
}
```
这样，使用client就不会再报该错误了。但此方法是跳过了检测，在某些场景并不适用，就只能使用其他方式了。

#### 方式二，添加证书到本机上
在各个OS中，添加根证书的方式是不同的。对于Linux系统来说，使用
```
sudo cp {client}/cacert.pem /etc/ssl/certs
```

这就是手动把CA证书添加到本机的证书链，再进行请求，就可以成功访问了。

但这种方式存在一定弊端就是如果你客户端部署在多台机器，就得手动每台都添加；并且，还需要有root权限才能做，通常我们开发是没有服务器的root权限的。

这样，我们还可以使用第三种方式来解决

#### 方式三，请求内嵌证书
类似第一种方式，我们同样是配置TLS，但这次我们不进行跳过，而是直接将*.pem文件配置给client，这样既保证能够访问，又不是直接地跳过。
```
rootCA := `*.pem 文件的内容`
roots := x509.NewCertPool()
ok := roots.AppendCertsFromPEM([]byte(rootCA))
if !ok {
    panic("failed to parse root certificate")
}
client  = &http.Client{
    Transport: &http.Transport{
		TLSClientConfig: &tls.Config{RootCAs: roots},
	}
}
```
这样，就大功告成啦。

### 总结
当然，这三种方式都并不是互斥的，每一种都有不同的使用场景。

如果你是写了一个爬虫，那你肯定只需也只能使用第一种跳过的方式，这样可以更为高效地爬取。

如果你能够拿到证书，但是没有root权限，但是又要求使用证书，就得用第三种方式了。

而一般如果有运维部门帮你给每台服务器都添加证书，当然他们只能使用第二种，这样，你的程序完全可以不用考虑这个问题了。





