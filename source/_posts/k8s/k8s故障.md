---
title:  k8s 故障
date: 2020-01-09 11:00:00
categories: 
- k8s
tags:
- k8s
---

## 删除K8s Namespace时卡在Terminating状态

### 方案一

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


### 方案二

删除已经停止的 namespace 和 删除 普通的 pod 、deployment、svc等不同。不能使用 --force

导出描述的json文件

```bash
kubectl get ns kuboard -o json > test.json
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

```bash
kubectl replace --raw "/api/v1/namespaces/kuboard/finalize" -f ./test.json
```

查看

```bash
kubectl get ns
```

## k8s 清除状态为Evicted 的pod

```bash
kubectl get pods -n dev| grep Evicted | awk '{print $1}' | xargs kubectl delete pod -n dev
```

---

## nfs-provisioner报错问题:"selfLink was empty"

镜像需要用比较新的

Kubernetes升级为1.20版本后，原有的后端nfs存储storageclass无法自动创建pv。
查看PVC状态一直为pending状态，查看nfs-provisioner日志

```txt
unexpected error getting claim reference: selfLink was empty, can't make reference
```

报错信息 `selfLink was empty` ，于是上网查询相关内容，在[官方1.20的变更说明](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.20.md)中看到其中一条说明为：

```txt
Stop propagating SelfLink (deprecated in 1.16) in kube-apiserver
```

selfLink在1.16版本以后已经弃用，在1.20版本停用。

而由于nfs-provisioner的实现是基于selfLink功能（同时也会影响其他用到selfLink这个功能的第三方软件），需要等nfs-provisioner的制作方重新提供新的解决方案。


### 临时方案

修改` /etc/kubernetes/manifests/kube-apiserver.yaml` 文件，找到如下内容后，在最后添加一项参数

k8s1.24.0 版本默认是true,不支持修改为false,否则apiserver会启动失败！

```yaml
spec:
  containers:

- command:
  - kube-apiserver
  - --advertise-address=192.168.210.1
  - --.......　　#省略多行内容
  - --feature-gates=RemoveSelfLink=false　　#添加此行
```

添加后需要删除apiserver的所有pod进行重启,重启拉起后，再次查询PVC，可以看到PVC状态都为Bound，可以正常被PV绑定了

---

## 4 pod has unbound immediate PersistentVolumeClaims

```txt
0/4 nodes are available: 4 pod has unbound immediate PersistentVolumeClaims. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

---

## 重置kubeadm 环境

```bash
kubeadm reset
rm -fr ~/.kube/  /etc/kubernetes/* var/lib/etcd/*
```

如果忘记kubeadm join 可以通过如下命令获取join命令参数：

```bash
kubeadm token create --print-join-command
```
