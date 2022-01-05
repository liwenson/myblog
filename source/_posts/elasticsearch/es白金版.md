---
title: es 白金版
date: 2022-01-04 10:18
categories:
- elasticsearch
tags:
- es
---
  
  
摘要: es 白金版 , 仅限于学习，非商业用途。
<!-- more -->


## 方法一
#### 安装elasticsearch
略
#### 反编译 x-pack-core-x.x.x.jar
##### 备份
```
elasticsearch-7.5.0\modules\x-pack-core\x-pack-core-7.5.0.jar   #文件赋值一份
```

x-pack的lisence的校验主要是这两个文件：

验证licence是否有效：org.elasticsearch.license.LicenseVerifier
验证jar包是否被修改：org.elasticsearch.xpack.core.XPackBuil

可以使用反编译工具将jar 包源码获取到，也可以新建java文件,写入代码
    反编译工具
    luyten
    JD-GUI

##### 手动创建 XPackBuild.java 和 LicenseVerifier.java 两个文件

XPackBuild.java   最后一个静态代码块中 try的部分全部删除 
```
package org.elasticsearch.xpack.core;

import java.net.*;
import org.elasticsearch.core.*;
import java.nio.file.*;
import java.io.*;
import java.util.jar.*;

public class XPackBuild
{
    public static final XPackBuild CURRENT;
    private String shortHash;
    private String date;
    
    @SuppressForbidden(reason = "looks up path of xpack.jar directly")
    static Path getElasticsearchCodebase() {
        final URL url = XPackBuild.class.getProtectionDomain().getCodeSource().getLocation();
        try {
            return PathUtils.get(url.toURI());
        }
        catch (URISyntaxException bogus) {
            throw new RuntimeException(bogus);
        }
    }
    
    XPackBuild(final String shortHash, final String date) {
        this.shortHash = shortHash;
        this.date = date;
    }
    
    public String shortHash() {
        return this.shortHash;
    }
    
    public String date() {
        return this.date;
    }
    
    static {
        final Path path = getElasticsearchCodebase();
        String shortHash = null;
        String date = null;
        Label_0109: {

            shortHash = "Unknown";
            date = "Unknown";

        }
        CURRENT = new XPackBuild(shortHash, date);
    }
}
```

LicenseVerifier.java    两个静态方法修改为全部返回true
```
package org.elasticsearch.license;

import java.nio.*;
import org.elasticsearch.common.bytes.*;
import java.security.*;
import java.util.*;
import org.elasticsearch.xcontent.*;
import org.apache.lucene.util.*;
import org.elasticsearch.core.internal.io.*;
import java.io.*;

public class LicenseVerifier
{
    public static boolean verifyLicense(final License license, final byte[] publicKeyData) {
        /*
        byte[] signedContent = null;
        byte[] publicKeyFingerprint = null;
        try {
            final byte[] signatureBytes = Base64.getDecoder().decode(license.signature());
            final ByteBuffer byteBuffer = ByteBuffer.wrap(signatureBytes);
            final int version = byteBuffer.getInt();
            final int magicLen = byteBuffer.getInt();
            final byte[] magic = new byte[magicLen];
            byteBuffer.get(magic);
            final int hashLen = byteBuffer.getInt();
            publicKeyFingerprint = new byte[hashLen];
            byteBuffer.get(publicKeyFingerprint);
            final int signedContentLen = byteBuffer.getInt();
            signedContent = new byte[signedContentLen];
            byteBuffer.get(signedContent);
            final XContentBuilder contentBuilder = XContentFactory.contentBuilder(XContentType.JSON);
            license.toXContent(contentBuilder, (ToXContent.Params)new ToXContent.MapParams((Map)Collections.singletonMap("license_spec_view", "true")));
            final Signature rsa = Signature.getInstance("SHA512withRSA");
            rsa.initVerify(CryptUtils.readPublicKey(publicKeyData));
            final BytesRefIterator iterator = BytesReference.bytes(contentBuilder).iterator();
            BytesRef ref;
            while ((ref = iterator.next()) != null) {
                rsa.update(ref.bytes, ref.offset, ref.length);
            }
            return rsa.verify(signedContent);
        }
        catch (IOException ex) {}
        catch (NoSuchAlgorithmException ex2) {}
        catch (SignatureException ex3) {}
        catch (InvalidKeyException e) {
            throw new IllegalStateException(e);
        }
        finally {
            if (signedContent != null) {
                Arrays.fill(signedContent, (byte)0);
            }
        }
        */
        return true;
    }
    
    public static boolean verifyLicense(final License license) {
        /*
        byte[] publicKeyBytes;
        try {
            final InputStream is = LicenseVerifier.class.getResourceAsStream("/public.key");
            try {
                final ByteArrayOutputStream out = new ByteArrayOutputStream();
                Streams.copy(is, (OutputStream)out);
                publicKeyBytes = out.toByteArray();
                if (is != null) {
                    is.close();
                }
            }
            catch (Throwable t) {
                if (is != null) {
                    try {
                        is.close();
                    }
                    catch (Throwable t2) {
                        t.addSuppressed(t2);
                    }
                }
                throw t;
            }
        }
        catch (IOException ex) {
            throw new IllegalStateException(ex);
        }
        return verifyLicense(license, publicKeyBytes);
        */
        return true;
    }
}

```

#### 编译
```
javac -cp "/ztocwst/elasticsearch-7.16.2/lib/elasticsearch-7.16.2.jar:/ztocwst/elasticsearch-7.16.2/lib/elasticsearch-x-content-7.16.2.jar:/ztocwst/elasticsearch-7.16.2/lib/lucene-core-8.10.1.jar:/ztocwst/elasticsearch-7.16.2/modules/x-pack-core/x-pack-core-7.16.2.jar:/ztocwst/elasticsearch-7.16.2/modules/x-pack-core/netty-common-4.1.66.Final.jar:/ztocwst/elasticsearch-7.16.2/lib/elasticsearch-core-7.16.2.jar" XPackBuild.java



javac -cp "/ztocwst/elasticsearch-7.16.2/lib/elasticsearch-7.16.2.jar:/ztocwst/elasticsearch-7.16.2/lib/elasticsearch-x-content-7.16.2.jar:/ztocwst/elasticsearch-7.16.2/lib/lucene-core-8.10.1.jar:/ztocwst/elasticsearch-7.16.2/modules/x-pack-core/x-pack-core-7.16.2.jar:/ztocwst/elasticsearch-7.16.2/modules/x-pack-core/netty-common-4.1.66.Final.jar:/ztocwst/elasticsearch-7.16.2/lib/elasticsearch-core-7.16.2.jar" LicenseVerifier.java

```


#### 打包替换
```
jar -xvf x-pack-core-7.16.2.jar
cp XPackBuild.class org/elasticsearch/xpack/core/
cp LicenseVerifier.class org/elasticsearch/license/


jar cvf x-pack-core-7.16.2.jar .

cp x-pack-core-7.16.2.jar /ztocwst/elasticsearch-7.16.2/modules/x-pack-core/x-pack-core-7.16.2.jar
```

#### 启动服务
禁用elasticsearch安全协议
导出许可证书之前要先关闭xpack安全认证，打开../config/elasticsearch.yml文件在末尾添加:
```
xpack.security.enabled: false
```
并启动elasticsearch服务：
```
./bin/elasticsearch -d
```

#### 导入license

license.json
```
{"license":{"uid":"3b93c113-e459-4749-924d-c2abe8627a8e","type":"platinum","issue_date_in_millis":1572825600000,"expiry_date_in_millis":2524579200999,"max_nodes":1000,"issued_to":"wsli li (zto)","issuer":"Web Form","signature":"AAAAAwAAAA2CJbVaZb7rsZ7C9zk8AAABmC9ZN0hjZDBGYnVyRXpCOW5Bb3FjZDAxOWpSbTVoMVZwUzRxVk1PSmkxaktJRVl5MUYvUWh3bHZVUTllbXNPbzBUemtnbWpBbmlWRmRZb25KNFlBR2x0TXc2K2p1Y1VtMG1UQU9TRGZVSGRwaEJGUjE3bXd3LzRqZ05iLzRteWFNekdxRGpIYlFwYkJiNUs0U1hTVlJKNVlXekMrSlVUdFIvV0FNeWdOYnlESDc3MWhlY3hSQmdKSjJ2ZTcvYlBFOHhPQlV3ZHdDQ0tHcG5uOElCaDJ4K1hob29xSG85N0kvTWV3THhlQk9NL01VMFRjNDZpZEVXeUtUMXIyMlIveFpJUkk2WUdveEZaME9XWitGUi9WNTZVQW1FMG1DenhZU0ZmeXlZakVEMjZFT2NvOWxpZGlqVmlHNC8rWVVUYzMwRGVySHpIdURzKzFiRDl4TmM1TUp2VTBOUlJZUlAyV0ZVL2kvVk10L0NsbXNFYVZwT3NSU082dFNNa2prQ0ZsclZ4NTltbU1CVE5lR09Bck93V2J1Y3c9PQAAAQBr+ifM6Ws3/WZM9sZ0Sk3GoaX35ZVUVEyEADClbh1c+Aa549YW3aI+TEdBlL51/WOKVb7viOTa3hsDp/B3iIQ2aXgnBeLzSTcJ4eS2sLpAvzCXQpqGO+v4ZxbTnBWugIfExM8m5Rk3mQ73QpzSFz21gE/IFE+bk8Wh9aGYgdX8VW85dgYJjfKUQ5MU/Qnwx8pCE6z9C/uDloMm8FhDxVMt1A/1WGDPIpA5YAlc6sTRLQVi3aqUcpydco6vagUdWRmrFGZBtQtRcvc1VxcphKAZCj0E22r3uEcyDuF4bOqiKIEuWcDQIbwyGVJqBsIdQorOTL2e7drmU4JYJJdHmNS1","start_date_in_millis":1572825600000}}
```
```
curl -XPUT -u elastic 'http://192.168.1.9:9200/_xpack/license' -H "Content-Type: application/json" -d @license.json
```

导入成功后再把xpack安全认证打开：
```
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
```

#### 内置账号创建密码
使用内置帐号需要设置密码，执行命令：./bin/elasticsearch-setup-passwords interactive   按提示输入密码 


## 方法二
改方法不需要导入license 文件， 测试下来，好像不太稳定

#### 目录结构
```
. 7.5.0
├── build
│   └── src
├── install
└── src
```


#### 安装elasticsearch
略

#### 获取对应版本的源码
```
wget https://github.com/elastic/elasticsearch/archive/v7.5.0.tar.gz -O elasticsearch-v7.5.0.tar.gz
```

#### 解压
```
tar zxvf elasticsearch-v7.5.0.tar.gz
```

#### 编译x-pack包
```
mkdir build && cd build

# lib module
ln -s ../install/elasticsearch-7.5.0/lib .
ln -s ../install/elasticsearch-7.5.0/modules .


# License.java
find ../src -name "License.java" | xargs -r -I {} cp {} .
sed -i 's#this.type = type;#this.type = "platinum";#g' License.java
sed -i 's#validate();#// validate();#g' License.java


# 编译
javac -cp "`ls lib/elasticsearch-7.5.0.jar`:`ls lib/elasticsearch-x-content-7.5.0.jar`:`ls lib/lucene-core-*.jar`:`ls modules/x-pack-core/x-pack-core-7.5.0.jar`" License.java

# x-pack-core-7.5.0.jar
mkdir src && cd src
find ../../install -name "x-pack-core-7.5.0.jar" | xargs -r -I {} cp {} .
jar xvf x-pack-core-7.5.0.jar
rm -f x-pack-core-7.5.0.jar
\cp -f ../License*.class org/elasticsearch/license/
jar cvf x-pack-core-7.5.0.jar .
``` 
#### 覆盖x-pack-core-7.5.0.jar
把编译后的x-pack-core-7.5.0.jar文件覆盖到安装目录下
```
cp 7.5.0/build/src/x-pack-core-7.5.0.jar /usr/share/elasticsearch/modules/x-pack-core/
```



