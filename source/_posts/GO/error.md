---
title: golang 碰到的错误
date: 2021-06-28 11:12
categories:
- golang
tags:
- golang
---
	
	
摘要: desc
<!-- more -->


## Err01
#### 错误
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

#### 处理
```
go clean -modcache

cd project && rm go.sum

go mod tidy
```


#### 原因
```
之前用 go 1.15的版本，现在又升级到 go 1.16，需要重新生成一次你的 mod 缓存，否则就会报错 checksum mismatch
```


## Err02

#### 错误
```
exec: "gcc": executable file not found in %PATH%
```

#### 处理
```
windows下载安装tdm-gcc 或者 Mingw 即可
```

#### 原因
```
原因是sqlitle3是个cgo库，需要gcd编译c代码
```
