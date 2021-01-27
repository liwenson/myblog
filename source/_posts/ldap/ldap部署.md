---
title: ldap安装部署
date: 2020-03-02 14:00:00
categories: 
- ldap
tags:
- ldap
---



### 环境准备

#### 1、yum 仓库

```
wget http://mirrors.aliyun.com/repo/Centos-7.repo
cp Centos-7.repo /etc/yum.repos.d/
cd /etc/yum.repos.d/
mv CentOS-Base.repo CentOS-Base.repo.bak
mv Centos-7.repo CentOS-Base.repo

(如果找不到软件包，重新设置一下yum源)
yum localinstall http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

yum clean all
yum makecache
```

#### 2、关闭防火墙

```bash
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config && setenforce 0 && systemctl disable firewalld.service && systemctl stop firewalld.service && shutdown -r now
```



### 安装oepnldap

```bash
yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel migrationtools
```

查看openldap版本

```
slapd -VV

@(#) $OpenLDAP: slapd 2.4.44 (Jan 29 2019 17:42:45) $
	mockbuild@x86-01.bsys.centos.org:/builddir/build/BUILD/openldap-2.4.44/openldap-2.4.44/servers/slapd
```



### 配置openldap

#### 1、方式一，配置openldap管理员

##### a、 这里我配置密码为123456

```
#slappasswd -s 123456

{SSHA}y34sWhOnwBeR2hUBbTida1U/7s0S63sB
```

生成的密码字段保存下来

##### b、修改olcDatabase={2}hdb.ldif文件

```
vim /etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif

修改olcDatabase={2}hdb.ldif文件,对于该文件增加一行
olcRootPW: {SSHA}y34sWhOnwBeR2hUBbTida1U/7s0S63sB
，然后修改域信息：
olcSuffix: dc=ops,dc=com
olcRootDN: cn=admin,dc=ops,dc=com

修改后如下
-----------------------------------------
# AUTO-GENERATED FILE - DO NOT EDIT!! Use ldapmodify.
# CRC32 505f2856
dn: olcDatabase={2}hdb
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: {2}hdb
olcDbDirectory: /var/lib/ldap
olcSuffix: dc=ops,dc=com
olcRootDN: cn=admin,dc=ops,dc=com
olcDbIndex: objectClass eq,pres
olcDbIndex: ou,cn,mail,surname,givenname eq,pres,sub
structuralObjectClass: olcHdbConfig
entryUUID: 9773d930-f089-1039-88b1-3ff9195b4b09
creatorsName: cn=config
createTimestamp: 20200302042528Z
entryCSN: 20200302042528.964500Z#000000#000#000000
modifiersName: cn=config
modifyTimestamp: 20200302042528Z
olcRootPW: {SSHA}y34sWhOnwBeR2hUBbTida1U/7s0S63sB
```

**注意**：`其中cn=adm in中的admin表示OpenLDAP管理员的用户名，而olcRootPW表示OpenLDAP管理员的密码`。

##### c、修改olcDatabase={1}monitor.ldif文件

```
修改olcDatabase={1}monitor.ldif文件，如下：
vim /etc/openldap/slapd.d/cn=config/olcDatabase\=\{1\}monitor.ldif

olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=extern
 al,cn=auth" read by dn.base="cn=admin,dc=ops,dc=com" read by * none

```

注意：该修改中的dn.base是修改OpenLDAP的管理员的相关信息的。
验证OpenLDAP的基本配置，使用如下命令：

```
5e5cb0fe ldif_read_file: checksum error on "/etc/openldap/slapd.d/cn=config/olcDatabase={1}monitor.ldif"
5e5cb0fe ldif_read_file: checksum error on "/etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif"
config file testing succeeded
```

上面的`checksum error `报错不用管, 只要配置文件测试succeeded成功就行



##### d、修改文件权限

```
chown  -R ldap.ldap /etc/openldap/
chown  -R ldap.ldap /var/lib/ldap/
```

##### e、启动服务

```
systemctl enable slapd
systemctl start slapd
systemctl status slapd
```



验证服务
OpenLDAP默认监听的端口是389，下面我们来看下是不是389端口，如下：

```
tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      1472/slapd          
tcp6       0      0 :::389                  :::*                    LISTEN      1472/slapd 
```

#### 2、方式二，创建olcRootDN作为管理员账号(推荐)

看到前面两个配置文件，官方不推荐我们直接修改配置文件，而是通过`ldapmodify`来更新配置。

类似于update by pk, 这里的pk就是dn了。

##### a、建rootdn.ldif

```
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=admin,dc=demo,dc=com
-
replace: olcSuffix
olcSuffix: dc=demo,dc=com
-
replace: olcRootPW
olcRootPW: <pass>
```

- 修改olcRootDN， 设置为我们的admin: cn=admin,dc=demo,dc=com
- 修改olcSuffix， 设置为我们的域名dc=demo,dc=com
- 修改olcRootPW， 设置我们的admin密码, 这个需要加密，所以暂时放一个占位符，等下替换
- changetype变更类型， replace表示替换， add表示增加。

**cn=config**是全局配置，必须包含`objectClass: olcGlobal`.



##### b、然后创建changeroot.sh

```
admin_pass=`slappasswd -s admin`
echo "admin pass is:  ${admin_pass}"
sed "s!<pass>!${admin_pass}!g"   rootdn.ldif > tmp.ldif

echo "备份默认配置"

cp /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif.bak

echo "将要修改的内容："
cat tmp.ldif

ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f tmp.ldif

echo "修改后的变化"
diff /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif.bak
```

- `slappasswd -s admin` 获取加密后的密码
- 备份原始文件
- ldapmodify 更新命令， -H指定host，这里`ldapi:///`表示IPC (Unix-domain socket)协议， -f指定变更的内容。 命令文档: http://man7.org/linux/man-pages/man1/ldapmodify.1.html

使用脚本进行变更，而不是直接命令行交互式变更，这样可以更容易梳理变更逻辑, 而且可以重复使用。





### 配置OpenLDAP数据库

##### a、OpenLDAP默认使用的数据库是BerkeleyDB，现在来开始配置OpenLDAP数据库

```
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap:ldap -R /var/lib/ldap
chmod 700 -R /var/lib/ldap
ll /var/lib/ldap/
```

注意：/var/lib/ldap/就是BerkeleyDB数据库默认存储的路径。

##### b、导入基本Schema

```
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
```

##### c、修改migrate_common.ph文件

migrate_common.ph文件主要是用于生成ldif文件使用，修改migrate_common.ph文件

```
vim /usr/share/migrationtools/migrate_common.ph    71行左右

$DEFAULT_MAIL_DOMAIN = “ops.com”;
$DEFAULT_BASE = “dc=ops,dc=com”;
$EXTENDED_SCHEMA = 1;
```



#### 添加我们的base组织结构

创建文件base.ldif

```
dn: dc=ops,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: ldap测试组织
dc: demo

dn: cn=admin,dc=ops,dc=com
objectClass: organizationalRole
cn: Manager
description: 组织管理人

dn: ou=People,dc=demo,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=demo,dc=com
objectClass: organizationalUnit
ou: Group

```

使用`ldapadd`添加base:

```
ldapadd -x -D cn=admin,dc=demo,dc=com -w admin -f base.ldif 
```

使用`ldapsearch`来检查内容

```
[root@a1791f1044ba data]# ldapsearch -x -D cn=admin,dc=ops,dc=com -w 123456 -b "dc=ops,dc=com"
# extended LDIF
#
# LDAPv3
# base <dc=demo,dc=com> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# ops.com
dn: dc=ops,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o:: bGRhcOa1i+ivlee7hOe7hw==
dc: demo

# Manager, demo.com
dn: cn=Manager,dc=demo,dc=com
objectClass: organizationalRole
cn: Manager
description:: 57uE57uH566h55CG5Lq6

# People, demo.com
dn: ou=People,dc=demo,dc=com
objectClass: organizationalUnit
ou: People

# Group, demo.com
dn: ou=Group,dc=demo,dc=com
objectClass: organizationalUnit
ou: Group

# search result
search: 2
result: 0 Success

# numResponses: 5
# numEntries: 4
```

#### 添加用户

添加人员对应的是树的叶子节点，使用的  `oebjectClass： inetOrgPerson`。

添加组织部门对应的是目录，使用的  `objectClass: organizationalUnit`.