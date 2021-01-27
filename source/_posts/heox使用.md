---
title:  hexo 使用
date: 2019-10-09 11:00:00
categories: 
- hexo
tags:
- hexo
---

## hexo 使用

## 安装nodeJS

安装后

```bash
node -v
npm -v
```



## 安装 hexo

```bash
npm install -g hexo-cli

hexo -v    #查看一下版本
```



初始化hexo

```
始化hexo
----------------------
hexo init myblog

这个myblog可以自己取什么名字都行，然后
----------------------
cd myblog
npm install

```



命令

```bash
hexo new "postName"     #新建文章
hexo new page "pageName"    #新建页面
hexo generate      #生成静态页面至public目录
hexo server      #开启预览访问端口（默认端口4000，'ctrl + c'关闭server）
hexo deploy      #将.deploy目录部署到指定空间
hexo help        # 查看帮助
hexo version     #查看Hexo的版本
```

## 简写指令

```bash
hexo n "我的第一篇文章"  等价于 hexo new "我的第一篇文章"   还等价于   hexo new post "我的第一篇文章"
hexo p     等价于   hexo publish
hexo g     等价于   hexo generate
hexo s     等价于   hexo server
hexo d     等价于   hexo deploy
hexo deploy -g     等价于    hexo deploy --generate
hexo generate -d   等价于    hexo generate --deploy
```

