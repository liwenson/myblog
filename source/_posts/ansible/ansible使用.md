---
title: ansible使用
date: 2022-03-24 11:47
categories:
- ansible
tags:
- ansible
---
  
  
摘要: ansible使用
<!-- more -->

[TOC]

## Ansible清单 [inventory]
inventory，是存放被管理机器的IP或域名的地方，清单里的IP地址可以分组，如前端机器一组，后端机器一组，分组可以嵌套。默认这个配置文件在/etc/ansible/hosts
```
# cat /etc/ansible/hosts

[webservers]
foo.example.com
bar.example.com
192.168.31.10:2222
192.168.31.11 ansible_ssh_user=root ansible_ssh_pass=123.com ansible_ssh_port=3333
192.168.31.12 ansible_ssh_user=root ansible_ssh_pass=123.com
## ansible_ssh_user=root  指定主机登陆用户名为root
## ansible_ssh_pass=123.com 指定主机登陆用户的密码为123.com
## ansible_ssh_port=3333  指定ssh的端口

[dbservers]
one.example.com
two.example.com
three.example.com

[appservers]
app[1:10].example.com
10.0.0.[20:30]
```

### 创建方式

Inventory 清单文件是一个描述主机和组的 Ansible 文件, 一般为 INI 格式，也也可以用yaml格式。Inventory 清单文件有两种类型：

- Static Inventory  手动编写。
- External Inventory Script   通过 Inventory Script 提供，常见在公有云部署场景。

### Groups 与 Hosts 对象

Inventory 清单文件中主要有两个概念：

- [Group] : 在系统级别进行分类，便于对不同的系统进行区别管理。
- Host : 实际的一台托管节点，用 hostname 或 IP address 来表示。

Inventory 清单文件描述了这些 Groups 和 Hosts 之间的关系，并且 Groups 和 Hosts 之前是完全解耦的关系。

### 命名

组名称遵循一般的变量命名规则，不能以数字开头，特殊符号只能用下划线

### 常见的机器分组方式

大致有三种

- 按照服务(业务、角色)分，如 web、mysql、php、dns
- 按照地理位置(机房)分，如 north、sourth、beijing、shenzhen
- 按照时间阶段分，即生产prod、预生产stag、测试test

### 分组嵌套
一台机器，可能同属于多个分组，如某台机器是web，在北方，生产环境，那么这台机器会出现在三个分组中.

Ansible还支持YAML格式书写主机清单，对于具有嵌套关系的主机清单，使用YAML格式书写更清楚

yaml 格式 inventory

```yaml
all:
  hosts:
    192.168.21.100:
  children:
    webservers:
      hosts:
        192.168.31.101:
        192.168.31.102:
        192.168.31.103:
    dbservers:
      hosts:
        192.168.41.101:
        192.168.41.102:
        192.168.41.103:
    east:
      hosts:
        192.168.41.101:
        192.168.41.102:
        192.168.41.103:
    west:
      hosts:
        192.168.31.101:
        192.168.31.102:
        192.168.31.103:
    prod:
      hosts:
        192.168.31.101:
        192.168.31.102:
        192.168.31.103:
    test:
      hosts:
        192.168.41.103:
    centos:
      children:
        webservers:    
    ubuntu:
      children:
        dbservers:

```

适用于主机数量多和有规律的主机
INI 格式 inventory

```ini
[student]          
workstation.lab.example.com
server[a:d].lab.exmaple.com
astion.lab.example.com

[test]               # test组
node1
[proxy]              # proxy组
node2
[webserver]          # webserver组
node[3:4]
[database]           # 数据库组 
node5
# 定义嵌套组(主组套子组,子组用:chidren定义)
[cluster:children]   # 集群组
webserver            # webserver组
database             # database组
```

### 匹配机器

patterns  依赖于 Inventory。 如果 host 或 group 不在 Inventory 清单仓库，则不能使用 Pattern 。 如果你使用的 Patterns IP 或主机名不存在

|Description  | Pattern(s) | Targets|
|---|---|---|
|All hosts  | all (or *) | 匹配全部机器|
|One host | host1 | 匹配单个机器|
|Multiple hosts | host1,host2 | 匹配多个机器 逗号分隔|
|One group | webservers | 匹配一个机器分组|
|Multiple groups | webservers:dbservers | 匹配多个机器分组 冒号分割|
|Intersection of groups | webservers:&staging | 匹配同时在webservers和staging分组里的机器|

ansible支持主机列表的正则匹配

```txt
全量: ​​all/*​​

逻辑或: ​​:​​

逻辑非: ​​！​​

逻辑与: ​​＆​​

切片： ​​[]​​

正则匹配： 以​​~​​开头
```

```shell
ansible all -m ping               #所有默认inventory文件中的机器
ansible "*" -m ping               #同上
ansible 121.28.13.* -m  ping      #所有122.28.13.X机器
ansible  web1:web2  -m  ping      #所有属于组web1或属于web2的机器
ansible  web1:!web2  -m  ping     #属于组web1，但不属于web2的机器
ansible  web1&web2  -m  ping      #属于组web1又属于web2的机器
ansible webserver[0]  -m  ping    #属于组webserver的第1台机器
ansible webserver[0:5]  -m  ping  #属于组webserver的第1到4台机器
ansible "~(beta|web)\.example\.(com|org)"  -m ping

```

### 查看主机清单

```shell
ansible all --list-hosts

ansible webserver --list-hosts
```

## 动态 Inventory

Ansible Inventory 是包含静态 Inventory 和动态 Inventory 两部分的，静态 Inventory 指的是在文件中指定的主机和组，动态 Inventory 指通过外部脚本获取主机列表，并按照 ansible 所要求的格式返回给 ansilbe 命令的。这部分一般会结合 CMDB 资管系统、云计算平台等获取主机信息。由于主机资源一般会动态的进行增减，而这些系统一般会智能更新。我们可以通过这些工具提供的 API 或者接入库查询等方式返回主机列表。

**注意:** 在实际使用中，CMDB的业务信息比较多的情况下，需要查询 、编历 整个数据，会导致ansible运行过久，执行效低，超时等问题，基于以上问题，我们考虑到用动态方法制作静态inventory文件。

### 脚本规约

用于生成 JSON 的脚本对实现语言没有要求，它可以是一个可执行脚本、二进制文件，或者其他任何可以运行文件，但是必须输出为 JSON 格式，同时必须支持两个参数：--list 和 --host <hostname>。

```txt
--list : 用于返回所有的主机组信息，每个组所包含的主机列表 hosts、所含子组列表 children、主机组变量列表 vars 都应该是字典形式的，_meta 用来存放主机变量。
--host <hostname>  : 返回指定主机的变量列表，或者返回一个空的字典
```

### json格式

```json
{
    "group1": {
        "hosts": [
            "192.168.28.71",
            "192.168.28.72"
        ],
        "vars": {
            "ansible_ssh_user": "johndoe",
            "ansible_ssh_private_key_file": "~/.ssh/mykey",
            "example_variable": "value"
        },
        "children":['group2']
    },
    "_meta": {
        "hostvars": {
            "192.168.28.71": {
                "host_specific_var": "bar"
            },
            "192.168.28.72": {
                "host_specific_var": "foo"
            }
        }
    }
}

```

_meta 用来存放主机变量,如果inventory脚本返回的顶级元素为”_meta”,它可能会返回所有主机的变量. 如果这个元素中包含一个名为”hostvars”的value,这个inventory脚本对每一台主机使用调用时候，就不会调用 --host 选项对目标主机进行操作，而是使用hostvars 中目标主机的信息对目标主机进行操作。

### 从数据库中查询(未验证，仅供参考)

从mysql数据库作为数据源生成动态 ansible 主机;

```python
#!/usr/bin/env python36

def commmysql():
    import mysql.connector
    import json
    mydb = mysql.connector.connect(
        host="192.168.1.2",  # 数据库主机地址
        user="root",  # 数据库用户名
        passwd="12345678",
        database="test"
    )
    mycursor = mydb.cursor()
    mycursor.execute(" select host,`group` from ansible_hosts;")

    myresult = mycursor.fetchall()
    data = dict()
    #####查询出group分组并去重#############
    groups = list(set([i[1].decode() for i in myresult]))
    data["all"] = {"children": groups}
    data["_meta"] = {"hostvars": {}}
    for group in groups:
        data[group] = dict()
        data[group]["hosts"] = list()
        for x in myresult:
            if x[1].decode("utf-8") == group:
                data[group]["hosts"].append(x[0].decode("utf-8"))
    return json.dumps(data,indent=3)


def main():
    from optparse import OptionParser
    parse = OptionParser()
    parse.add_option("-l", "--list", action="store_true", dest="list", default=False)
    (option, arges) = parse.parse_args()
    if option.list:
        print(commmysql())
    else:
        print("abc")


if __name__ == '__main__':
    from optparse import OptionParser
    parse = OptionParser()
    parse.add_option("-l", "--list", action="store_true", dest="list", default=False)
    (option, arges) = parse.parse_args()
    if option.list:
        print(commmysql())
    else:
        print("test")

```

### 使用

使用方法和静态 inventory 类似

```shell
ansible -i dynamic_investory.py all --list-hosts
```


## Ansible之条件判断  [ when ]

条件判断的关键字是 when ，使用 when 关键字为任务指定条件，条件成立，则执行任务，条件不成立，则不执行任务.在 when 关键字中引用变量时，变量名不需要加双括号({{ args }}).

### 字符串判断

在 ansible 中使用 == 就可以判断字符串是否相同，还可通过如下关键字判断字符串大小写的状态：

- lower：判断包含字母的字符串中的字母是否是纯小写，字符串中的字母全部为小写则返回真
- upper：判断包含字母的字符串中的字母是否是纯大写，字符串中的字母全部为大写则返回真

除此之外，还可通过 in 关键字判断指定字符串是否存在于另一个字符串中。

例 1：判断当前操作主机的系统是不是 CentOS。

```yaml
---
- hosts: all
  tasks:
  - debug:
      msg: "System release is CentOS"
    when: ansible_distribution == "CentOS"

```

例 2：判断给定字符串的大小写状态。

```yaml
---

- hosts: B
  gather_facts: no
  vars:
    str1: "abc"
    str2: "ABC"
  tasks:
  - debug:
      msg: "This string is all lowercase"
    when: str1 is lower
  - debug:
      msg: "This string is all uppercase"
    when: str2 is upper
```

例 3：判断给定字符串变量值是否存在于 hello world 字符串中。

```yaml
---

- hosts: B
  gather_facts: no
  vars:
    str1: "hello"
    str2: "hello world"
  tasks:
  - debug:
      msg: "{{str1}} in {{str2}}"
    when: str1 in str2
```

### 变量判断

ansible 可通过如下几个关键字对变量进行判断：

- string：判断对象是否是一个字符串，是字符串则返回真
- number：判断对象是否是一个数字，是数字则返回真
- defined：判断变量是否已经定义，已经定义则返回真
- undefind：判断变量是否已经定义，未定义则返回真
- none：判断变量值是否为空，如果变量已经定义，但是变量值为空，则返回真

例 1：当对应的条件为真时，你可以看到 debug 模块对应的输出。

```yaml
---
- hosts: B
  gather_facts: no
  vars:
    testvar: "test"
    testvar1:
  tasks:
  - debug:
      msg: "Variable is defined"
    when: testvar is defined
  - debug:
      msg: "Variable is undefined"
    when: testvar2 is undefined
  - debug:
      msg: "The variable is defined, but there is no value"
    when: testvar1 is none
```

例 2：判断给定变量是一个字符串还是数字

```yaml

---
- hosts: B
  gather_facts: no
  vars:
    testvar: "a"
  tasks:
  - debug:
      msg: "{{testvar}} is a number"
    when: testvar is number
  - debug:
      msg: "{{testvar}} is a string"
    when: testvar is string
```

### 结果判断

ansible 可通过如下几个关键字来对任务的执行结果进行判断：

- success 或 succeeded：通过任务的返回信息判断任务的执行状态，任务执行成功则返回真；
- failure 或 failed：通过任务的返回信息判断任务的执行状态，任务执行失败则返回真；
- change 或 changed：通过任务的返回信息判断任务的执行状态，任务执行状态为 changed 则返回真；
- skip 或 skipped：通过任务的返回信息判断任务的执行状态，当任务没有满足条件，而被跳过执行时，则返回真

例：根据任务执行结果输出对应信息。

```yaml
---
- hosts: B
  gather_facts: no
  vars:
    doshell: "yes"
  tasks:
  - shell: "cat /testdir/abc"
    when: doshell == "yes"
    register: returnmsg
    ignore_errors: true
  - debug:
      msg: "success"
    when: returnmsg is success
  - debug:
      msg: "failed"
    when: returnmsg is failure
  - debug:
      msg: "changed"
    when: returnmsg is change
  - debug:
      msg: "skip"
    when: returnmsg is skip

```

### 状态判断 [failed_when]

failed_when 的作用就是，当对应的条件成立时，将对应任务的执行状态设置为失败，我们可以借助 failed_when 关键字来完成类似 fail 模块的功能。

```yaml
---
- hosts: B
  gather_facts: no
  tasks:
  - debug:
      msg: "I execute normally"
  - shell: "echo 'This is a string for testing error'"
    register: return_value
    failed_when: ' "error" in return_value.stdout'
  - debug:
      msg: "I never execute,Because the playbook has stopped"
```

上例中, failed_when 对应的条件是 "error" in return_value.stdout，表示 error 字符串如果存在于 shell 模块执行后的标准输出中，则条件成立，当条件成立后，shell 模块的执行状态将会被设置为失败，由于 shell 模块的执行状态被设置为失败，所以 playbook 会终止运行，于是，最后的 debug 模块并不会被执行。

理解了' failed_when'关键字以后，顺势理解'changed_when'关键字就容易多了。

- failed_when 关键字的作用是在条件成立时，将对应任务的执行状态设置为失败。
- changed_when 关键字的作用是在条件成立时，将对应任务的执行状态设置为 changed。

例子：changed_when

```yaml

---
- hosts: B
  gather_facts: no
  tasks:
  - debug:
      msg: "test message"
    changed_when: 2 > 1
```

我们知道，debug 模块在正常执行的情况下只能是 ok 状态，上例中，我们使用 changed_when 关键字将 debug 模块的执行后的状态定义为了 changed，你可以尝试执行上例 playbook，执行效果如下:

```shell
$ ansible-playbook test.yml

PLAY [B] ******************************************************************************************************************************

TASK [debug] **************************************************************************************************************************
changed: [B] => {
    "msg": "test message"
}

PLAY RECAP ****************************************************************************************************************************
B                          : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```

changed_when 除了能够在条件成立时将任务的执行状态设置为 changed，还能让对应的任务永远不能是 changed 状态，示例如下:

```yaml
---

- hosts: B
  gather_facts: no
  tasks:
  - shell: "ls /opt"
    changed_when: false
```

当将 changed_when 直接设置为 false 时，对应任务的状态将不会被设置为 changed，如果任务原本的执行状态为 changed，最终则会被设置为 ok，所以，上例 playbook 执行后，shell 模块的执行状态最终为 ok。

### 运算符判断

在 ansible 中，我们可以使用如下比较运算符

```text
==：比较两个对象是否相等，相等为真；
!=：比较两个对象是否不等，不等为真；
>：比较两个值的大小，如果左边的值大于右边的值，则为真；
<：比较两个值的大小，如果左边的值小于右边的值，则为真；
>=：比较两个值的大小，如果左边的值大于右边的值或左右相等，则为真；
<=：比较两个值的大小，如果左边的值小于右边的值或左右相等，则为真；
```

我们总结的这些运算符其实都是 jinja2 的运算符，ansible 使用 jinja2 模板引擎，在 ansible 中也可以直接使用 jinja2 的这些运算符。

说完了比较运算符，再来说说逻辑运算符，可用的逻辑运算符如下

- and：逻辑与，当左边与右边同时为真，则返回真；
- or：逻辑或，当左边与右边有任意一个为真，则返回真；
- not：取反，对一个操作体取反；
- ( )：组合，将一组操作体包装在一起，形成一个较大的操作体

例 1：输出大于 2 的数字。

```yaml
---
- hosts: B
  gather_facts: no
  tasks:
  - debug:
      var: item
    when: item > 2
    with_items: [ 1, 2, 3 ]
```

例 2：判断客户机系统是否是 CentOS 7

```yaml
---
- hosts: all
  tasks:
  - debug:
      msg: "System release is centos7"
    when: ansible_distribution == "CentOS" and ansible_distribution_major_version == "7"

# 这里的 when 条件也可写为如下
# when
# - ansible_distribution == "CentOS"
# - ansible_distribution_major_version == "7"
# 其含义为列表中每一项结果都为 true 时才执行
```

例 3：判断任务是否成功执行。

```yaml
---
- hosts: B
  gather_facts: no
  tasks:
  - name: task1
    shell: "ls /testabc"
    register: returnmsg
    ignore_errors: true

# 如果任务执行失败 ansible 默认会立即停止继续往下执行，使用 ignore_errors 可以忽略失败的错误，让其正常向下执行

- name: task2
    debug:
      msg: "Command execution successful"
    when: returnmsg.rc == 0
- name: task3
    debug:
      msg: "Command execution failed"
    when: returnmsg.rc != 0
```

### 文件判断

ansible 可通过如下关键字对文件状态进行判断：

- file：判断路径是否是一个文件，如果路径是一个文件则返回真；
- directory：判断路径是否是一个目录，如果路径是一个目录则返回真；
- link：判断路径是否是一个软链接，如果路径是一个软链接则返回真；
- mount：判断路径是否是一个挂载点，如果路径是一个挂载点则返回真；
- exists：判断路径是否存在，如果路径存在则返回真；

**注意**: 这里的文件路径是 ansible 管理机的路径。

例：判断 /testdir 是否存在。

```yaml
---
- hosts: B
  gather_facts: no
  vars:
    testpath: /testdir
  tasks:
  - debug:
      msg: "file exist"
    when: testpath is exists
# 取反可使用 not，下面判断表示 testpath 路径是否不存在
# when: testpath is not exists

```

### 整除判断

ansible 可通过如下关键字对一个数字进行整除判断：

- even：判断数值是否是偶数，是偶数则返回真；
- odd：判断数值是否是奇数，是奇数则返回真；
- divisibleby(num)：判断是否可以整除指定的数值num，如果除以指定的值num以后余数为0，则返回真

示例：

```yaml
---
- hosts: B
  gather_facts: no
  vars:
    num1: 4
    num2: 7
    num3: 64
  tasks:
  - debug:
      msg: "An even number"
    when: num1 is even
  - debug:
      msg: "An odd number"
    when: num2 is odd
  - debug:
      msg: "Can be divided exactly by 8"
    when: num3 is divisibleby(8)
```

### 列表父子集判断

ansible 可使用如下关键字对列表进行父子集判断：

- subset：判断一个 list 是不是另一个 list 的子集，是另一个 list 的子集时返回真
- superset : 判断一个 list 是不是另一个 list 的父集，是另一个 list 的父集时返回真

示例

```yaml
---

- hosts: B
  gather_facts: no
  vars:
    a:
  - 2
  - 5
    b: [1,2,3,4,5]
  tasks:
  - debug:
      msg: "A is a subset of B"
    when: a is subset(b)
  - debug:
      msg: "B is the parent set of A"
    when: b is superset(a)
```

### 版本判断

在 ansible 中 version 关键字可以用于对比两个版本号的大小，或者与指定的版本号进行对比，使用语法为 version('版本号', '比较操作符')。

version 支持的比较操作符如下：

```txt
大于:  >、gt；
大于等于:  >=、ge
小于:  <、lt；
小于等于:  <=、le；
等于:  ==、=、eq；
不等于:  !=、<>、ne；
```

示例

```yaml
---

- hosts: B
  vars:
    ver: 7.4.1708
    ver1: 7.4.1707
  tasks:
  - debug:
      msg: "This message can be displayed when the ver is greater than ver1"
    when: ver is version(ver1,">")
  - debug:
      msg: "system version {{ansible_distribution_version}} greater than 7.3"
    when: ansible_distribution_version is version("7.3","gt")

# ver_val is version(ver1, ">") 表示 ver_val 是否大于 ver1 版本
```

### 合并判断

在 ansible 中，可以使用 block 关键字将多个任务整合成一个块，这个块将被当做一个整体，我们可以对这个块添加判断条件，当条件成立时，则执行这个块中的所有任务。

示例

```yaml
---
- hosts: B
  gather_facts: no
  tasks:
  - debug:
      msg: "task1 not in block"
  - block:
    - debug:
          msg: "task2 in block1"
    - debug:
          msg: "task3 in block1"
    when: 2 > 1
```

## Ansible 执行策略

ansible在默认情况下，所有hosts中每次在5台机器上运行任务。如果想要改变这种默认行为，可以改变forks 数量或者改变策略类型。

Ansible官方目前提供了四种策略插件

- linear
- free
- host-pinned
- debug

### 设置策略

默认是 linear strategy

- linear: 线性执行策略指主机组内所有主机完成一个任务后才继续下一个任务的执行，在执行一个任务时，如果某个主机先执行完则会等待其他主机执行结束。说直白点就是第一个任务在指定的主机都执行完，再进行第二个任务的执行，第二个任务在指定的主机都执行完后，再进行第三个任务的执行…… 以此类推

- free: 自由策略，即在一个play执行完之前，每个主机都各顾各的尽可能快的完成play里的所有任务，而不会因为其他主机没执行完任务而等待，不受线性执行策略那样的约束。所以这种策略的执行结果给人感觉是无序的甚至是杂乱无章的，而且每次执行结果的task显示顺序很可能不一样。

- host_pinned: 主机组中的一个主机完成所有的任务之后，下一个主机在执行所有的任务，一个一个主机来完成所有的任务
- debug: 此策略使您能够在任务失败时调用调试器,可以访问失败任务上下文中调试器的所有功能。 然后，您可以例如检查或设置变量的值，更新模块参数，并使用新的变量和参数重新运行失败的任务，以帮助解决失败的原因

可以通过下面方式修改

```yaml
- hosts: all
  strategy: free
  tasks:
  ...

```

或者修改ansible.cfg 全局设置

```ini
[defaults]
strategy = free
...

```

### debug

```yaml
---
- hosts: test
  strategy: debug
  gather_facts: no
  vars:
    var1: value1
  tasks:
    - name: wrong variable
      ping: data={{ wrong_var }}
```

playbook，在执行到错误的任务时，会进入debug模式下

```shell

PLAY [localhost] ***********************************************************************************************************************************************************

TASK [wrong variable] ******************************************************************************************************************************************************
fatal: [localhost]: FAILED! => {"msg": "The task includes an option with an undefined variable. The error was: 'wrong_var' is undefined\n\nThe error appears to be in '/root/test/003/001.yaml': line 7, column 7, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n  tasks:\n    - name: wrong variable\n      ^ here\n"}
[localhost] TASK: wrong variable (debug)>
```

可用命令
|命令 | 说明|
|---|---|
|p | 显示此次失败的原因|
|p task | 显示此次任务的名称|
|p task.args | 显示模块的参数|
|p host | 显示执行此次任务的主机|
|p result | 显示此次任务的结果|
|p vars | 显示当前的变量|
|vars[key] = value | 更新vars中的值|
|task.args[key] = value | 更新模块的参数。|
|r | 再次执行此任务|
|c | 继续执行|
|q | 退出debug模式|

### host_pinned

```yaml
cat hosts

---
all:
  hosts:
    test_01:
      wait_timeout: 1
    test_02:
      wait_timeout: 2
    test_03:
      wait_timeout: 3
    test_06:
      wait_timeout: 4
    test_09:
      wait_timeout: 5
```

cat pinned-01.yml

```yaml
- name: Play A
  hosts: all
  gather_facts: false
  strategy: host_pinned
  tasks:
    - debug:
        msg: "A:{{ inventory_hostname }}
              {{ lookup('pipe', 'date +%H-%M-%S') }}
              started"
    - wait_for:
        timeout: "{{ wait_timeout }}"
    - debug:
        msg: "A:{{ inventory_hostname }}
              {{ lookup('pipe', 'date +%H-%M-%S') }}
              finished"
```

```shell
ansible-playbook -i hosts  002.yaml -f 3 | grep msg\":

    "msg": "A:test_01 14-10-28 started"
    "msg": "A:test_02 14-10-28 started"
    "msg": "A:test_03 14-10-28 started"

    "msg": "A:test_01 14-10-31 finished"
    "msg": "A:test_06 14-10-31 started"

    "msg": "A:test_02 14-10-32 finished"
    "msg": "A:test_09 14-10-32 started"

    "msg": "A:test_03 14-10-32 finished"
    "msg": "A:test_06 14-10-36 finished"
    "msg": "A:test_09 14-10-38 finished"

```

host_pinned 策略是遵循第一个主机、第二个主机、第三个主机……这样顺序执行下去的，每个主机执行完所有任务之后，下一个主机再执行

### linear

```yaml
all:
  hosts:
    test_01:
    test_02:
    test_03:
```

```yaml
---
- name: Play A
  hosts: all
  strategy: linear
  tasks:
    - debug:
        msg: "test_1"
    - debug:
        msg: "test_2"
```

```shell
PLAY [Play A] ***********************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [test_03]
ok: [test_02]
ok: [test_01]

TASK [debug] ************************************************************************************************************
ok: [test_01] => {
    "msg": "test_1"
}
ok: [test_02] => {
    "msg": "test_1"
}
ok: [test_03] => {
    "msg": "test_1"
}

TASK [debug] ************************************************************************************************************
ok: [test_01] => {
    "msg": "test_2"
}
ok: [test_02] => {
    "msg": "test_2"
}
ok: [test_03] => {
    "msg": "test_2"
}

PLAY RECAP **************************************************************************************************************
test_01                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
test_02                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
test_03                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

linear策略是遵循第一个任务、第二个任务、第三个任务……这样顺序执行下去的

### free

```yaml
---
- name: Play A
  hosts: all
  strategy: free
  tasks:
    - debug:
        msg: "test_1"
    - debug:
        msg: "test_2"
```

```shell
PLAY [Play A] ***********************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [test_01]

TASK [debug] ************************************************************************************************************
ok: [test_01] => {
    "msg": "test_1"
}

TASK [debug] ************************************************************************************************************
ok: [test_01] => {
    "msg": "test_2"
}

TASK [Gathering Facts] **************************************************************************************************
ok: [test_03]
ok: [test_02]

TASK [debug] ************************************************************************************************************
ok: [test_03] => {
    "msg": "test_1"
}
ok: [test_02] => {
    "msg": "test_1"
}

TASK [debug] ************************************************************************************************************
ok: [test_03] => {
    "msg": "test_2"
}
ok: [test_02] => {
    "msg": "test_2"
}

PLAY RECAP **************************************************************************************************************
test_01                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
test_02                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
test_03                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

free策略则是无序的，甚至Gathering Facts任务也可能在debug任务之后执行


## Ansible 任务委托[delegate_to、delegate_facts、run_once]

### delegate_to


ansible 的所有任务都是在指定的机器上运行的。当在一个独立的集群环境中配置时，只是想操作其中的某一台主机，或者在特定的主机上运行task任务，此时就需要用到 ansible 的任务委托功能。使用 delegate_to 关键字可以配置 task任务在指定的机器上执行，就是说其他的task任务还是在hosts关键字配置的机器上运行，到了这个关键字所在的任务时，就使用委托的机器运行

```yaml
---
- hosts : all

  tasks :
    - name: "get_ip"
      shell : "hostname -I | cut -d' ' -f 1"
      register :  ip
      #delegate_to: test_01

    - name: "get_hostname"
      shell : "hostname"
      register :  host

    - debug:
        msg: "{{ ip.stdout }}, {{ host.stdout }}"
```

执行结果

```shell
PLAY [all] **************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [test_02]
ok: [test_01]
ok: [test_03]

TASK [get_ip] ***********************************************************************************************************
changed: [test_03]
changed: [test_02]
changed: [test_01]

TASK [get_hostname] *****************************************************************************************************
changed: [test_03]
changed: [test_02]
changed: [test_01]

TASK [debug] ************************************************************************************************************
ok: [test_01] => {
    "msg": "10.200.84.117, hz01-qa-ops-docker-01"
}
ok: [test_02] => {
    "msg": "10.200.192.46, hz01-base-jenkins-02"
}
ok: [test_03] => {
    "msg": "10.200.75.95, hz01-qa01-wms-cluster-02"
}

PLAY RECAP **************************************************************************************************************
test_01                    : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
test_02                    : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
test_03                    : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

将任务指定到某个节点执行

```yaml
---
- hosts : all

  tasks :
    - name: "get_ip"
      shell : "hostname -I | cut -d' ' -f 1"
      register :  ip
      delegate_to: test_01

    - name: "get_hostname"
      shell : "hostname"
      register :  host

    - debug:
        msg: "{{ ip.stdout }}, {{ host.stdout }}"
```

执行结果

```shell
PLAY [all] **************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************
ok: [test_01]
ok: [test_02]
ok: [test_03]

TASK [get_ip] ***********************************************************************************************************
changed: [test_03 -> test_01]
changed: [test_01]
changed: [test_02 -> test_01]

TASK [get_hostname] *****************************************************************************************************
changed: [test_01]
changed: [test_03]
changed: [test_02]

TASK [debug] ************************************************************************************************************
ok: [test_01] => {
    "msg": "10.200.84.117, hz01-qa-ops-docker-01"
}
ok: [test_02] => {
    "msg": "10.200.84.117, hz01-base-jenkins-02"
}
ok: [test_03] => {
    "msg": "10.200.84.117, hz01-qa01-wms-cluster-02"
}

PLAY RECAP **************************************************************************************************************
test_01                    : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
test_02                    : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
test_03                    : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```

将获取ip的任务指定到test_01 执行之后，只能获取到 01 的ip.
如果 "delegate_to: 127.0.0.1" 则可以用local_action来代替。即下面两个配置效果是一样的

```yaml
---
- hosts : all

  tasks :
    - name: "get_ip"
      local_action: shell "hostname -I | cut -d' ' -f 1"
      register :  ip

    - name: "get_hostname"
      shell : "hostname"
      register :  host

    - debug:
        msg: "{{ ip.stdout }}, {{ host.stdout }}"
```

如果设置了多个delegate_to，则执行时只会匹配最下面那个.
delegate_to 默认后面只能跟一个主机ip，不能跟多个主机ip。即默认委托到单个主机。
如果有多个ip需要委托，则可以将这些ip重新放一个group，然后delegate_to委托给group组。
delegate_to委托到组的方式：通过items变量方式！！！ 即将shell这个task任务委托给 dbserver 组内的机器执行

```ini
[dbserver]
192.168.0.1
192.168.0.2
192.168.0.3

```

```yaml
- hosts: all
  tasks:
    - name: test
      shell: echo "test" > /root/test.list
      delegate_to: "{{item}}"
      with_items: "{{groups['dbserver']}}"
```

### delegate_facts

默认情况下, ansible委托任务的facts是inventory_hostname中主机的facts, 而不是被委托机器的facts。
在ansible 2.0 中, 通过设置"delegate_facts: True" 可以让task任务去收集被委托机器的facts。

```yaml
- hosts: all
  tasks:
    - name: test
      shell: echo "test" > /root/test.list
      delegate_to: "{{item}}"
      delegate_facts: True
      with_items: "{{groups['dbserver']}}"
```

### run_once

通过设置"run_once: true"来指定该task只能在委托的某一台机器或委托的组内机器上执行一次！！可以和delegate_to 结合使用,如果没有delegate_to, 那么这个task默认就会在第一台机器上执行

```yaml
- hosts: all
  tasks:
    - name: test
      shell: echo "test" > /root/test.list
      delegate_to: "{{item}}"
      run_once: true
      delegate_facts: True
      with_items: "{{groups['dbserver']}}"
```

## Ansible的任务暂停  [ local_action、wait_for ]

当Ansible一些任务的运行需要等到一些状态的恢复，比如某一台主机或者应用刚刚重启，需要等待其某个端口开启，这个时候就需要用到Ansible的任务暂停功能。Ansible任务的暂停操作是通过local_action配合wait_for模块来完成的。

```
- hosts: webserver
  remote_user: root
  gather_facts: no
 
  tasks:
    - name: test
      local_action:
        module: wait_for  #模块名字
        port: 2379
        host: 192.168.10.11
        delay: 10
        timeout: 300
        state: started
```
使用local_action配合 wait_for 模块来完成任务的暂停操作
