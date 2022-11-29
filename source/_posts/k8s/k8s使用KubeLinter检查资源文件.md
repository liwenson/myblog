---
title: 使用KubeLinter检查k8s资源文件
date: 2022-04-21 11:11
categories:
- k8s
tags:
- KubeLinter
---
  
  
摘要: desc
<!-- more -->

## 前言

KubeLinter 运行合理的默认检查，旨在为您提供有关 Kubernetes YAML 文件和 Helm 图表的有用信息。 这是为了帮助团队及早并经常检查安全错误配置和 DevOps 最佳实践。 其中一些常见示例包括以非 root 用户身份运行容器、强制执行最低权限以及仅将敏感信息存储在机密中。

KubeLinter 是可配置的，因此您可以启用和禁用检查，以及创建自己的自定义检查，具体取决于您希望在组织内遵循的策略。

当 lint 检查失败时，KubeLinter 会报告有关如何解决任何潜在问题的建议并返回非零退出代码。

## 官方文档<https://docs.kubelinter.io>

## 安装

下载页面 <https://github.com/stackrox/kube-linter/releases>

## 使用

```bash
kube-linter lint your-yaml.yaml
```

问题检查说明和处理意见 <https://docs.kubelinter.io/#/generated/checks>



