---
title:  k8s 故障
date: 2020-01-09 11:00:00
categories: 
- k8s
tags:
- k8s
---

# 删除K8s Namespace时卡在Terminating状态

想要删除K8s里的一个Namespace，结果删除了所有该Namespace资源之后使用`kubectl delete namespace test`发现删除不掉，一直卡在`Terminating`状态，使用`--force`参数依然无法删除，报错:

```
Error from server (Conflict): Operation cannot be fulfilled on namespaces "test": The system is ensuring all content is removed from this namespace. Upon completion, this namespace will automatically be purged by the system.
```



先运行   `kubectl get namespace test -o json > tmp.json` ，拿到当前namespace描述，然后打开`tmp.json`，删除其中的`spec`字段。因为这边的K8s集群是带认证的，所以又新开了窗口运行`kubectl proxy`跑一个API代理在本地的8081端口。最后运行

```bash
curl -k -H "Content-Type: application/json" -X PUT --data-binary @tmp.json http://127.0.0.1:8080/api/v1/namespaces/test/finalize
```

查看 api 地址

```
# kubectl cluster-info

Kubernetes master is running at http://localhost:8080
CoreDNS is running at http://localhost:8080/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
kubernetes-dashboard is running at http://localhost:8080/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy
```

