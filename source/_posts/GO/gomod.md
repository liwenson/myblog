---
title: go mod 简单使用
date: 2020-10-13 16:28
categories:
- go
tags:
- go-mod
---
  
  
摘要: go mod 使用
<!-- more -->


go modules 是 golang 1.11 新加的特性。Modules官方定义为：

> 模块是相关Go包的集合。modules是源代码交换和版本控制的单元。 go命令直接支持使用modules，包括记录和解析对其他模块的依赖性。modules替换旧的基于GOPATH的方法来指定在给定构建中使用哪些源文件

### 如何使用 Modules ？

把 golang 升级到 1.11

设置 GO111MODULE

GO111MODULE 有三个值：off, on和auto（默认值）。
```
GO111MODULE=off，go命令行将不会支持module功能，寻找依赖包的方式将会沿用旧版本那种通过vendor目录或者GOPATH模式来查找。
GO111MODULE=on，go命令行会使用modules，而一点也不会去GOPATH目录下查找。
GO111MODULE=auto，默认值，go命令行将会根据当前目录来决定是否启用module功能。这种情况下可以分为两种情形：
    1、当前目录在GOPATH/src之外且该目录包含go.mod文件
    2、当前文件在包含go.mod文件的目录下面。
```


> 当modules 功能启用时，依赖包的存放位置变更为$GOPATH/pkg，允许同一个package多个版本并存，且多个项目可以共享缓存的 module。


### go mod  命令
golang 提供了 go mod命令来管理包。
go mod 有以下命令：



| 命令 | 说明 | 
| ---- | ---- |
| download |  download modules to local cache(下载依赖包) |
| edit | edit go.mod from tools or scripts(编辑go.mod) |
| graph | print module requirement graph (打印模块依赖图) |
| init | initialize new module in current directory(在当前目录初始化mod) |
| tidy | add missing and remove unused modules(拉取缺少的模块，移除不用的模块) |
| vendor | make vendored copy of dependencies(将依赖复制到vendor下) |
| verify | verify dependencies have expected content (验证依赖是否正确) |
| why | explain why packages or modules are needed(解释为什么需要依赖) |

---

go.mod 提供了module, require、replace和exclude 四个命令
```
module    语句指定包的名字(路径)
require   语句指定的依赖项模块
replace   语句可以替换依赖项模块
exclude   语句可以忽略依赖项模块
```


---

go get 升级

- 运行 `go get -u`  将会升级到最新的次要版本或者修订版本(x.y.z, z是修订版本号， y是次要版本号)
- 运行 `go get -u=patch` 将会升级到最新的修订版本
- 运行 `go get package@version` 将会升级到指定的版本号version
- 运行`go get`如果有版本的更改，那么go.mod文件也会更改


### 使用replace替换无法直接获取的package
由于某些已知的原因，并不是所有的package都能成功下载，比如：golang.org下的包。
modules 可以通过在 go.mod 文件中使用 replace 指令替换成github上对应的库，比如：
```
replace (
	golang.org/x/crypto v0.0.0-20190313024323-a1f597ede03a => github.com/golang/crypto v0.0.0-20190313024323-a1f597ede03a
)
```
或者

```
replace golang.org/x/crypto v0.0.0-20190313024323-a1f597ede03a => github.com/golang/crypto v0.0.0-20190313024323-a1f597ede03a
```

