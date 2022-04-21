---
title: k8s部署openEBS
date: 2022-04-14 14:32
categories:
- k8s
tags:
- openEBS
---
  
  
摘要: k8s 中部署openEBS
<!-- more -->

[TOC]

## 介绍

OpenEBS 是一种模拟了 AWS 的 EBS、阿里云的云盘等块存储实现的基于容器的存储开源软件。OpenEBS 是一种基于 CAS(Container Attached Storage) 理念的容器解决方案，其核心理念是存储和应用一样采用微服务架构，并通过 Kubernetes 来做资源编排。其架构实现上，每个卷的 Controller 都是一个单独的 Pod，且与应用 Pod 在同一个节点，卷的数据使用多个 Pod 进行管理。

OpenEBS 有很多组件，可以分为以下几类：

    控制平面组件 - 管理 OpenEBS 卷容器，通常会用到容器编排软件的功能
    数据平面组件 - 为应用程序提供数据存储，包含 Jiva 和 cStor 两个存储后端
    节点磁盘管理器 - 发现、监控和管理连接到 Kubernetes 节点的媒体
    与云原生工具的整合 - 与 Prometheus、Grafana、Fluentd 和 Jaeger 进行整合。

### 控制平面组件

OpenEBS 集群的控制平面通常被称为 Maya，控制平面负责供应卷、相关的卷操作，如快照、制作克隆、创建存储策略、执行存储策略、导出卷指标供 Prometheus/grafana 消费等.

OpenEBS 控制平面 Maya 实现了创建超融合的 OpenEBS，并将其挂载到如 Kubernetes 调度引擎上，用来扩展特定的容器编排系统提供的存储功能；OpenEBS 的控制平面也是基于微服务的，通过不同的组件实现存储管理功能、监控、容器编排插件等功能。

目前，OpenEBS 供应器只支持一种类型的绑定，即 iSCSI。

### 数据平面组件

penEBS 持久化存储卷通过 Kubernetes 的 PV 来创建，使用 iSCSI 来实现，数据保存在节点上或者云存储中。OpenEBS 的卷完全独立于用户的应用的生命周期来管理，和 Kuberentes 中 PV 的思路一致。OpenEBS 卷为容器提供持久化存储，具有针对系统故障的弹性，更快地访问存储，快照和备份功能。同时还提供了监控使用情况和执行 QoS 策略的机制。

目前，OpenEBS 提供了两个可以轻松插入的存储引擎。这两个引擎分别叫做 Jiva 和 cStor。这两个存储引擎都完全运行在Linux 用户空间中，并且基于微服务架构。

下面列出了支持 OpenEBS 持久卷的各种存储引擎的开发状态。

| 存储引擎 | 状态 | 详情 |
|---|---|---|
|Jiva | stable | 最适合在使用临时存储的 Kubernetes 工作节点上运行 Replicated Block Storage |
|cStor | beta | 在具有块设备的节点上的首选。如果需要快照和克隆，建议使用此选项 |
|Local Volumes | beta  Kubernetes 节点上的本地存储-最适合需要低延迟存储的分布式应用程序 |
|Mayastor | alpha | 一种全新的存储引擎，比肩本地存储的工作效率，同时也提供复制等存储服务。快照和克隆的功能支持正在开发中 |

#### Jiva

Jiva 存储引擎是基于 Rancher 的 LongHorn 和 gotgt 开发的,采用 GO 语言编写，运行在用户空间。LongHorn 控制器将传入的 IO 同步复制到 LongHorn 复制器上。复制器考虑以 Linux 稀疏文件为基础，进行动态供应、快照、重建等存储功能。

#### cStor

cStor 数据引擎是用C语言编写的，具有高性能的 iSCSI 目标和Copy-On-Write 块系统，可提供数据完整性、数据弹性和时间点快照和克隆。cStor 具有池功能，可将节点上的磁盘以镜像式或 RAIDZ 模式聚合，以提供更大的容量和性能单位。

#### Local PV

对于那些不需要存储级复制的应用，Local PV 可能是不错的选择，因为它能提供更高的性能。OpenEBS LocalPV 与 Kubernetes LocalPV 类似，只不过它是由 OpenEBS 控制平面动态调配的，就像其他常规 PV 一样。OpenEBS LocalPV 有两种类型--主机路径 LocalPV 或设备 LocalPV，主机路径 LocalPV 指的是主机上的一个子目录，设备 LocalPV 指的是节点上的一个被发现的磁盘（直接连接或网络连接）。OpenEBS 引入了一个LocalPV 供应器，用于根据 PVC 和存储类规范中的一些标准选择匹配的磁盘或主机路径。

#### 存储策略

OpenEBS的存储策略使用StorageClaass实现，包括如下的StorageClass：

    openebs-cassandra
    openebs-es-data-sc
    openebs-jupyter
    openebs-kafka
    openebs-mongodb
    openebs-percona
    openebs-redis
    openebs-standalone
    openebs-standard
    openebs-zk

### 节点磁盘管理器

Node Disk Manager (NDM)填补了使用 Kubernetes 管理有状态应用的持久性存储所需的工具链中的空白。容器时代的 DevOps 架构师必须以自动化的方式服务于应用和应用开发者的基础设施需求，以提供跨环境的弹性和一致性。这些要求意味着存储栈本身必须非常灵活，以便 Kubernetes 和云原生生态系统中的其他软件可以轻松使用这个栈。NDM 在 Kubernetes 的存储栈中起到了基础性的作用，它将不同的磁盘统一起来，并通过将它们识别为 Kubernetes 对象来提供部分池化的能力。同时， NDM 还可以发现、供应、监控和管理底层磁盘，这样Kubernetes PV 供应器（如 OpenEBS 和其他存储系统和Prometheus）可以管理磁盘子系统。

## 建议

建议以下场景使用OpenEBS作为后端存储

    单机测试环境
    多机实验/演示环境

## 参考

```txt
https://weiliang-ms.github.io/wl-awesome/2.%E5%AE%B9%E5%99%A8/k8s/storage/OpenEBS.html#local-pv-device%E5%AE%9E%E8%B7%B5
```

## 准备

OpenEBS依赖与iSCSI做存储管理，因此需要先确保您的集群上已有安装openiscsi。

如果您使用kubeadm，容器方式安装的kublet，那么其中会自带iSCSI，不需要再手动安装，如果是直接使用二进制形式在裸机上安装的kubelet，则需要自己安装iSCSI。

OpenEBS需要使用iSCSI作为存储协议，而CentOS上默认是没有安装该软件的，因此需要手动安装。

## 部署

通过 operator 启动 OpenEBS 服务

应用这个 yaml 文件

```bash
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

## 查看

```bash
kubectl get pods -n openebs

NAME                                            READY   STATUS    RESTARTS   AGE
openebs-localpv-provisioner-879c89d76-5s8lb     1/1     Running   0          98s
openebs-ndm-7wht4                               1/1     Running   0          99s
openebs-ndm-cluster-exporter-7b547c4d64-4npjf   1/1     Running   0          99s
openebs-ndm-node-exporter-g9hwg                 1/1     Running   0          99s
openebs-ndm-node-exporter-r64hc                 1/1     Running   0          99s
openebs-ndm-node-exporter-vql2r                 1/1     Running   0          99s
openebs-ndm-operator-65b586dfb4-rjh7s           1/1     Running   0          99s
openebs-ndm-qf95f                               1/1     Running   0          99s
openebs-ndm-rhmwz                               1/1     Running   0          99s
```

默认情况下 OpenEBS 还会安装一些内置的 StorageClass 对象：

```bash
kubectl get sc

NAME                  PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
managed-nfs-storage   fuseim.pri/ifs     Retain          Immediate              false                  2d17h
openebs-device        openebs.io/local   Delete          WaitForFirstConsumer   false                  3m6s
openebs-hostpath      openebs.io/local   Delete          WaitForFirstConsumer   false                  3m6s

```

网络不好可以复制文本

```yaml

# This manifest deploys the OpenEBS control plane components, 
# with associated CRs & RBAC rules
# NOTE: On GKE, deploy the openebs-operator.yaml in admin context
#
# NOTE: The Jiva and cStor components previously included in the Operator File  
#  are now removed and it is recommended for users to use cStor and Jiva CSI operators. 
#  To upgrade your Jiva and cStor volumes to CSI, please checkout the documentation at:
#  https://github.com/openebs/upgrade
#
# To deploy the legacy Jiva and cStor:
# kubectl apply -f https://openebs.github.io/charts/legacy-openebs-operator.yaml
# 
# To deploy cStor CSI:
# kubectl apply -f https://openebs.github.io/charts/cstor-operator.yaml
#
# To deploy Jiva CSI:
# kubectl apply -f https://openebs.github.io/charts/jiva-operator.yaml
#

# Create the OpenEBS namespace
apiVersion: v1
kind: Namespace
metadata:
  name: openebs
---
# Create Maya Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: openebs-maya-operator
  namespace: openebs
---
# Define Role that allows operations on K8s pods/deployments
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: openebs-maya-operator
rules:
- apiGroups: ["*"]
  resources: ["nodes", "nodes/proxy"]
  verbs: ["*"]
- apiGroups: ["*"]
  resources: ["namespaces", "services", "pods", "pods/exec", "deployments", "deployments/finalizers", "replicationcontrollers", "replicasets", "events", "endpoints", "configmaps", "secrets", "jobs", "cronjobs"]
  verbs: ["*"]
- apiGroups: ["*"]
  resources: ["statefulsets", "daemonsets"]
  verbs: ["*"]
- apiGroups: ["*"]
  resources: ["resourcequotas", "limitranges"]
  verbs: ["list", "watch"]
- apiGroups: ["*"]
  resources: ["ingresses", "horizontalpodautoscalers", "verticalpodautoscalers", "certificatesigningrequests"]
  verbs: ["list", "watch"]
- apiGroups: ["*"]
  resources: ["storageclasses", "persistentvolumeclaims", "persistentvolumes"]
  verbs: ["*"]
- apiGroups: ["volumesnapshot.external-storage.k8s.io"]
  resources: ["volumesnapshots", "volumesnapshotdatas"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: [ "get", "list", "create", "update", "delete", "patch"]
- apiGroups: ["openebs.io"]
  resources: [ "*"]
  verbs: ["*" ]
- apiGroups: ["cstor.openebs.io"]
  resources: [ "*"]
  verbs: ["*" ]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["get", "watch", "list", "delete", "update", "create"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"]
  verbs: ["get", "create", "list", "delete", "update", "patch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
- apiGroups: ["*"]
  resources: ["poddisruptionbudgets"]
  verbs: ["get", "list", "create", "delete", "watch"]
---
# Bind the Service Account with the Role Privileges.
# TODO: Check if default account also needs to be there
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: openebs-maya-operator
subjects:
- kind: ServiceAccount
  name: openebs-maya-operator
  namespace: openebs
roleRef:
  kind: ClusterRole
  name: openebs-maya-operator
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.5.0
  creationTimestamp: null
  name: blockdevices.openebs.io
spec:
  group: openebs.io
  names:
    kind: BlockDevice
    listKind: BlockDeviceList
    plural: blockdevices
    shortNames:
    - bd
    singular: blockdevice
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - jsonPath: .spec.nodeAttributes.nodeName
      name: NodeName
      type: string
    - jsonPath: .spec.path
      name: Path
      priority: 1
      type: string
    - jsonPath: .spec.filesystem.fsType
      name: FSType
      priority: 1
      type: string
    - jsonPath: .spec.capacity.storage
      name: Size
      type: string
    - jsonPath: .status.claimState
      name: ClaimState
      type: string
    - jsonPath: .status.state
      name: Status
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        description: BlockDevice is the Schema for the blockdevices API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: DeviceSpec defines the properties and runtime status of a BlockDevice
            properties:
              aggregateDevice:
                description: AggregateDevice was intended to store the hierarchical information in cases of LVM. However this is currently not implemented and may need to be re-looked into for better design. To be deprecated
                type: string
              capacity:
                description: Capacity
                properties:
                  logicalSectorSize:
                    description: LogicalSectorSize is blockdevice logical-sector size in bytes
                    format: int32
                    type: integer
                  physicalSectorSize:
                    description: PhysicalSectorSize is blockdevice physical-Sector size in bytes
                    format: int32
                    type: integer
                  storage:
                    description: Storage is the blockdevice capacity in bytes
                    format: int64
                    type: integer
                required:
                - storage
                type: object
              claimRef:
                description: ClaimRef is the reference to the BDC which has claimed this BD
                properties:
                  apiVersion:
                    description: API version of the referent.
                    type: string
                  fieldPath:
                    description: 'If referring to a piece of an object instead of an entire object, this string should contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2]. For example, if the object reference is to a container within a pod, this would take on a value like: "spec.containers{name}" (where "name" refers to the name of the container that triggered the event) or if no container name is specified "spec.containers[2]" (container with index 2 in this pod). This syntax is chosen only to have some well-defined way of referencing a part of an object. TODO: this design is not final and this field is subject to change in the future.'
                    type: string
                  kind:
                    description: 'Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
                    type: string
                  name:
                    description: 'Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names'
                    type: string
                  namespace:
                    description: 'Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/'
                    type: string
                  resourceVersion:
                    description: 'Specific resourceVersion to which this reference is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency'
                    type: string
                  uid:
                    description: 'UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids'
                    type: string
                type: object
              details:
                description: Details contain static attributes of BD like model,serial, and so forth
                properties:
                  compliance:
                    description: Compliance is standards/specifications version implemented by device firmware  such as SPC-1, SPC-2, etc
                    type: string
                  deviceType:
                    description: DeviceType represents the type of device like sparse, disk, partition, lvm, crypt
                    enum:
                    - disk
                    - partition
                    - sparse
                    - loop
                    - lvm
                    - crypt
                    - dm
                    - mpath
                    type: string
                  driveType:
                    description: DriveType is the type of backing drive, HDD/SSD
                    enum:
                    - HDD
                    - SSD
                    - Unknown
                    - ""
                    type: string
                  firmwareRevision:
                    description: FirmwareRevision is the disk firmware revision
                    type: string
                  hardwareSectorSize:
                    description: HardwareSectorSize is the hardware sector size in bytes
                    format: int32
                    type: integer
                  logicalBlockSize:
                    description: LogicalBlockSize is the logical block size in bytes reported by /sys/class/block/sda/queue/logical_block_size
                    format: int32
                    type: integer
                  model:
                    description: Model is model of disk
                    type: string
                  physicalBlockSize:
                    description: PhysicalBlockSize is the physical block size in bytes reported by /sys/class/block/sda/queue/physical_block_size
                    format: int32
                    type: integer
                  serial:
                    description: Serial is serial number of disk
                    type: string
                  vendor:
                    description: Vendor is vendor of disk
                    type: string
                type: object
              devlinks:
                description: DevLinks contains soft links of a block device like /dev/by-id/... /dev/by-uuid/...
                items:
                  description: DeviceDevLink holds the mapping between type and links like by-id type or by-path type link
                  properties:
                    kind:
                      description: Kind is the type of link like by-id or by-path.
                      enum:
                      - by-id
                      - by-path
                      type: string
                    links:
                      description: Links are the soft links
                      items:
                        type: string
                      type: array
                  type: object
                type: array
              filesystem:
                description: FileSystem contains mountpoint and filesystem type
                properties:
                  fsType:
                    description: Type represents the FileSystem type of the block device
                    type: string
                  mountPoint:
                    description: MountPoint represents the mountpoint of the block device.
                    type: string
                type: object
              nodeAttributes:
                description: NodeAttributes has the details of the node on which BD is attached
                properties:
                  nodeName:
                    description: NodeName is the name of the Kubernetes node resource on which the device is attached
                    type: string
                type: object
              parentDevice:
                description: "ParentDevice was intended to store the UUID of the parent Block Device as is the case for partitioned block devices. \n For example: /dev/sda is the parent for /dev/sda1 To be deprecated"
                type: string
              partitioned:
                description: Partitioned represents if BlockDevice has partitions or not (Yes/No) Currently always default to No. To be deprecated
                enum:
                - "Yes"
                - "No"
                type: string
              path:
                description: Path contain devpath (e.g. /dev/sdb)
                type: string
            required:
            - capacity
            - devlinks
            - nodeAttributes
            - path
            type: object
          status:
            description: DeviceStatus defines the observed state of BlockDevice
            properties:
              claimState:
                description: ClaimState represents the claim state of the block device
                enum:
                - Claimed
                - Unclaimed
                - Released
                type: string
              state:
                description: State is the current state of the blockdevice (Active/Inactive/Unknown)
                enum:
                - Active
                - Inactive
                - Unknown
                type: string
            required:
            - claimState
            - state
            type: object
        type: object
    served: true
    storage: true
    subresources: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []

---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.5.0
  creationTimestamp: null
  name: blockdeviceclaims.openebs.io
spec:
  group: openebs.io
  names:
    kind: BlockDeviceClaim
    listKind: BlockDeviceClaimList
    plural: blockdeviceclaims
    shortNames:
    - bdc
    singular: blockdeviceclaim
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - jsonPath: .spec.blockDeviceName
      name: BlockDeviceName
      type: string
    - jsonPath: .status.phase
      name: Phase
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: Age
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        description: BlockDeviceClaim is the Schema for the blockdeviceclaims API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: DeviceClaimSpec defines the request details for a BlockDevice
            properties:
              blockDeviceName:
                description: BlockDeviceName is the reference to the block-device backing this claim
                type: string
              blockDeviceNodeAttributes:
                description: BlockDeviceNodeAttributes is the attributes on the node from which a BD should be selected for this claim. It can include nodename, failure domain etc.
                properties:
                  hostName:
                    description: HostName represents the hostname of the Kubernetes node resource where the BD should be present
                    type: string
                  nodeName:
                    description: NodeName represents the name of the Kubernetes node resource where the BD should be present
                    type: string
                type: object
              deviceClaimDetails:
                description: Details of the device to be claimed
                properties:
                  allowPartition:
                    description: AllowPartition represents whether to claim a full block device or a device that is a partition
                    type: boolean
                  blockVolumeMode:
                    description: 'BlockVolumeMode represents whether to claim a device in Block mode or Filesystem mode. These are use cases of BlockVolumeMode: 1) Not specified: VolumeMode check will not be effective 2) VolumeModeBlock: BD should not have any filesystem or mountpoint 3) VolumeModeFileSystem: BD should have a filesystem and mountpoint. If DeviceFormat is    specified then the format should match with the FSType in BD'
                    type: string
                  formatType:
                    description: Format of the device required, eg:ext4, xfs
                    type: string
                type: object
              deviceType:
                description: DeviceType represents the type of drive like SSD, HDD etc.,
                nullable: true
                type: string
              hostName:
                description: Node name from where blockdevice has to be claimed. To be deprecated. Use NodeAttributes.HostName instead
                type: string
              resources:
                description: Resources will help with placing claims on Capacity, IOPS
                properties:
                  requests:
                    additionalProperties:
                      anyOf:
                      - type: integer
                      - type: string
                      pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                      x-kubernetes-int-or-string: true
                    description: 'Requests describes the minimum resources required. eg: if storage resource of 10G is requested minimum capacity of 10G should be available TODO for validating'
                    type: object
                required:
                - requests
                type: object
              selector:
                description: Selector is used to find block devices to be considered for claiming
                properties:
                  matchExpressions:
                    description: matchExpressions is a list of label selector requirements. The requirements are ANDed.
                    items:
                      description: A label selector requirement is a selector that contains values, a key, and an operator that relates the key and values.
                      properties:
                        key:
                          description: key is the label key that the selector applies to.
                          type: string
                        operator:
                          description: operator represents a key's relationship to a set of values. Valid operators are In, NotIn, Exists and DoesNotExist.
                          type: string
                        values:
                          description: values is an array of string values. If the operator is In or NotIn, the values array must be non-empty. If the operator is Exists or DoesNotExist, the values array must be empty. This array is replaced during a strategic merge patch.
                          items:
                            type: string
                          type: array
                      required:
                      - key
                      - operator
                      type: object
                    type: array
                  matchLabels:
                    additionalProperties:
                      type: string
                    description: matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels map is equivalent to an element of matchExpressions, whose key field is "key", the operator is "In", and the values array contains only "value". The requirements are ANDed.
                    type: object
                type: object
            type: object
          status:
            description: DeviceClaimStatus defines the observed state of BlockDeviceClaim
            properties:
              phase:
                description: Phase represents the current phase of the claim
                type: string
            required:
            - phase
            type: object
        type: object
    served: true
    storage: true
    subresources: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []
---
# This is the node-disk-manager related config.
# It can be used to customize the disks probes and filters
apiVersion: v1
kind: ConfigMap
metadata:
  name: openebs-ndm-config
  namespace: openebs
  labels:
    openebs.io/component-name: ndm-config
data:
  # udev-probe is default or primary probe it should be enabled to run ndm
  # filterconfigs contains configs of filters. To provide a group of include
  # and exclude values add it as , separated string
  node-disk-manager.config: |
    probeconfigs:
      - key: udev-probe
        name: udev probe
        state: true
      - key: seachest-probe
        name: seachest probe
        state: false
      - key: smart-probe
        name: smart probe
        state: true
    filterconfigs:
      - key: os-disk-exclude-filter
        name: os disk exclude filter
        state: true
        exclude: "/,/etc/hosts,/boot"
      - key: vendor-filter
        name: vendor filter
        state: true
        include: ""
        exclude: "CLOUDBYT,OpenEBS"
      - key: path-filter
        name: path filter
        state: true
        include: ""
        exclude: "/dev/loop,/dev/fd0,/dev/sr0,/dev/ram,/dev/md,/dev/dm-,/dev/rbd,/dev/zd"
    # metconfig can be used to decorate the block device with different types of labels
    # that are available on the node or come in a device properties.
    # node labels - the node where bd is discovered. A whitlisted label prefixes
    # attribute labels - a property of the BD can be added as a ndm label as ndm.io/<property>=<property-value>
    metaconfigs:
      - key: node-labels
        name: node labels
        pattern: ""
      - key: device-labels
        name: device labels
        type: ""
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: openebs-ndm
  namespace: openebs
  labels:
    name: openebs-ndm
    openebs.io/component-name: ndm
    openebs.io/version: 3.1.0
spec:
  selector:
    matchLabels:
      name: openebs-ndm
      openebs.io/component-name: ndm
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: openebs-ndm
        openebs.io/component-name: ndm
        openebs.io/version: 3.1.0
    spec:
      # By default the node-disk-manager will be run on all kubernetes nodes
      # If you would like to limit this to only some nodes, say the nodes
      # that have storage attached, you could label those node and use
      # nodeSelector.
      #
      # e.g. label the storage nodes with - "openebs.io/nodegroup"="storage-node"
      # kubectl label node <node-name> "openebs.io/nodegroup"="storage-node"
      #nodeSelector:
      #  "openebs.io/nodegroup": "storage-node"
      serviceAccountName: openebs-maya-operator
      hostNetwork: true
      # host PID is used to check status of iSCSI Service when the NDM
      # API service is enabled
      #hostPID: true
      containers:
      - name: node-disk-manager
        image: openebs/node-disk-manager:1.8.0
        args:
          - -v=4
        # The feature-gate is used to enable the new UUID algorithm.
          - --feature-gates="GPTBasedUUID"
        # Use partition table UUID instead of create single partition to get
        # partition UUID. Require `GPTBasedUUID` to be enabled with.
        # - --feature-gates="PartitionTableUUID"
        # Detect changes to device size, filesystem and mount-points without restart.
        # - --feature-gates="ChangeDetection"
        # The feature gate is used to start the gRPC API service. The gRPC server
        # starts at 9115 port by default. This feature is currently in Alpha state
        # - --feature-gates="APIService"
        # The feature gate is used to enable NDM, to create blockdevice resources
        # for unused partitions on the OS disk
        # - --feature-gates="UseOSDisk"
        imagePullPolicy: IfNotPresent
        securityContext:
          privileged: true
        volumeMounts:
        - name: config
          mountPath: /host/node-disk-manager.config
          subPath: node-disk-manager.config
          readOnly: true
          # make udev database available inside container
        - name: udev
          mountPath: /run/udev
        - name: procmount
          mountPath: /host/proc
          readOnly: true
        - name: devmount
          mountPath: /dev
        - name: basepath
          mountPath: /var/openebs/ndm
        - name: sparsepath
          mountPath: /var/openebs/sparse
        env:
        # namespace in which NDM is installed will be passed to NDM Daemonset
        # as environment variable
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        # pass hostname as env variable using downward API to the NDM container
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        # specify the directory where the sparse files need to be created.
        # if not specified, then sparse files will not be created.
        - name: SPARSE_FILE_DIR
          value: "/var/openebs/sparse"
        # Size(bytes) of the sparse file to be created.
        - name: SPARSE_FILE_SIZE
          value: "10737418240"
        # Specify the number of sparse files to be created
        - name: SPARSE_FILE_COUNT
          value: "0"
        livenessProbe:
          exec:
            command:
            - pgrep
            - "ndm"
          initialDelaySeconds: 30
          periodSeconds: 60
      volumes:
      - name: config
        configMap:
          name: openebs-ndm-config
      - name: udev
        hostPath:
          path: /run/udev
          type: Directory
      # mount /proc (to access mount file of process 1 of host) inside container
      # to read mount-point of disks and partitions
      - name: procmount
        hostPath:
          path: /proc
          type: Directory
      - name: devmount
      # the /dev directory is mounted so that we have access to the devices that
      # are connected at runtime of the pod.
        hostPath:
          path: /dev
          type: Directory
      - name: basepath
        hostPath:
          path: /var/openebs/ndm
          type: DirectoryOrCreate
      - name: sparsepath
        hostPath:
          path: /var/openebs/sparse
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openebs-ndm-operator
  namespace: openebs
  labels:
    name: openebs-ndm-operator
    openebs.io/component-name: ndm-operator
    openebs.io/version: 3.1.0
spec:
  selector:
    matchLabels:
      name: openebs-ndm-operator
      openebs.io/component-name: ndm-operator
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        name: openebs-ndm-operator
        openebs.io/component-name: ndm-operator
        openebs.io/version: 3.1.0
    spec:
      serviceAccountName: openebs-maya-operator
      containers:
        - name: node-disk-operator
          image: openebs/node-disk-operator:1.8.0
          imagePullPolicy: IfNotPresent
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            # the service account of the ndm-operator pod
            - name: SERVICE_ACCOUNT
              valueFrom:
                fieldRef:
                  fieldPath: spec.serviceAccountName
            - name: OPERATOR_NAME
              value: "node-disk-operator"
            - name: CLEANUP_JOB_IMAGE
              value: "openebs/linux-utils:3.1.0"
            # OPENEBS_IO_IMAGE_PULL_SECRETS environment variable is used to pass the image pull secrets
            # to the cleanup pod launched by NDM operator
            #- name: OPENEBS_IO_IMAGE_PULL_SECRETS
            #  value: ""
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8585
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8585
            initialDelaySeconds: 5
            periodSeconds: 10
---
# Create NDM cluster exporter deployment.
# This is an optional component and is not required for the basic
# functioning of NDM
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openebs-ndm-cluster-exporter
  namespace: openebs
  labels:
    name: openebs-ndm-cluster-exporter
    openebs.io/component-name: ndm-cluster-exporter
    openebs.io/version: 3.1.0
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      name: openebs-ndm-cluster-exporter
      openebs.io/component-name: ndm-cluster-exporter
  template:
    metadata:
      labels:
        name: openebs-ndm-cluster-exporter
        openebs.io/component-name: ndm-cluster-exporter
        openebs.io/version: 3.1.0
    spec:
      serviceAccountName: openebs-maya-operator
      containers:
        - name: ndm-cluster-exporter
          image: openebs/node-disk-exporter:1.8.0
          command:
            - /usr/local/bin/exporter
          args:
            - "start"
            - "--mode=cluster"
            - "--port=$(METRICS_LISTEN_PORT)"
            - "--metrics=/metrics"
          ports:
            - containerPort: 9100
              protocol: TCP
              name: metrics
          imagePullPolicy: IfNotPresent
          env:
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: METRICS_LISTEN_PORT
              value: :9100
---
# Create NDM cluster exporter service
# This is optional and required only when
# ndm-cluster-exporter deployment is used
apiVersion: v1
kind: Service
metadata:
  name: openebs-ndm-cluster-exporter-service
  namespace: openebs
  labels:
    name: openebs-ndm-cluster-exporter-service
    openebs.io/component-name: ndm-cluster-exporter
    app: openebs-ndm-exporter
spec:
  clusterIP: None
  ports:
    - name: metrics
      port: 9100
      targetPort: 9100
  selector:
    name: openebs-ndm-cluster-exporter
---
# Create NDM node exporter daemonset.
# This is an optional component used for getting disk level
# metrics from each of the storage nodes
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: openebs-ndm-node-exporter
  namespace: openebs
  labels:
    name: openebs-ndm-node-exporter
    openebs.io/component-name: ndm-node-exporter
    openebs.io/version: 3.1.0
spec:
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      name: openebs-ndm-node-exporter
      openebs.io/component-name: ndm-node-exporter
  template:
    metadata:
      labels:
        name: openebs-ndm-node-exporter
        openebs.io/component-name: ndm-node-exporter
        openebs.io/version: 3.1.0
    spec:
      serviceAccountName: openebs-maya-operator
      containers:
        - name: node-disk-exporter
          image: openebs/node-disk-exporter:1.8.0
          command:
            - /usr/local/bin/exporter
          args:
            - "start"
            - "--mode=node"
            - "--port=$(METRICS_LISTEN_PORT)"
            - "--metrics=/metrics"
          ports:
            - containerPort: 9101
              protocol: TCP
              name: metrics
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          env:
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: METRICS_LISTEN_PORT
              value: :9101
---
# Create NDM node exporter service
# This is optional and required only when
# ndm-node-exporter daemonset is used
apiVersion: v1
kind: Service
metadata:
  name: openebs-ndm-node-exporter-service
  namespace: openebs
  labels:
    name: openebs-ndm-node-exporter
    openebs.io/component: openebs-ndm-node-exporter
    app: openebs-ndm-exporter
spec:
  clusterIP: None
  ports:
    - name: metrics
      port: 9101
      targetPort: 9101
  selector:
    name: openebs-ndm-node-exporter
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openebs-localpv-provisioner
  namespace: openebs
  labels:
    name: openebs-localpv-provisioner
    openebs.io/component-name: openebs-localpv-provisioner
    openebs.io/version: 3.1.0
spec:
  selector:
    matchLabels:
      name: openebs-localpv-provisioner
      openebs.io/component-name: openebs-localpv-provisioner
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        name: openebs-localpv-provisioner
        openebs.io/component-name: openebs-localpv-provisioner
        openebs.io/version: 3.1.0
    spec:
      serviceAccountName: openebs-maya-operator
      containers:
      - name: openebs-provisioner-hostpath
        imagePullPolicy: IfNotPresent
        image: openebs/provisioner-localpv:3.1.0
        args:
          - "--bd-time-out=$(BDC_BD_BIND_RETRIES)"
        env:
        # OPENEBS_IO_K8S_MASTER enables openebs provisioner to connect to K8s
        # based on this address. This is ignored if empty.
        # This is supported for openebs provisioner version 0.5.2 onwards
        #- name: OPENEBS_IO_K8S_MASTER
        #  value: "http://10.128.0.12:8080"
        # OPENEBS_IO_KUBE_CONFIG enables openebs provisioner to connect to K8s
        # based on this config. This is ignored if empty.
        # This is supported for openebs provisioner version 0.5.2 onwards
        #- name: OPENEBS_IO_KUBE_CONFIG
        #  value: "/home/ubuntu/.kube/config"
        # This sets the number of times the provisioner should try 
        # with a polling interval of 5 seconds, to get the Blockdevice
        # Name from a BlockDeviceClaim, before the BlockDeviceClaim
        # is deleted. E.g. 12 * 5 seconds = 60 seconds timeout
        - name: BDC_BD_BIND_RETRIES
          value: "12"
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: OPENEBS_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        # OPENEBS_SERVICE_ACCOUNT provides the service account of this pod as
        # environment variable
        - name: OPENEBS_SERVICE_ACCOUNT
          valueFrom:
            fieldRef:
              fieldPath: spec.serviceAccountName
        - name: OPENEBS_IO_ENABLE_ANALYTICS
          value: "true"
        - name: OPENEBS_IO_INSTALLER_TYPE
          value: "openebs-operator"
        - name: OPENEBS_IO_HELPER_IMAGE
          value: "openebs/linux-utils:3.1.0"
        - name: OPENEBS_IO_BASE_PATH
          value: "/var/openebs/local"
        # LEADER_ELECTION_ENABLED is used to enable/disable leader election. By default
        # leader election is enabled.
        #- name: LEADER_ELECTION_ENABLED
        #  value: "true"
        # OPENEBS_IO_IMAGE_PULL_SECRETS environment variable is used to pass the image pull secrets
        # to the helper pod launched by local-pv hostpath provisioner
        #- name: OPENEBS_IO_IMAGE_PULL_SECRETS
        #  value: ""
        # Process name used for matching is limited to the 15 characters
        # present in the pgrep output.
        # So fullname can't be used here with pgrep (>15 chars).A regular expression
        # that matches the entire command name has to specified.
        # Anchor `^` : matches any string that starts with `provisioner-loc`
        # `.*`: matches any string that has `provisioner-loc` followed by zero or more char
        livenessProbe:
          exec:
            command:
            - sh
            - -c
            - test `pgrep -c "^provisioner-loc.*"` = 1
          initialDelaySeconds: 30
          periodSeconds: 60
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-hostpath
  annotations:
    openebs.io/cas-type: local
    cas.openebs.io/config: |
      #hostpath type will create a PV by 
      # creating a sub-directory under the
      # BASEPATH provided below.
      - name: StorageType
        value: "hostpath"
      #Specify the location (directory) where
      # where PV(volume) data will be saved. 
      # A sub-directory with pv-name will be 
      # created. When the volume is deleted, 
      # the PV sub-directory will be deleted.
      #Default value is /var/openebs/local
      - name: BasePath
        value: "/var/openebs/local/"
provisioner: openebs.io/local
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-device
  annotations:
    openebs.io/cas-type: local
    cas.openebs.io/config: |
      #device type will create a PV by
      # issuing a BDC and will extract the path
      # values from the associated BD.
      - name: StorageType
        value: "device"
provisioner: openebs.io/local
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
---
```

## 使用

OpenEBS的cStor与Jiva引擎由于组件过多，配置相较其他存储方案繁琐，生产环境不建议使用，这里我们仅论述Local PV引擎。

Local PV引擎不具备存储级复制能力，适用于k8s有状态服务的后端存储（如: es、redis等

### 创建数据目录

在将要创建Local PV Hostpaths的节点上设置目录。这个目录将被称为BasePath。默认位置是/var/openebs/local

节点node1、node2、node3创建/data/openebs/local目录 （/data可以预先挂载数据盘，如未挂载额外数据盘，则使用操作系统'/'挂载点存储空间）

```bash
mkdir -p /data/openebs/local
```

### 创建存储类

发布创建存储类
```bash
cat > openebs-hostpath-sc.yaml <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-hostpath
  annotations:
    openebs.io/cas-type: local
    cas.openebs.io/config: |
      #hostpath type will create a PV by
      # creating a sub-directory under the
      # BASEPATH provided below.
      - name: StorageType
        value: "hostpath"
      #Specify the location (directory) where
      # where PV(volume) data will be saved.
      # A sub-directory with pv-name will be
      # created. When the volume is deleted,
      # the PV sub-directory will be deleted.
      #Default value is /var/openebs/local
      - name: BasePath
        value: "/data/openebs/local/"
provisioner: openebs.io/local
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF
```

更改配置文件中的内容

```yaml
value: "/var/openebs/local/"
```

创建

```bash
kubectl apply -f openebs-hostpath-sc.yaml
```


### 创建pvc验证可用性

```bash
cat > local-hostpath-pvc.yaml <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: local-hostpath-pvc
spec:
  storageClassName: openebs-hostpath
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G
EOF
```

执行

```bash
kubectl apply -f local-hostpath-pvc.yaml
```

### 查看pvc状态

```bash
kubectl get pvc

NAME                 STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS       AGE
local-hostpath-pvc   Pending                                    openebs-hostpath   2m15s
```
输出显示STATUS为Pending。这意味着PVC还没有被应用程序使用。

### 创建测试pod

```bash
cat > local-hostpath-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: hello-local-hostpath-pod
spec:
  volumes:

- name: local-storage
    persistentVolumeClaim:
      claimName: local-hostpath-pvc
  containers:
- name: hello-container
    image: busybox
    command:
  - sh
  - -c
  - 'while true; do echo "`date` [`hostname`] Hello from OpenEBS Local PV." >> /mnt/store/greet.txt; sleep $(($RANDOM % 5 + 300)); done'
    volumeMounts:
  - mountPath: /mnt/store
      name: local-storage
EOF
```

发布创建

```bash
kubectl apply -f local-hostpath-pod.yaml
```

验证数据是否写入卷

```bash
kubectl exec hello-local-hostpath-pod -- cat /mnt/store/greet.txt
Thu Jun 24 15:10:45 CST 2021 [node1] Hello from OpenEBS Local PV.
```

验证容器是否使用Local PV Hostpath卷

```bash
kubectl describe pod hello-local-hostpath-pod

Name:         hello-local-hostpath-pod
Namespace:    default
Priority:     0
...
Volumes:
  local-storage:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  local-hostpath-pvc
    ReadOnly:   false
  default-token-98scc:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-98scc
    Optional:    false
...
```

查看pvc状态
```bash
kubectl get pvc local-hostpath-pvc

NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
local-hostpath-pvc   Bound    pvc-6eac3773-49ef-47af-a475-acb57ed15cf6   5G         RWO            openebs-hostpath   10m
```

查看该pv卷数据存储目录为

```bash
kubectl get -o yaml pv pvc-6eac3773-49ef-47af-a475-acb57ed15cf6|grep 'path:'
          f:path: {}
    path: /data/openebs/local/pvc-6eac3773-49ef-47af-a475-acb57ed15cf6
```

并且pv配置了亲和性，制定了调度节点为node2

```yaml
spec:
  accessModes:

- ReadWriteOnce
  capacity:
    storage: 5G
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: local-hostpath-pvc
    namespace: default
    resourceVersion: "9034"
    uid: 6eac3773-49ef-47af-a475-acb57ed15cf6
  local:
    fsType: ""
    path: /data/openebs/local/pvc-6eac3773-49ef-47af-a475-acb57ed15cf6
  nodeAffinity:
    required:
      nodeSelectorTerms:
  - matchExpressions:
    - key: kubernetes.io/hostname
          operator: In
          values:
      - node2
  persistentVolumeReclaimPolicy: Delete
  storageClassName: openebs-hostpath
  volumeMode: Filesystem
```

验证三个节点存储目录下

结果证明数据仅存在于node2下

### 清理pod

```
kubectl delete pod hello-local-hostpath-pod
```