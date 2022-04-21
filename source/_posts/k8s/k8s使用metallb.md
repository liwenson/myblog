---
title: k8s使用metallb
date: 2022-04-01 14:09
categories:
- k8s
tags:
- metallb
---
  
  
摘要: k8s使用metallb
<!-- more -->

[MetalLB 概念](https://metallb.universe.tf/concepts/)

[地址解析协议](https://zh.wikipedia.org/wiki/%E5%9C%B0%E5%9D%80%E8%A7%A3%E6%9E%90%E5%8D%8F%E8%AE%AE)

MetalLB项目目前处于beta阶段，已被多个人员和公司用于多个生产和非生产集群中。根据错误报告的频率，暂时未发现有较大的BUG。

更详细信息可参见官网：<https://metallb.universe.tf>

## 部署要求

MetalLB需要以下环境才能运行:

- 运行Kubernetes 1.13.0或更高版本的群集，尚不具有网络负载平衡功能。
- 集群网络配置 可以与MetalLB共存，详见下图。
- 一些用于MetalLB的IPv4地址。
- 如果使用BGP模式，您还需要一个或多个能够支持 BGP协议的路由器。

## 工作原理

Metallb包含两个组件，Controller和Speaker，Controller为Deployment部署方式，而Speaker则采用daemonset方式部署到Kubernetes集群各个Node节点。

具体的工作原理如下图所示，Controller负责监听service变化，当service配置为LoadBalancer模式时，从IP池分配给到相应的IP，并进行IP的生命周期管理。Speaker则依据Service的变化，按具体的协议发起相应的广播或应答，根据工作模式（Layer2/BGP)的不同，可采用Leader的方式或负载均衡的方式来响应请求。

当业务流量通过TCP/UDP协议到达指定的Node时，由Node上面运行的Kube-Proxy组件对流量进行处理，并分发到对应的Pod上面

## 工作模式

MetalLB支持两种模式，一种是Layer2模式，一种是BGP模式

### Layer2模式

第2层模式下，Metallb会在Node节点中选出一台做为Leader，与服务IP相关的所有流量都会流向该节点。在该节点上， kube-proxy将流量传播到所有服务的Pod，而当leader节点出现故障时，会由另一个节点接管。
局限性：

在二层模式中会存在以下两种局限性：单节点瓶颈以及故障转移慢的情况。

单个leader选举节点接收服务IP的所有流量。这意味着服务的入口带宽被限制为单个节点的带宽，单节点的流量处理能力将成为整个集群的接收外部流量的瓶颈。

在当前的实现中，节点之间的故障转移取决于客户端的合作。当发生故障转移时，MetalLB发送许多2层数据包，以通知客户端与服务IP关联的MAC地址已更改。大多数操作系统能正确处理数据包，并迅速更新其邻居缓存。在这种情况下，故障转移将在几秒钟内发生。在计划外的故障转移期间，在有故障的客户端刷新其缓存条目之前，将无法访问服务IP。对于生产环境如果要求毫秒性的故障切换，目前Metallb可能会比较难适应要求。

### BGP模式

在BGP模式下，群集中的每个节点都与网络路由器建立BGP对等会话，并使用该对等会话通告外部群集服务的IP。假设您的路由器配置为支持多路径，则可以实现真正的负载平衡：MetalLB发布的路由彼此等效。这意味着路由器将一起使用所有下一跳，并在它们之间进行负载平衡。数据包到达节点后，kube-proxy负责流量路由的最后一跳，将数据包送达服务中的一个特定容器。

负载平衡的方式取决于您特定的路由器型号和配置，但是常见的行为是基于数据包哈希值来平衡每个连接，这意味着单个TCP或UDP会话的所有数据包都将定向到群集中的单个计算机。
局限性：

基于BGP的路由器实现无状态负载平衡。他们通过对数据包头中的某些字段进行哈希处理，并将该哈希值用作可用后端数组的索引，将给定的数据包分配给特定的下一跳
但路由器中使用的哈希通常不稳定，因此，只要后端集的大小发生变化（例如，当节点的BGP会话断开时），现有连接就会被随机有效地重新哈希，这意味着大多数现有连接连接最终将突然转发到另一后端，而该后端不知道所讨论的连接。

## 启用kube-proxy的ARP模式

如果您在 IPVS 模式下使用 kube-proxy，从 Kubernetes v1.14.2 开始，您必须启用严格的 ARP 模式。

请注意，如果您使用 kube-router 作为服务代理，则不需要这个，因为它默认启用严格的 ARP。

您可以通过在当前集群中编辑 kube-proxy 配置来实现这一点：

```bash
kubectl edit configmap -n kube-system kube-proxy
```

strictARP 改为true

```yaml
    ipvs:
      strictARP: true
```

快速更改和应用

```bash
# see what changes would be made, returns nonzero returncode if different
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

```

## 创建测试用的工作负载

使用 nginx 镜像，创建两个工作负载：

```bash
kubectl create deploy nginx --image nginx:latest --port 80 -n default
kubectl create deploy nginx2 --image nginx:latest --port 80 -n default
```

同时为两个 Deployment 创建 Service，这里类型选择 LoadBalancer：

```bash
kubectl expose deployment nginx --name nginx-lb --port 8080 --target-port 80 --type LoadBalancer -n default
kubectl expose deployment nginx2 --name nginx2-lb --port 8080 --target-port 80 --type LoadBalancer -n default
```

检查 Service 发现状态都是 Pending 的，这是因为我们目前没有 LoadBalancer 的实现

```bash
kubectl get pods,svc -n default

NAME                          READY   STATUS    RESTARTS   AGE
pod/nginx-8d545c96d-tp56q     1/1     Running   0          84s
pod/nginx2-79c8885ff8-6lq8f   1/1     Running   0          78s

NAME                 TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/nginx-lb     LoadBalancer   10.10.220.35   <pending>     8080:32111/TCP   9s
service/nginx2-lb    LoadBalancer   10.10.76.29    <pending>     8080:30383/TCP   4s

```

## 通过资源文件部署metallb

```bash
curl -O https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
curl -O https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

kubectl apply -f .
```

网络不通可以复制下面的文件内容

```bash
vim namespace.yaml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
  labels:
    app: metallb
```

```bash
vim metallb.yaml

```

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  labels:
    app: metallb
  name: controller
spec:
  allowPrivilegeEscalation: false
  allowedCapabilities: []
  allowedHostPaths: []
  defaultAddCapabilities: []
  defaultAllowPrivilegeEscalation: false
  fsGroup:
    ranges:
    - max: 65535
      min: 1
    rule: MustRunAs
  hostIPC: false
  hostNetwork: false
  hostPID: false
  privileged: false
  readOnlyRootFilesystem: true
  requiredDropCapabilities:
  - ALL
  runAsUser:
    ranges:
    - max: 65535
      min: 1
    rule: MustRunAs
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    ranges:
    - max: 65535
      min: 1
    rule: MustRunAs
  volumes:
  - configMap
  - secret
  - emptyDir
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  labels:
    app: metallb
  name: speaker
spec:
  allowPrivilegeEscalation: false
  allowedCapabilities:
  - NET_RAW
  allowedHostPaths: []
  defaultAddCapabilities: []
  defaultAllowPrivilegeEscalation: false
  fsGroup:
    rule: RunAsAny
  hostIPC: false
  hostNetwork: true
  hostPID: false
  hostPorts:
  - max: 7472
    min: 7472
  - max: 7946
    min: 7946
  privileged: true
  readOnlyRootFilesystem: true
  requiredDropCapabilities:
  - ALL
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - configMap
  - secret
  - emptyDir
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: metallb
  name: controller
  namespace: metallb-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: metallb
  name: speaker
  namespace: metallb-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app: metallb
  name: metallb-system:controller
rules:
- apiGroups:
  - ''
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ''
  resources:
  - services/status
  verbs:
  - update
- apiGroups:
  - ''
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - policy
  resourceNames:
  - controller
  resources:
  - podsecuritypolicies
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app: metallb
  name: metallb-system:speaker
rules:
- apiGroups:
  - ''
  resources:
  - services
  - endpoints
  - nodes
  verbs:
  - get
  - list
  - watch
- apiGroups: ["discovery.k8s.io"]
  resources:
  - endpointslices
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ''
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - policy
  resourceNames:
  - speaker
  resources:
  - podsecuritypolicies
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app: metallb
  name: config-watcher
  namespace: metallb-system
rules:
- apiGroups:
  - ''
  resources:
  - configmaps
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app: metallb
  name: pod-lister
  namespace: metallb-system
rules:
- apiGroups:
  - ''
  resources:
  - pods
  verbs:
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  labels:
    app: metallb
  name: controller
  namespace: metallb-system
rules:
- apiGroups:
  - ''
  resources:
  - secrets
  verbs:
  - create
- apiGroups:
  - ''
  resources:
  - secrets
  resourceNames:
  - memberlist
  verbs:
  - list
- apiGroups:
  - apps
  resources:
  - deployments
  resourceNames:
  - controller
  verbs:
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app: metallb
  name: metallb-system:controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: metallb-system:controller
subjects:
- kind: ServiceAccount
  name: controller
  namespace: metallb-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app: metallb
  name: metallb-system:speaker
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: metallb-system:speaker
subjects:
- kind: ServiceAccount
  name: speaker
  namespace: metallb-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: metallb
  name: config-watcher
  namespace: metallb-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: config-watcher
subjects:
- kind: ServiceAccount
  name: controller
- kind: ServiceAccount
  name: speaker
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: metallb
  name: pod-lister
  namespace: metallb-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-lister
subjects:
- kind: ServiceAccount
  name: speaker
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: metallb
  name: controller
  namespace: metallb-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: controller
subjects:
- kind: ServiceAccount
  name: controller
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app: metallb
    component: speaker
  name: speaker
  namespace: metallb-system
spec:
  selector:
    matchLabels:
      app: metallb
      component: speaker
  template:
    metadata:
      annotations:
        prometheus.io/port: '7472'
        prometheus.io/scrape: 'true'
      labels:
        app: metallb
        component: speaker
    spec:
      containers:
      - args:
        - --port=7472
        - --config=config
        - --log-level=info
        env:
        - name: METALLB_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: METALLB_HOST
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        - name: METALLB_ML_BIND_ADDR
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        # needed when another software is also using memberlist / port 7946
        # when changing this default you also need to update the container ports definition
        # and the PodSecurityPolicy hostPorts definition
        #- name: METALLB_ML_BIND_PORT
        #  value: "7946"
        - name: METALLB_ML_LABELS
          value: "app=metallb,component=speaker"
        - name: METALLB_ML_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: memberlist
              key: secretkey
        image: quay.io/metallb/speaker:v0.12.1
        name: speaker
        ports:
        - containerPort: 7472
          name: monitoring
        - containerPort: 7946
          name: memberlist-tcp
        - containerPort: 7946
          name: memberlist-udp
          protocol: UDP
        livenessProbe:
          httpGet:
            path: /metrics
            port: monitoring
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /metrics
            port: monitoring
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_RAW
            drop:
            - ALL
          readOnlyRootFilesystem: true
      hostNetwork: true
      nodeSelector:
        kubernetes.io/os: linux
      serviceAccountName: speaker
      terminationGracePeriodSeconds: 2
      tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
        operator: Exists
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: metallb
    component: controller
  name: controller
  namespace: metallb-system
spec:
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: metallb
      component: controller
  template:
    metadata:
      annotations:
        prometheus.io/port: '7472'
        prometheus.io/scrape: 'true'
      labels:
        app: metallb
        component: controller
    spec:
      containers:
      - args:
        - --port=7472
        - --config=config
        - --log-level=info
        env:
        - name: METALLB_ML_SECRET_NAME
          value: memberlist
        - name: METALLB_DEPLOYMENT
          value: controller
        image: quay.io/metallb/controller:v0.12.1
        name: controller
        ports:
        - containerPort: 7472
          name: monitoring
        livenessProbe:
          httpGet:
            path: /metrics
            port: monitoring
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /metrics
            port: monitoring
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - all
          readOnlyRootFilesystem: true
      nodeSelector:
        kubernetes.io/os: linux
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
      serviceAccountName: controller
      terminationGracePeriodSeconds: 0
```

```bash
kubectl apply -f namespace.yaml
kubectl apply -f metallb.yaml
```

```bash
kubectl get po -n metallb-system

NAME                         READY   STATUS    RESTARTS   AGE
controller-57fd9c5bb-wtmkr   1/1     Running   0          2m9s
speaker-sn4z8                1/1     Running   0          2m9s
```

## 配置IP池

MetalLB 要为 Service 分配 IP 地址，但 IP 地址不是凭空来的，而是需要预先提供一个地址库。这个地址库是需要和node ip是一个网段的

```bash
vim configmap.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 10.200.70.150-10.200.70.159
```

```bash
kubectl apply -f configmap.yaml
```

查看之前创建测测试demo,发现已经不是 pending 状态了,可以看到 MetalLB 为两个 Service 分配了 IP 地址

```bash
kubectl get pods,svc -n default

NAME                          READY   STATUS    RESTARTS   AGE
pod/nginx-8d545c96d-tp56q     1/1     Running   0          2m40s
pod/nginx2-79c8885ff8-6lq8f   1/1     Running   0          2m34s

NAME                 TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
service/nginx-lb     LoadBalancer   10.10.220.35   10.200.70.150   8080:32111/TCP   85s
service/nginx2-lb    LoadBalancer   10.10.76.29    10.200.70.151   8080:30383/TCP   80s
```

## Layer 2 工作原理

Layer 2 中的 Speaker 工作负载是 DeamonSet 类型，在每台节点上都调度一个 Pod。首先，几个 Pod 会先进行选举，选举出 Leader。Leader 获取所有 LoadBalancer 类型的 Service，将已分配的 IP 地址绑定到当前主机到网卡上。也就是说，所有 LoadBalancer 类型的 Service 的 IP 同一时间都是绑定在同一台节点的网卡上。

当外部主机有请求要发往集群内的某个 Service，需要先确定目标主机网卡的 mac 地址（至于为什么，参考维基百科）。这是通过发送 ARP 请求，Leader 节点的会以其 mac 地址作为响应。外部主机会在本地 ARP 表中缓存下来，下次会直接从 ARP 表中获取。

请求到达节点后，节点再通过 kube-proxy 将请求负载均衡目标 Pod。所以说，假如Service 是多 Pod 这里有可能会再跳去另一台主机。

## 优缺点

优点很明显，实现起来简单（相对于另一种 BGP 模式下路由器要支持 BPG）。只要保证 IP 地址库与集群是同一个网段即可。

当然缺点更加明显了，Leader 节点的带宽会成为瓶颈；与此同时，可用性欠佳，故障转移需要 10 秒钟的时间（每个 speaker 进程有个 10s 的循环）。
