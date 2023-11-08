---
title: OpenKruise简单使用
date: 2023-04-10 16:37
categories:
- cat
tags:
- tag
---
  
  
摘要: desc
<!-- more -->

OpenKruise 是一个基于 Kubernetes 的扩展套件，主要聚焦于云原生应用的自动化，比如部署、发布、运维以及可用性防护。

OpenKruise 提供的绝大部分能力都是基于 CRD 扩展来定义，它们不存在于任何外部依赖，可以运行在任意纯净的 Kubernetes 集群中。

## 核心能力

### 增强版本的 Workloads

OpenKruise 包含了一系列增强版本的 Workloads（工作负载），比如 CloneSet、Advanced StatefulSet、Advanced DaemonSet、BroadcastJob 等。

它们不仅支持类似于 Kubernetes 原生 Workloads 的基础功能，还提供了如原地升级、可配置的扩缩容/发布策略、并发操作等。

其中，原地升级是一种升级应用容器镜像甚至环境变量的全新方式。它只会用新的镜像重建 Pod 中的特定容器，整个 Pod 以及其中的其他容器都不会被影响。因此它带来了更快的发布速度，以及避免了对其他 Scheduler、CNI、CSI 等组件的负面影响。

### 应用的旁路管理

OpenKruise 提供了多种通过旁路管理应用 sidecar 容器、多区域部署的方式，“旁路” 意味着你可以不需要修改应用的 Workloads 来实现它们。

比如，SidecarSet 能帮助你在所有匹配的 Pod 创建的时候都注入特定的 sidecar 容器，甚至可以原地升级已经注入的 sidecar 容器镜像、并且对 Pod 中其他容器不造成影响。

而 WorkloadSpread 可以约束无状态 Workload 扩容出来 Pod 的区域分布，赋予单一 workload 的多区域和弹性部署的能力。

### 高可用性防护

OpenKruise 在为应用的高可用性防护方面也做出了很多努力。

目前它可以保护你的 Kubernetes 资源不受级联删除机制的干扰，包括 CRD、Namespace、以及几乎全部的 Workloads 类型资源。

相比于 Kubernetes 原生的 PDB 只提供针对 Pod Eviction 的防护，PodUnavailableBudget 能够防护 Pod Deletion、Eviction、Update 等许多种 voluntary disruption 场景。

### 高级的应用运维能力

OpenKruise 也提供了很多高级的运维能力来帮助你更好地管理应用。

你可以通过 ImagePullJob 来在任意范围的节点上预先拉取某些镜像，或者指定某个 Pod 中的一个或多个容器被原地重启。


## 官方文档

https://openkruise.io/zh/docs/installation

## 安装

从 v1.0.0 (alpha/beta) 开始，OpenKruise 要求在 Kubernetes >= 1.16 以上版本的集群中安装和使用。

OpenKruise 需要使用helm来安装

```
# Firstly add openkruise charts repository if you haven't do this.
$ helm repo add openkruise https://openkruise.github.io/charts/

# [Optional]
$ helm repo update

# Install the latest version.
$ helm install kruise openkruise/kruise --version 1.4.0
```

安装滚动更新

```
helm install kruise-rollout openkruise/kruise-rollout --version 0.3.0
```


