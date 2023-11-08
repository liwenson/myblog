---
title: npm镜像配置
date: 2023-07-14 14:10
categories:
- node
tags:
- npm
---
  
  
摘要: desc
<!-- more -->

## 一键脚本

```
# 基础npm
config set registry https://registry.npmmirror.com

# 全面
npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
npm config set electron_mirror https://npmmirror.com/mirrors/electron/
npm config set sqlite3_binary_host_mirror https://npmmirror.com/mirrors/
npm config set profiler_binary_host_mirror https://npmmirror.com/mirrors/node-inspector/
npm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver
npm config set sentrycli_cdnurl https://npmmirror.com/mirrors/sentry-cli/
```
