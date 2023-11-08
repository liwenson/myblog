
在使用Queue模块+多线程模拟生产者+消费者问题时，遇到了一个小问题，现在记录下来。供可能会遇到类似问题的初学者们参考。

该问题的完整参考代码如下。主要实现了以下的功能:在一个线程中，开启生产者模式，生成出来的object会put进一个Queue对象queue中。除此以外，在n个线程中（本代码中n为5，nfuncs = 5），开启消费者模式，每一个消费者线程会在一个while循环中不断地从queue中消耗一个object（使用get方法），直到生产者生产出的object被全部消耗（本代码中设为100个object）。



Python的Queue模块提供了同步的，线程安全的队列类，包括：FIFO队列Queue，LIFO队列LifeQueue,优先级队列PriorityQueue,这些队列都实现了锁原语，能在多线程中直接使用，可以使用队列来实现线程间的同步。

初始化Queue（）对象时（如：q=Queue()),若括号中没有指定最大可接收的消息数量，或数量为负数，那么就代表可接收的消息数量没有上限。

```
Queue.task_done():完成一项工作后，使用此方法可以向队列发送一个信号，表示该任务执行完毕。
Queue.join():等到队列中所有任务（数据）执行完毕后，再往下执行，否则一直等待；join()是判断依据，不单单指队列中没有数据，数据get出去之后，要使用task_done()向队列发送一个信号，表示该任务（数据使用）执行完毕。
Queue.qsize():返回当前队列包含的消息数量
Queue.empty():如果队列为空，返回True,反之返回False
Queue.full():如果队列满了，返回True,反之返回False
Queue.put(item, block=True, timeout=None):写入队列，block表示是否等待，timeout表示等待时长
Queue.get(block=True, timeout=None):获取队列，block表示是否等待，timeout表示等待时长
Queue.put_nowait(item):等同于Queue.put(item,False)
Queue.get_nowait():等同于Queue.get(False)


```
生产者消费者模式：

为什么使用生产者和消费者模式：

        在线程的世界里，生产者就是产生数据的线程，消费者就是消费数据的线程。在多线程开发当中，如果生产者处理速度很快，而消费者处理速度很慢，那么生产者必须等待消费者处理完，产能继续生产数据；同样的道理，如果消费者处理能力大于生产者，那么消费者就必须要等待生产者，为了解决这个问题，于是引入了生产者和消费者模式。

什么是生产者消费者模式：

        生产者消费者模式是通过一个容器来解决生产者和消费者的强耦合问题。生产者和消费者不直接通讯，而通过阻塞队列来通讯，所以生产者产生完数据之后不用等待消费者处理，直接扔给阻塞队列，消费者不找生产者要数据，而是直接从阻塞队列里取，阻塞队列就相当于一个缓冲区，平衡了生产者和消费者的处理能力。


```
生产者消费者示例

import queue
import threading
import time
 
q = queue.Queue()
 
 
class Producer(threading.Thread):
    """生产商品的线程类,判断队列是否小于50，小于50之后就生产200个商品，生产完一轮休息1秒"""
 
    def run(self):
        while True:
            if q.qsize() <= 50:
                print("生产前队列长度为：{}".format(q.qsize()))
                for i in range(200):
                    q.put("生产商品{}".format(i))
                time.sleep(1)
 
 
class Consumer(threading.Thread):
    """消费商品的线程类,当商品数量大于10的时候就消费商品，每次消费3个，当商品数量小于10的时候就休息2秒"""
 
    def run(self):
        while True:
            if q.qsize() >= 10:
                print("消费前队列长度为：{}".format(q.qsize()))
                for i in range(3):
                    goods = q.get()
                    print(f"消费的商品是：{goods}")
            else:
                time.sleep(2)
 
 
p = Producer()
p.start()  # 启动1个生产者线程
for i in range(5):  # 启动5个消费者线程
    c = Consumer()
    c.start()
运行结果：

```

