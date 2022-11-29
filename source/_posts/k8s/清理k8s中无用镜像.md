---
title: 常用清理集群资源的命令
date: 2022-11-01 20:26
categories:
- k8s
tags:
- image
---
  
  
摘要: desc
<!-- more -->

## 清理 Evicted 状态的 Pod

```bash
kubectl get pods --all-namespaces  | grep Evicted
```

## 清理 Error 状态的 Pod

```bash
kubectl get pods --all-namespaces  | grep Error | awk '{print $1,$2}' | xargs -L1 kubectl delete pod -n

```

## 清理 Completed 状态的 Pod

```bash
kubectl get pods --all-namespaces  | grep Completed | awk '{print $1,$2}' | xargs -L1 kubectl delete pod -n
```

## 清理没有被使用的 PV

```bash
kubectl describe -A pvc | grep -E "^Name:.*$|^Namespace:.*$|^Used By:.*$" | grep -B 2 "<none>" | grep -E "^Name:.*$|^Namespace:.*$" | cut -f2 -d: | paste -d " " - - | xargs -n2 bash -c 'kubectl -n ${1} delete pvc ${0}'
```

## 清理没有被绑定的 PVC

```bash
kubectl get pvc --all-namespaces | grep -v Bound | awk '{print $1,$2}' | xargs -L1 kubectl delete pvc -n
```

## 清理没有被绑定的 PV

```bash
kubectl get pv | tail -n +2 | grep -v Bound | awk '{print $1}' | xargs -L1 kubectl delete pv
```

## 清理含有僵尸进程的pod

```bash

ps -A -ostat,ppid | grep -e '^[Zz]' | awk '{print }' | xargs kill -HUP > /dev/null 2>&1
ps aux | grep pid
kubectl delete po xxx -n xxx

```
