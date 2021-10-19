---
title: ingress-traefik部署
date: 2021-10-13 15:53
categories:
- k8s
tags:
- ingress
---
	
	
摘要: ingress-traefik部署
<!-- more -->


##  traefik核心概念

> Traefik是一个为了让部署微服务更加便捷而诞生的现代HTTP反向代理、负载均衡工具。 它支持多种后台 (Docker, Swarm, Kubernetes, Marathon, Mesos, Consul, Etcd, Zookeeper, BoltDB, Rest API, file…) 来自动化、动态的应用它的配置文件设置。


#### traefik核心组件

> Providers: 用来自动发现平台上的服务，可以是编排工具、容器引擎或者 key-value 存储等，比如 Docker、Kubernetes、File Entrypoints: 监听传入的流量（端口等…），是网络入口点，它们定义了接收请求的端口（HTTP 或者 TCP）。 Routers: 分析请求（host, path, headers, SSL, …），负责将传入请求连接到可以处理这些请求的服务上去。 Services: 将请求转发给你的应用（load balancing, …），负责配置如何获取最终将处理传入请求的实际服务。 Middlewares: 中间件，用来修改请求或者根据请求来做出一些判断（authentication, rate limiting, headers, …），中间件被附件到路由上，是一种在请求发送到你的服务之前（或者在服务的响应发送到客户端之前）调整请求的一种方法。 Traefik v2.4中增加了对 Kubernetes Gateway API 的支持、那么什么是 Kubernetes Gateway API 呢？Gateway API 是由 SIG-NETWORK 社区管理的一个开源项目；该项目的目标是在 Kubernetes 生态系统内发展服务网络 API；网关 API 提供了用于暴露 Kubernetes 应用程序的 Service、Ingress 等。Gateway API 旨在通过提供可表达的，可扩展的，面向角色的接口来改善服务网络，这些接口已由许多供应商实施并获得了广泛的行业支持；网关 API 是 API 资源（服务、网关类、网关、HTTPRoute、TCPRoute等）的集合、这些资源共同为各种网络用例建模。其实 Traefik 除了支持我们手动配置 TLS 证书之外，还支持自动生成 TLS 证书

#### Nginx-Ingress和traefik区别

> k8s 是通过一个又一个的 controller 来负责监控、维护集群状态。Ingress Controller 就是监控 Ingress 路由规则的一个变化，然后跟 k8s 的资源操作入口 api-server 进行通信交互。K8s 并没有自带 Ingress Controller，它只是一种标准，具体实现有多种，需要自己单独安装，常用的是 Nginx Ingress Controller 和 Traefik Ingress Controller。 Ingress Controller 收到请求，匹配 Ingress 转发规则，匹配到了就转发到后端 Service，而 Service 可能代表的后端 Pod 有多个，选出一个转发到那个 Pod，最终由那个 Pod 处理请求。 

##### traefik优点
```
速度快
不需要安装其他依赖，使用 GO 语言编译可执行文件
支持最小化官方 Docker 镜像
支持多种后台，如 Docker, Swarm mode, Kubernetes, Marathon, Consul, Etcd, Rancher, Amazon ECS 等等
支持 REST API
配置文件热重载，不需要重启进程
支持自动熔断功能
支持轮训、负载均衡
提供简洁的 UI 界面
支持 Websocket, HTTP/2, GRPC
自动更新 HTTPS 证书
支持高可用集群模式
```


##### Nginx和Traefik横向对比

| - |Nginx Ingress 	|Traefik ingress|
|---|---|---|
|协议 |	http/https、http2、grpc、tcp/udp |	http/https、http2、grpc、tcp、tcp+tls|
|路由匹配 |	host、path |	host、path、headers、query、path 、prefix、method |
|命名空间支持 |	- |	共用或指定命名空间 |
|部署策略 |	- |	金丝雀部署、蓝绿部署、灰度部署 |
|upstream探测 |	重试、超时、心跳探测 |	重试、超时、心跳探测、熔断 |
|负载均衡算法 |	RR、会话保持、最小连接、最短时间、一致性hash |	WRR、动态RR、会话保持 |
|优点  |	简单易用，易接入 |	部署容易，支持众多的后端，内置WebUI |
|缺点 |	没有解决nginx reload，插件多，但是扩展性能查差 |	这么一看好像没啥缺点 |



## 准备

清除namespace
```
kubectl delete namespaces ingress-nginx
```


k8s主机设置标签
```
kubectl label node 10.200.92.61 IngressProxy=true
kubectl label node 10.200.92.62 IngressProxy=true
```

## 部署traefik

### 创建namespace 
```
vim traefik-namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: ingress-traefik
```

### 创建 CRD 资源
>在Traefik v2.0版本后，开始使用 CRD（Custom Resource Definition）来完成路由配置等，所以需要提前创建CRD资源。

- crd资源清单 
```
cat traefik-crd.yaml

## IngressRoute
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ingressroutes.traefik.containo.us
spec:
  scope: Namespaced
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: IngressRoute
    plural: ingressroutes
    singular: ingressroute
---
## IngressRouteTCP
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ingressroutetcps.traefik.containo.us
spec:
  scope: Namespaced
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: IngressRouteTCP
    plural: ingressroutetcps
    singular: ingressroutetcp
---
## Middleware
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: middlewares.traefik.containo.us
spec:
  scope: Namespaced
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: Middleware
    plural: middlewares
    singular: middleware
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: tlsoptions.traefik.containo.us
spec:
  scope: Namespaced
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TLSOption
    plural: tlsoptions
    singular: tlsoption
---
## TraefikService
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: traefikservices.traefik.containo.us
spec:
  scope: Namespaced
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TraefikService
    plural: traefikservices
    singular: traefikservice
---
## TraefikTLSStore
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: tlsstores.traefik.containo.us
spec:
  scope: Namespaced
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: TLSStore
    plural: tlsstores
    singular: tlsstore
---
## IngressRouteUDP
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ingressrouteudps.traefik.containo.us
spec:
  scope: Namespaced
  group: traefik.containo.us
  version: v1alpha1
  names:
    kind: IngressRouteUDP
    plural: ingressrouteudps
    singular: ingressrouteudp
```

- 创建RBAC权限
```
cat traefik-rbac.yaml

## ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: ingress-traefik
  name: traefik-ingress-controller
---
## ClusterRole
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses/status
    verbs:
      - update
  - apiGroups:
      - traefik.containo.us
    resources:
      - ingressroutes
      - ingressroutetcps
      - ingressrouteudps
      - middlewares
      - tlsoptions
      - tlsstores
      - traefikservices
      - serverstransports
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - gatewayclasses
      - gatewayclasses/status
      - gateways
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - gatewayclasses/status
    verbs:
      - get
      - patch
      - update
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - gateways/status
    verbs:
      - get
      - patch
      - update
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - httproutes
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - networking.x-k8s.io
    resources:
      - httproutes/status
    verbs:
      - get
      - patch
      - update
---
## ClusterRoleBinding
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
  - kind: ServiceAccount
    name: traefik-ingress-controller
    namespace: ingress-traefik
```


- 创建 Traefik CRD ,rbac资源
```
kubectl apply -f traefik-crd.yaml
kubectl apply  -f traefik-rbac.yaml
```

###  创建Traefik配置文件
>下面配置中可以通过配置kubernetesCRD与kubernetesIngress和kubernetesGateway三项参数，让 Traefik 支持 CRD、Ingress与kubernetesGateway三种路由配置方式。 

```
cat traefik-config.yaml

kind: ConfigMap
apiVersion: v1
metadata:
  name: traefik-config
  namespace: ingress-traefik
data:
  traefik.yaml: |-
    ping: ""                    ## 启用 Ping
    serversTransport:
      insecureSkipVerify: true  ## Traefik 忽略验证代理服务的 TLS 证书
    api:
      insecure: true            ## 允许 HTTP 方式访问 API
      dashboard: true           ## 启用 Dashboard
      debug: false              ## 启用 Debug 调试模式
    metrics:
      prometheus: ""            ## 配置 Prometheus 监控指标数据，并使用默认配置
    entryPoints:
      web:
        address: ":80"          ## 配置 80 端口，并设置入口名称为 web
      websecure:
        address: ":443"         ## 配置 443 端口，并设置入口名称为 websecure
    providers:
      kubernetesCRD: ""         ## 启用 Kubernetes CRD 方式来配置路由规则
      kubernetesIngress: ""     ## 启用 Kubernetes Ingress 方式来配置路由规则
      kubernetesGateway: ""     ## 启用 Kubernetes Gateway API
    experimental:               
      kubernetesGateway: true   ## 允许使用 Kubernetes Gateway API
    log:
      filePath: ""              ## 设置调试日志文件存储路径，如果为空则输出到控制台
      level: error              ## 设置调试日志级别
      format: json              ## 设置调试日志格式
    accessLog:
      filePath: ""              ## 设置访问日志文件存储路径，如果为空则输出到控制台
      format: json              ## 设置访问调试日志格式
      bufferingSize: 0          ## 设置访问日志缓存行数
      filters:
        #statusCodes: ["200"]   ## 设置只保留指定状态码范围内的访问日志
        retryAttempts: true     ## 设置代理访问重试失败时，保留访问日志
        minDuration: 20         ## 设置保留请求时间超过指定持续时间的访问日志
      fields:                   ## 设置访问日志中的字段是否保留（keep 保留、drop 不保留）
        defaultMode: keep       ## 设置默认保留访问日志字段
        names:                  ## 针对访问日志特别字段特别配置保留模式
          ClientUsername: drop  
        headers:                ## 设置 Header 中字段是否保留
          defaultMode: keep     ## 设置默认保留 Header 中字段
          names:                ## 针对 Header 中特别字段特别配置保留模式
            User-Agent: redact
            Authorization: drop
            Content-Type: keep
    #tracing:                     ## 链路追踪配置,支持 zipkin、datadog、jaeger、instana、haystack 等 
    #  serviceName:               ## 设置服务名称（在链路追踪端收集后显示的服务名）
    #  zipkin:                    ## zipkin配置
    #    sameSpan: true           ## 是否启用 Zipkin SameSpan RPC 类型追踪方式
    #    id128Bit: true           ## 是否启用 Zipkin 128bit 的跟踪 ID
    #    sampleRate: 0.1          ## 设置链路日志采样率（可以配置0.0到1.0之间的值）
    #    httpEndpoint: http://localhost:9411/api/v2/spans     ## 配置 Zipkin Server 端点


kubectl apply -f traefik-config.yaml

configmap/traefik-config created		
```


###  安装Kubernetes Gateway CRD资源
Kubernetes 集群上默认没有安装 Service APIs，我们需要提前安装 Gateway API 的 CRD 资源，需要确保在 Traefik 安装之前启用 Service APIs 资源。

```
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0-rc1" | kubectl apply -f -

或者
kubectl apply -k "github.com/kubernetes-sigs/service-apis/config/crd?ref=v0.1.0"
```

### 创建Traefik
```
vim  traefik-deploy.yaml

apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: ingress-traefik
  labels:
    app: traefik
spec:
  ports:
    - name: web
      port: 80
    - name: websecure
      port: 443
    - name: admin
      port: 8080
  selector:
    app: traefik
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: traefik-ingress-controller
  namespace: ingress-traefik
  labels:
    app: traefik
spec:
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      name: traefik
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-ingress-controller
      terminationGracePeriodSeconds: 1
      containers:
        - image: traefik:v2.4.13
          name: traefik-ingress-lb
          ports:
            - name: web
              containerPort: 80
              hostPort: 80         ## 将容器端口绑定所在服务器的 80 端口
            - name: websecure
              containerPort: 443
              hostPort: 443        ## 将容器端口绑定所在服务器的 443 端口
            - name: admin
              containerPort: 8080  ## Traefik Dashboard 端口
          resources:
            limits:
              cpu: 2000m
              memory: 1024Mi
            requests:
              cpu: 1000m
              memory: 1024Mi
          securityContext:
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
          args:
            - --configfile=/config/traefik.yaml
          volumeMounts:
            - mountPath: "/config"
              name: "config"
          readinessProbe:
            httpGet:
              path: /ping
              port: 8080
            failureThreshold: 3
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5
          livenessProbe:
            httpGet:
              path: /ping
              port: 8080
            failureThreshold: 3
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5    
      volumes:
        - name: config
          configMap:
            name: traefik-config 
      tolerations:              ## 设置容忍所有污点，防止节点被设置污点
        - operator: "Exists"
      nodeSelector:             ## 设置node筛选器，在特定label的节点上启动
        IngressProxy: "true"

```

```
创建 Traefik
kubectl apply -f traefik-deploy.yaml
```

## 路由配置

### 创建 Traefik Ingress 路由规则
```
cat traefik-dashboard-in.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traefik-dashboard-ingress
  namespace: ingress-traefik
  annotations:
    kubernetes.io/ingress.class: traefik  
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: traefik.unionpaysmart.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: traefik
            port:
              number: 8080
```
```
kubectl apply -f traefik-dashboard-in.yaml  -n kube-system

ingress.networking.k8s.io/traefik-dashboard-ingress created
```

### 配置dns或者hosts
将域名指向 IngressProxy: "true" 标签的节点ip 
```

```

访问traefik界面验证

### 使用CRD方式配置Traefik路由规则
```
cat traefik-dashboard-route.yaml

apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard-route
  namespace: ingress-traefik
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`traefik-test.devopstack.cn`)
    kind: Rule
    services:
      - name: traefik
        port: 8080

验证
kubectl get ingressroutes.traefik.containo.us -n ingress-traefik

NAME                      AGE
traefik-dashboard-route   5m8s
```

### 使用Kubernetes Gateway API
>在Traefik v2.4版本后支持Kubernetes Gateway API提供的CRD方式创建路由规则. GatewayClass： GatewayClass 是基础结构提供程序定义的群集范围的资源。此资源表示可以实例化的网关类。一般该资源是用于支持多个基础设施提供商用途的，这里我们只部署一个即可。 Gateway： Gateway 与基础设施配置的生命周期是 1:1。当用户创建网关时，GatewayClass 控制器会提供或配置一些负载平衡基础设施。 HTTPRoute： HTTPRoute 是一种网关 API 类型，用于指定 HTTP 请求从网关侦听器到 API 对象（即服务）的路由行为。 

#### 创建GatewayClass
```
cat kubernetes-gatewayclass.yaml

apiVersion: networking.x-k8s.io/v1alpha1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controller: traefik.io/gateway-controller

```

#### 配置HTTP路由规则
- 创建Gateway资源
```
cat http-gateway.yaml

apiVersion: networking.x-k8s.io/v1alpha1
kind: Gateway
metadata: 
  name: http-gateway
  namespace: ingress-traefik
spec: 
  gatewayClassName: traefik
  listeners: 
    - protocol: HTTP
      port: 80
      routes: 
        kind: HTTPRoute
        namespaces:
          from: All
        selector:
          matchLabels:
            app: traefik
```

- 创建 HTTPRoute 资源
```
cat traefik-httproute.yaml

apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: traefik-dashboard-httproute
  namespace: ingress-traefik
  labels:
    app: traefik
spec:
  hostnames:
    - "traefik.devopstack.cn"
  rules:
    - matches:
        - path:
            type: Prefix
            value: /
      forwardTo:
        - serviceName: traefik
          port: 8080
          weight: 1
```

- 创建资源
```
kubectl apply -f http-gateway.yaml

gateway.networking.x-k8s.io/http-gateway created


kubectl apply -f traefik-httproute.yaml

httproute.networking.x-k8s.io/traefik-dashboard-httproute created


kubectl get httproutes.networking.x-k8s.io  -n ingress-traefik

NAME                          HOSTNAMES
traefik-dashboard-httproute   ["traefik.devopstack.cn"]
```
访问验证



## 中间件的使用
>什么是Traefik Middlewares中间件 中间件是 Traefik2.0 中一个非常有特色的功能，可以根据自己的各种需求去选择不同的中间件来满足服务，Traefik 官方已经内置了许多不同功能的中间件，其中一些可以修改请求，头信息，一些负责重定向，一些添加身份验证等等，而且中间件还可以通过链式组合的方式来适用各种情况。 Traefik Middlewares支持的功能如下 重试、压缩、缓冲、断路器 header 管理、错误页、中间件链 服务限流、同一主机并发请求限制 基本认证、IP 白名单、摘要认证、转发鉴权验证 regex 请求重定向、scheme 请求重定向、请求 URL 替换、regex 请求 URL 替换、删除 URL 前缀、regex 删除 URL 前缀、添加 URL 前缀 

### 通过Middleware配置http强制跳转https
