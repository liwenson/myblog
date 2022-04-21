---
title: k8s部署EFk
date: 2022-04-01 16:10
categories:
- k8s
tags:
- EFK
---
  
  
摘要: k8s部署EFK
<!-- more -->

EFK是 Elasticsearch，Fluentbit，Kibana的缩写，是k8s集群常用的日志解决方案。

- Elasticsearch 是一个搜索引擎，负责存储日志并提供查询接口；

- Fluentd(Fluent Bit) 负责从 Kubernetes 搜集日志，每个node节点上面的fluentd监控并收集该节点上面的系统日志，并将处理过后的日志信息发送给Elasticsearch；

- Kibana 提供了一个 Web GUI，用户可以浏览和搜索存储在 Elasticsearch 中的日志。

Fluent Bit 是Fluentd的子项目，相对于Fluentd更加轻量

## Fluentd vs Fluentbit vs Logstash

| |Fluentd | Fluent Bit| Logstash | Filebeat |
|---|---|---|---|---|
|开发语言 | C & Ruby | C | JRuby | GO|
|依赖 | 依赖 Ruby Gem | 无依赖，除非一些插件需要|依赖JVM|无依赖|
|内存占用 | 大约40MB | 大约650KB |大约1GB|大约30MB|
|插件 | 1000+插件 | 70+插件|1000+插件|略|
|使用范围 | 容器、服务器 | 容器、服务器、嵌入式Linux |容器、服务器|容器、服务器、嵌入式Linux|

## K8S日志收集架构

K8S 本身不提供原生的日志管理方案，日志无论是输出到 stdout/stderr 还是写入文件，如果没有作持久化处理的话，当 pod 被驱逐，node 宕机等情况下，日志都会丢失。所以需要开发人员提供一种日志收集方案以使日志的生命周期与 pod 、node 相互独立。

K8S 常见的日志收集架构有:

- 工作节点日志代理
- sidecar 容器日志代理
- 应用直接暴露日志

### 工作节点日志代理

通过 DaemonSet 将 logging-agent (日志收集组件)以pod的形式部署到每一个节点上，logging-agent 会监控日志文件（K8S会将自动节点上所有 Pod 的 stdout 和 stderr 重定向该日志文件），将日志发送到 Logging Backend（如 ES，Fluentd，S3 等）。

### sidecar容器日志代理

sidecar 容器日志代理同样需要一个节点级别的日志代理工作，这种场景主要是处理应用无法输出到 stdout/stderr的情形。

通过在 pod 里面部署一个容器（称为 sidecar ）运行 logging-agent ，logging-agent 将应用输出的日志（可以是文件、套接字，journald 等）输出到 sidecar 的 stdout/stderr ，节点的日志代理会捕获到这些日志将其发送至 Logging Backend。

### 应用直接暴露日志

应用内加入额外的日志处理逻辑，直接发送到 Logging Backend。

### 对比

| - |  原生方式 | DaemonSet方式 | Sidecar方式|
|---|---|---|---|
|采集日志类型 | 标准输出 | 标准输出+部分文件 | 文件|
|部署运维 | 低，原生支持 | 一般，需维护DaemonSet | 较高，每个需要采集日志的POD都需要部署sidecar容器|
|日志分类存储 | 无法实现 | 一般，可通过容器/路径等映射 | 每个POD可单独配置，灵活性高|
|多租户隔离 | 弱 | 一般，只能通过配置间隔离 | 强，通过容器进行隔离，可单独分配资源|
|支持集群规模 | 本地存储无限制，若使用syslog、fluentd会有单点限制 | 中小型规模，业务数最多支持百级别 | 无限制|
|资源占用 | 低，docker engine提供 | 较低，每个节点运行一个容器 | 较高，每个POD运行一个容器|
|查询便捷性 | 低 | 较高，可进行自定义的查询、统计 | 高，可根据业务特点进行定制|
|可定制性 | 低 | 低 | 高，每个POD单独配置|
|适用场景 | 测试、POC等非生产场景 | 功能单一型的集群 | 大型、混合型、PAAS型集群|

## EFK 实践

### 命名空间

```bash
kubectl create namespace logging
```

或者 `vim namespace-logging.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: logging
```

### Elasticsearch

#### 创建一个名为 elasticsearch 的无头服务

vim elasticsearch-svc.yaml

```yaml
kind: Service
apiVersion: v1
metadata:
  name: elasticsearch
  namespace: logging
  labels:
    app: elasticsearch
spec:
  selector:
    app: elasticsearch
  clusterIP: None
  ports:
    - port: 9200
      name: rest
    - port: 9300
      name: inter-node
```

#### 创建statefulset的资源清单

vim elasticsearch-statefulset.yaml

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: es
  namespace: logging
spec:
  serviceName: elasticsearch
  replicas: 3
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels: 
        app: elasticsearch
    spec:
      initContainers:
      - name: increase-vm-max-map-ulimit
        image: busybox
        command: ["/bin/bash", "-c", "sysctl -w vm.max_map_count=262144; ulimit -l unlimited"]
        securityContext:
          privileged: true
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:7.10.2
        ports:
        - name: rest
          containerPort: 9200
        - name: inter
          containerPort: 9300
        resources:
          limits:
            cpu: 1000m
          requests:
            cpu: 1000m
        volumeMounts:
        - name: data
          mountPath: /usr/share/elasticsearch/data
        env:
        - name: cluster.name
          value: k8s-logs

        - name: node.name
          valueFrom:
            fieldRef:
              fieldPath: metadata.name

        - name: cluster.initial_master_nodes
          value: "es-0,es-1,es-2"

        - name: discovery.zen.minimum_master_nodes
          value: "2"

        - name: discovery.seed_hosts
          value: "elasticsearch"
        - name: ES_JAVA_OPTS
          value: "-Xms2048m -Xmx2048m"
        - name: network.host
          value: "0.0.0.0"
  volumeClaimTemplates:
  - metadata:
      name: data
      labels:
        app: elasticsearch
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: managed-nfs-storage  ## 需求提前创建好nfs storageClass
      resources:
        requests:
          storage: 200Gi
```

部署

```bash
kubectl create -f elasticsearch-svc.yaml
kubectl create -f elasticsearch-statefulset.yaml
```

查看

```bash
kubectl get svc -n logging
kubectl get po -n logging
```

### Kibana

vim kibana.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: logging
  labels:
    app: kibana
spec:
  ports:
  - port: 5601
  type: NodePort
  selector:
    app: kibana
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: logging
  labels:
    app: kibana
spec:
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:7.6.2
        resources:
          limits:
            cpu: 1000m
          requests:
            cpu: 1000m
        env:
        - name: ELASTICSEARCH_HOSTS
          value: http://elasticsearch:9200
        ports:
        - containerPort: 5601
```

```bash
kubectl create -f kibana.yaml
```

```bash
kubectl get pods --namespace=logging
```

### Fluent bit

资源库地址：<https://github.com/fluent/fluent-bit-kubernetes-logging>

官方文档： <https://docs.fluentbit.io/manual/v/1.8/installation/kubernetes#installation>

Fluent Bit 必须部署为 DaemonSet，这样它就可以在 Kubernetes 集群的每个节点上使用。

#### RBAC

Kubernetes v1.21 及以下的版本

```bash
kubectl create namespace logging
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-service-account.yaml
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-role.yaml
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-role-binding.yaml
```

Kubernetes v1.22 版本

```bash
kubectl create namespace logging
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-service-account.yaml
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-role-1.22.yaml
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/fluent-bit-role-binding-1.22.yaml
```

或者

```bash
vim fluent-bit-service-rbac.yaml
```

```yaml
---
# source fluent-bit-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluent-bit
  namespace: logging

---
# source fluent-bit-role.yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: fluent-bit-read
rules:
- apiGroups: [""]
  resources:
  - namespaces
  - pods
  verbs: ["get", "list", "watch"]

---
# source fluent-bit-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: fluent-bit-read
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluent-bit-read
subjects:
- kind: ServiceAccount
  name: fluent-bit
  namespace: logging
```


#### Fluent Bit to Elasticsearch

##### 创建ConfigMap

创建 Fluent Bit DaemonSet 使用的 ConfigMap

```bash
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/elasticsearch/fluent-bit-configmap.yaml

```

如果集群使用 CRI 运行时，例如 containerd 或 CRI-O，需要将input-kubernetes.conf 中 Parser的描述从 docker 改为cri。

```bash
vim fluent-bit-configmap.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: logging
  labels:
    k8s-app: fluent-bit
data:
  # Configuration files: server, input, filters and output
  # ======================================================
  fluent-bit.conf: |
    [SERVICE]
        Flush         1
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf
        HTTP_Server   On
        HTTP_Listen   0.0.0.0
        HTTP_Port     2020

    @INCLUDE input-kubernetes.conf
    @INCLUDE filter-kubernetes.conf
    @INCLUDE output-elasticsearch.conf

  input-kubernetes.conf: |
    [INPUT]
        Name              tail
        Tag               kube.*
        Path              /var/log/containers/*.log
        Parser            docker           #  指定使用 docker 解析器来处理日志，定义于 parser.conf 中
        DB                /var/log/flb_kube.db
        Mem_Buf_Limit     5MB
        Skip_Long_Lines   On
        Refresh_Interval  10

  filter-kubernetes.conf: |
    [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix     kube.var.log.containers.
        Merge_Log           On
        Merge_Log_Key       log_processed
        K8S-Logging.Parser  On
        K8S-Logging.Exclude Off

    [FILTER]
        Name             nest  
        Match            *
        Operation        lift
        Nested_under     log   # 将 log 下的所有 json 字段上移一级

  output-elasticsearch.conf: |
    [OUTPUT]
        Name            es
        Match           *
        Host            ${FLUENT_ELASTICSEARCH_HOST}
        Port            ${FLUENT_ELASTICSEARCH_PORT}
        Logstash_Format On
        Replace_Dots    On
        Retry_Limit     False

  parsers.conf: |
    [PARSER]
        Name   apache
        Format regex
        Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z

    [PARSER]
        Name   apache2
        Format regex
        Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^ ]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z

    [PARSER]
        Name   apache_error
        Format regex
        Regex  ^\[[^ ]* (?<time>[^\]]*)\] \[(?<level>[^\]]*)\](?: \[pid (?<pid>[^\]]*)\])?( \[client (?<client>[^\]]*)\])? (?<message>.*)$

    [PARSER]
        Name   nginx
        Format regex
        Regex ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z

    [PARSER]
        Name   json
        Format json
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z

    [PARSER]
        Name        docker
        Format      json
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L
        Time_Keep   On

    [PARSER]
        # http://rubular.com/r/tjUt3Awgg4
        Name cri
        Format regex
        Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<message>.*)$
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z

    [PARSER]
        Name        syslog
        Format      regex
        Regex       ^\<(?<pri>[0-9]+)\>(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$
        Time_Key    time
        Time_Format %b %d %H:%M:%S
```

##### Fluent Bit

```bash
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/elasticsearch/fluent-bit-ds.yaml
```

```bash
vim fluent-bit-ds.yaml
```

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: logging
  labels:
    k8s-app: fluent-bit-logging
    version: v1
    kubernetes.io/cluster-service: "true"
spec:
  selector:
    matchLabels:
      k8s-app: fluent-bit-logging
  template:
    metadata:
      labels:
        k8s-app: fluent-bit-logging
        version: v1
        kubernetes.io/cluster-service: "true"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "2020"
        prometheus.io/path: /api/v1/metrics/prometheus
    spec:
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:1.9
        imagePullPolicy: Always
        ports:
          - containerPort: 2020
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc/
      terminationGracePeriodSeconds: 10
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
      serviceAccountName: fluent-bit
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      - operator: "Exists"
        effect: "NoExecute"
      - operator: "Exists"
        effect: "NoSchedule"

```

如果 docker 的根目录路径修改过，需要将 varlibdockercontainers 修改为对应的目录

```yaml
      - name: varlibdockercontainers
        hostPath:
          path: /home/docker/containers
```

#### Fluent Bit to Kafka

创建 Fluent Bit DaemonSet 使用的 ConfigMap

```bash
kubectl create -f <https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/kafka/fluent-bit-configmap.yaml>
```

Fluent Bit DaemonSet 可与 Kafka 在一个普通的 Kubernetes 集群上一起使用

```bash
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/kafka/fluent-bit-ds.yaml
```

gohangout

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: gohangout-logging
  name: gohangout
  namespace: logging
spec:
  replicas: 1  #pod副本数
  selector:
    matchLabels:
      k8s-app: gohangout-logging
  template:
    metadata:
      labels:
        k8s-app: gohangout-logging
    spec:
      nodeSelector:  #设置pod运行的节点
        nodeRole: tool
      tolerations: #设置节点容忍度
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
      containers:
      - image: rmself/gohangout:1.8.1
        imagePullPolicy: IfNotPresent ##Always,IfNotPresent,Never
        command: ["printenv"]
        name: gohangout
        livenessProbe: #健康检查
          httpGet:   # tcpSocket,exec
            path: /
            port: 8080
          initialDelaySeconds: 60 #pod初始化时间
          timeoutSeconds: 20
        readinessProbe: #健康检查
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 60
          timeoutSeconds: 20
        resources:  #资源限制
          limits:
            cpu: 100m
            memory: 100Mi
          requests:
            cpu: 10m
            memory: 10Mi
```

configMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gohangout-config
  namespace: logging
  labels:
    k8s-app: gohangout
data:
  # Configuration files: server, input, filters and output
  # ======================================================
  gohangout.conf: |
  inputs:
    - Kafka:
        topic:
            nginxlog: 3
        codec: json
        consumer_settings:
            bootstrap.servers: '10.200.76.53:9092,10.200.76.54:9092,10.200.76.55:9092'
            group.id: 'nginx'
  filters:
    - Grok:
        src: message
        pattern_paths:
          - '/opt/gohangout/patterns'
        match:
          - '%{IPV4:remote_addr} - (%{USERNAME:remote_user}|-) \[%{HTTPDATE:time_local}\] \"%{URIHOST:domain_name}\" \"%{WORD:request_method} %{URIPATHPARAM:request_uri} HTTP/%{NUMBER:http_protocol}\" \"%{NUMBER:request_time}\" %{NUMBER:http_status} %{NUMBER:body_bytes_sent} \"%{GREEDYDATA:http_referer}\" \"%{GREEDYDATA:http_user_agent}\" \"(%{IPV4:http_x_forwarded_for}|-)\"'
        remove_fields: ['message']
    - Add:
        overwrite: true
        fields:
          hostname: '$.agent.hostname'
    - Date:
        src: time_local
        target: '@timestamp'
        location: 'Asia/Shanghai'
        overwrite: true
        formats:
          - '2006-01-02 15:04:05'
          - 'RFC3339'
          - '2006-01-02T15:04:05'
          - '2006-01-02T15:04:05Z07:00'
          - '2006-01-02T15:04:05Z0700'
          - '2006-01-02'
          - 'UNIX'
          - 'UNIX_MS'
    - Remove:
        fields: ['log', 'message','ecs','@metadata','input','host','cloud','agent','logname','today','yy','m','mm','tags']

  outputs:
    - Elasticsearch:
        hosts:
          - 'http://elastic:gprYpiYWaIXh@10.200.92.47:9200'
          - 'http://elastic:gprYpiYWaIXh@10.200.92.48:9200'
          - 'http://elastic:gprYpiYWaIXh@10.200.92.49:9200'
        index: 'nginx_%{+20060102}' #golang里面的渲染方式就是用数字, 而不是用YYMM.
        index_type: "logs"
        bulk_actions: 2000
        bulk_size: 10
        flush_interval: 30
        es_version: 7
```
