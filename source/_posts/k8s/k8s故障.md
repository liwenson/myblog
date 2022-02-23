---
title:  k8s 故障
date: 2020-01-09 11:00:00
categories: 
- k8s
tags:
- k8s
---

# 删除K8s Namespace时卡在Terminating状态

## 方案一

想要删除K8s里的一个Namespace，结果删除了所有该Namespace资源之后使用`kubectl delete namespace test`发现删除不掉，一直卡在`Terminating`状态，使用`--force`参数依然无法删除，报错:

```
Error from server (Conflict): Operation cannot be fulfilled on namespaces "test": The system is ensuring all content is removed from this namespace. Upon completion, this namespace will automatically be purged by the system.
```


先运行   `kubectl get namespace test -o json > tmp.json` ，拿到当前namespace描述，然后打开`tmp.json`，删除其中的`spec`字段。因为这边的K8s集群是带认证的，所以又新开了窗口运行`kubectl proxy`跑一个API代理在本地的8081端口。最后运行
```bash
kubectl get namespace test -o json > tmp.json
```

```bash
kubectl proxy
```

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


## 方案二

删除已经停止的 namespace 和 删除 普通的 pod 、deployment、svc等不同。不能使用 --force

导出描述的json文件
```
kubectl get ns test -o json > test.json
```

打开导出的json文件 test.json

```
{
    "apiVersion": "v1",
    "kind": "Namespace",
    "metadata": {
        "annotations": {
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"test\"}}\n"
        },
        "creationTimestamp": "2021-01-15T03:38:43Z",
        "deletionTimestamp": "2022-06-15T13:50:41Z",
        "managedFields": [
            ...........此处省略..........
        ],
        "name": "test",
        "resourceVersion": "78488",
        "selfLink": "/api/v1/namespaces/test",
        "uid": "219da01a-019b-48df-96bc-2ab227db0b40"
    },
    "spec": {
        "finalizers": [
			"kubernetes"   // 删除 
        ]
    },
    "status": {
        "conditions": [
		......此处省略.....
        ],
        "phase": "Terminating"
    }
}

```

删除 spec 字段中的 "kubernetes"，改为
```
{
    "apiVersion": "v1",
    "kind": "Namespace",
    "metadata": {
        "annotations": {
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"test\"}}\n"
        },
        "creationTimestamp": "2021-01-15T03:38:43Z",
        "deletionTimestamp": "2022-06-15T13:50:41Z",
        "managedFields": [
            ...........此处省略..........
        ],
        "name": "test",
        "resourceVersion": "78488",
        "selfLink": "/api/v1/namespaces/test",
        "uid": "219da01a-019b-48df-96bc-2ab227db0b40"
    },
    "spec": {
        "finalizers": [

        ]
    },
    "status": {
        "conditions": [
		......此处省略.....
        ],
        "phase": "Terminating"
    }
}
```

执行清除命令
```
kubectl replace --raw "/api/v1/namespaces/test/finalize" -f ./test.json
```

查看
```
kubectl get ns
```


