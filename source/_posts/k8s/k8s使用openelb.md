---
title: k8s使用openelb
date: 2022-02-11 13:57
categories:
- k8s
tags:
- openelb
---
  
  
摘要: k8s使用openelb
<!-- more -->



## 部署openelb

需要将 k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1 改为  kubespheredev/kube-webhook-certgen:v1.1.1
```
kubectl apply -f https://raw.githubusercontent.com/kubesphere/porter/master/deploy/porter.yaml
```
```
kubectl get po -n porter-system
```

## 使用openelb layer2


[二层模式下使用openelb](https://openelb.github.io/docs/getting-started/usage/use-porter-in-layer-2-mode/)

### kube-proxy 启用 strictARP
编辑 kube-proxy ConfigMap
```
kubectl edit configmap kube-proxy -n kube-system
```

设置 data.config.conf.ipvs.strictARP到 true
```
ipvs:
  strictARP: true
```

重启 kube-proxy:
```
kubectl rollout restart daemonset kube-proxy -n kube-system
```

### 指定用于 PorterLB 的 NIC

如果安装PorterLB的节点有多个网卡，则需要指定二层模式下PorterLB使用的网卡

#### 例子:
安装了 PorterLB 的 master1 节点有两个网卡（eth0 192.168.0.2 和 eth1 192.168.1.2），并且 eth0 192.168.0.2 将用于 PorterLB。

运行以下命令注释master1以指定NIC：
```


```

### 创建 Eip 对象

spec.address必须与 Kubernetes 集群节点在同一网段。 

```
vi porter-layer2-eip.yaml

apiVersion: network.kubesphere.io/v1alpha2
kind: Eip
metadata:
  name: porter-layer2-eip
spec:
  address: 192.168.214.90-192.168.214.100
  interface: ens33
  protocol: layer2
```

创建 Eip 对象：
```
kubectl apply -f porter-layer2-eip.yaml
```

## 使用示例

使用 luksa/kubia 镜像创建两个 Pod 的部署。 每个 Pod 将自己的 Pod 名称返回给外部请求。 

创建 Deployment  YAML 文件
```
vi porter-layer2.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: porter-layer2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: porter-layer2
  template:
    metadata:
      labels:
        app: porter-layer2
    spec:
      containers:
        - image: luksa/kubia
          name: kubia
          ports:
            - containerPort: 8080
```

创建server YAML 文件：

```
vi porter-layer2-svc.yaml

kind: Service
apiVersion: v1
metadata:
  name: porter-layer2-svc
  annotations:
    lb.kubesphere.io/v1alpha1: porter
    protocol.porter.kubesphere.io/v1alpha1: layer2
    eip.porter.kubesphere.io/v1alpha2: porter-layer2-eip
spec:
  selector:
    app: porter-layer2
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 8080
  externalTrafficPolicy: Cluster
```


```
kubectl apply -f porter-layer2.yaml
kubectl apply -f porter-layer2-svc.yaml
```

### 验证
```
kubectl get svc porter-layer2-svc


NAME                TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
porter-layer2-svc   LoadBalancer   10.10.31.219   192.168.214.90   80:31810/TCP   122m

```

```
curl 192.168.214.90
```




