---
title: centos7 部署redpanda
date: 2022-04-24 14:24
categories:
- centos7
tags:
- redpanda
- kafka
---
  
  
摘要: centos7 部署redpanda
<!-- more -->

## github

官方页面

<https://redpanda.com/>

github

<https://github.com/redpanda-data/redpanda>

## 部署redpanda

```bash
curl -1sLf \
  'https://packages.vectorized.io/nzc4ZYQK3WRGd9sy/redpanda/cfg/setup/bash.rpm.sh' \
  | sudo -E bash
  
sudo yum install redpanda
```

## golang连接 redpanda

redpanda兼容kafka api ,使用方式和kafka没有差别

Go语言中连接kafka使用第三方库: github.com/Shopify/sarama

```bash
go get github.com/Shopify/sarama
```

### 生产端

```go
package main

import (
 "fmt"
 "github.com/Shopify/sarama"
 "log"
 "os"
 "sync"
 "time"
)

var wg sync.WaitGroup

var address = []string{"10.200.70.139:9092"}

func main() {

 //配置发布者
 config := sarama.NewConfig()
 //确认返回，记得一定要写，因为本次例子我用的是同步发布者
 config.Producer.Return.Successes = true
 //设置超时时间 这个超时时间一旦过期，新的订阅者在这个超时时间后才创建的，就不能订阅到消息了
 config.Producer.Timeout = 5 * time.Second
 //连接发布者，并创建发布者实例
 p, err := sarama.NewSyncProducer(address, config)
 if err != nil {
  log.Printf("sarama.NewSyncProducer err, message=%s \n", err)
  return
 }
 //程序退出时释放资源
 defer p.Close()
 //设置一个逻辑上的分区名
 topic := "weatherStation"
 //这个是发布的内容
 srcValue := "sync: this is a message. index=%d"
 //发布者循环发送0-9的消息内容
 for i := 0; i < 100; i++ {
  value := fmt.Sprintf(srcValue, i)
  //创建发布者消息体
  msg := &sarama.ProducerMessage{
   Topic: topic,
   Value: sarama.ByteEncoder(value),
  }
  //发送消息并返回消息所在的物理分区和偏移量
  partition, offset, err := p.SendMessage(msg)
  if err != nil {
   log.Printf("send message(%s) err=%s \n", value, err)
  } else {
   fmt.Fprintf(os.Stdout, value+"发送成功，partition=%d, offset=%d \n", partition, offset)
  }
  time.Sleep(4500 * time.Millisecond)
 }
}

```

### 消费端

```go
package main

import (
 "fmt"
 "github.com/Shopify/sarama"
 "sync"
)

var wg sync.WaitGroup

func main(){

 //创建新的消费者
 consumer, err := sarama.NewConsumer([]string{"10.200.70.139:9092"}, nil)
 if err != nil {
  fmt.Println("fail to start consumer", err)
 }
 //根据topic获取所有的分区列表
 partitionList, err := consumer.Partitions("weatherStation")
 if err != nil {
  fmt.Println("fail to get list of partition,err:", err)
 }
 fmt.Println(partitionList)
 //遍历所有的分区
 for p := range partitionList {
  //针对每一个分区创建一个对应分区的消费者
  pc, err := consumer.ConsumePartition("weatherStation", int32(p), sarama.OffsetNewest)
  if err != nil {
   fmt.Printf("failed to start consumer for partition %d,err:%v\n", p, err)
  }
  defer pc.AsyncClose()
  wg.Add(1)
  //异步从每个分区消费信息
  go func(sarama.PartitionConsumer) {
   for msg := range pc.Messages() {
    fmt.Printf("partition:%d Offse:%d Key:%v Value:%s \n",
     msg.Partition, msg.Offset, msg.Key, msg.Value)
   }
  }(pc)
 }
 wg.Wait()
}
```

使用 rpk 工具消费

```bash
rpk topic consume weatherStation
```



