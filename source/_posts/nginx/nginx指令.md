!---
title: nginx常用指令
date: 2022-09-16 10:20
categories:
- nginx
tags:
- nginx
---
  
  
摘要: nginx 常用指令笔记
<!-- more -->

## location

[location测试工具](https://detailyang.github.io/nginx-location-match-visible/) ,

### 优先级

(location `=` ) > (location `完整路径` ) > (location `^~` 路径) > (location `~`,`~*` 从上向下正则顺序，匹配就终止) > (location 部分起始路径) > (`/`)


|选项|匹配规则|示例|类型|优先级|
|---|---|---|---|---|
|=|精准匹配|location = /test {...}|精准匹配 |A|
|^~|从请求 uri 的开头进行匹配|location ^~ /test {...}|前缀匹配 |B|
|[空串]|从请求 uri 的开头进行匹配|location /test {...}|不带修饰符的前缀匹配|E|
|~|区分大小写的正则匹配|location ~ /test {...}|正则匹配 |D|
|~*|不区分大小写的正则匹配|location ~* /test {...}|正则匹配 |C|

A > B > C > D > E

普通 location > 正则 location


### 分类

正则 location 和普通 location

```txt
正则location： "~"和"~*"："~"表示区分大小写；"~*"表示不区分大小写
普通location:  除了上面其余全是(包括没有前缀) "="，"^~"，"@""
"^~"中的"^"表示非，"~"表示正则，意思为不要继续匹配正则

"="也表示阻止正则location，和"^~"的区别为："^~"依然遵守"最大前缀"匹配；而"="必须是精准匹配。
"@"是用来定义"Named Location"的（可以理解为独立于“普通location”和“正则location”之外的第三种类型），这种“Named Location ”不是用来处理普通的HTTP 请求的，它是专门用来处理"内部重定向（internally redirected ）"请求的。

注意：这里说的 "内部重定向（internally redirected ）" 是不需要跟浏览器交互的，纯粹是服务端的一个转发行为。
```


---

## try_files/index

### 配置语法

```nginx
Syntax:  try_files file ... uri;
         try_files file ... =code;
Default: —
Context: server, location
```

### 例子

```nginx
location / {
    root html;
    index index.html index.htm;
    try_files $uri $uri/ /index.html;
}
```

### 解释

- root: 设置静态根目录为 html
- index: 设置目录的默认文件为 index.html 、index.htm
- try_files: 设置文件查找规则为 $uri $uri/ /index.html。即3个规则，先从 $uri 查找，再从 $uri/ 目录中查找，最后查找 /index.html。

### 例子解释

针对上面的配置，当请求 http://localhost:8080/abc 时，则 $uri 为 /abc。此时，try_files 的规则可以具体为 /abc /abc/ /index.html，/ 表示根目录 html（由 root、alias指令 指定）。
其具体的查找逻辑如下：

1、检查 html 目录中是否存在 abc 文件（对应第1个规则）

- 如果存在，则返回文件
- 如果不存在，则继续下一步

2、检查 html 目录中是否存在 abc/ 目录（对应第2个规则）

- 如果存在，则再检查 abc/ 目录中是否存在 index.html 文件（由 index、alias指令 指定）
- 如果存在，则返回文件
- 如果不存在，则默认返回403，因为目录不可访问；
- 如果不存在则继续下一步

3、检查 html 目录中是否存在 index.html 文件（对应第3个规则）

- 如果存在，则返回文件
- 如果不存在，则返回404

