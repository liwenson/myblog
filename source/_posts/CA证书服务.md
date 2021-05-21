---
title: 本地搭建CA 证书服务
date: 2019-12-18 10:00:00
categories: 
- linux
tags:
- ca
- ssl
---

[TOC]

## 一、搭建CA服务

openssl 默认配置文件: ` /etc/pki/tls/openssl.cnf`

### 1、初始化目录

```shell
# cd /etc/pki/CA
# mkdir certs crl newcerts private
# tree
.
|-- certs
|-- crl
|-- newcerts
`-- private

4 directories, 0 files
```

### 2、创建CA需要的文件

```bash
# touch index.txt
# echo 01 > serial
# ll
total 20
drwx--x--x 2 root root 4096 Dec 18 02:59 certs
drwx--x--x 2 root root 4096 Dec 18 02:59 crl
-rw------- 1 root root    0 Dec 18 02:59 index.txt
drwx--x--x 2 root root 4096 Dec 18 02:59 newcerts
drwx--x--x 2 root root 4096 Dec 18 02:59 private
-rw------- 1 root root    3 Dec 18 03:00 serial
```



### 3、给CA创建私钥

```bash
# pwd
/etc/pki/CA

# (umask 066;openssl genrsa -out private/cakey.pem 2048)
Generating RSA private key, 2048 bit long modulus
........+++
.................+++
e is 65537 (0x10001)


# tree
.
|-- certs
|-- crl
|-- index.txt
|-- newcerts
|-- private
|   `-- cakey.pem
`-- serial

4 directories, 3 files
```



### 4、给CA生成自签名证书

```
# openssl req -new -x509 -key private/cakey.pem -days 7300 -out cacert.pem

You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [CN]:
State or Province Name (full name) [ZheJiang]:
Locality Name (eg, city) [HangZhou]:
Organization Name (eg, company) [ZTYC]:
Organizational Unit Name (eg, section) [ztyc]:
Common Name (eg, your name or your server's hostname) []:
Email Address []:

# ls
cacert.pem  certs  crl  index.txt  newcerts  private  serial

```



## 二、使用CA给客户颁发证书



### 1、客户机生成私钥

```bash
client opt]# (umask 066;openssl genrsa -out wms.qa.ops.com.key 2048)

Generating RSA private key, 2048 bit long modulus
..............+++
.........................................................................+++
e is 65537 (0x10001)

client opt]# ls
wms.qa.ops.com.key
```



### 2、生成证书申请文件

```bash
client opt]# openssl req -new -key wms.qa.ops.com.key -days 365 -out wms.qa.ops.com.csr

You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [CN]:
State or Province Name (full name) [ZheJiang]:
Locality Name (eg, city) [HangZhou]:
Organization Name (eg, company) [ZTYC]:
Organizational Unit Name (eg, section) [ztyc]:
Common Name (eg, your name or your server's hostname) []:wms.qa.ops.com
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:

client opt]#ls
wms.qa.ops.com.csr  wms.qa.ops.com.key

```

### 3、将证书申请文件传输到CA服务器上

```bash
# pwd
/etc/pki/CA

# ls crl/
wms.qa.ops.com.csr
```



### 4、在CA上给申请签证的客户签署证书

```
# pwd
/etc/pki/CA

# openssl ca -in crl/wms.qa.ops.com.csr -out certs/wms.qa.ops.com.crt -days 365

Using configuration from /etc/pki/tls/openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 1 (0x1)
        Validity
            Not Before: Dec 18 03:33:30 2019 GMT
            Not After : Dec 17 03:33:30 2020 GMT
        Subject:
            countryName               = CN
            stateOrProvinceName       = ZheJiang
            organizationName          = ZTYC
            organizationalUnitName    = ztyc
            commonName                = wms.qa.ops.com
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Comment: 
                OpenSSL Generated Certificate
            X509v3 Subject Key Identifier: 
                B2:35:6B:B9:16:86:4C:76:99:C8:27:64:7A:60:FC:B0:82:59:64:8A
            X509v3 Authority Key Identifier: 
                keyid:70:EB:D1:7E:7A:D0:29:AE:65:10:73:D3:16:7D:6C:CD:12:C8:F1:FB

Certificate is to be certified until Dec 17 03:33:30 2020 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated


```



### 5、将CA上将签署好的证书传输给申请的客户

```bash
client opt]# ls 
wms.qa.ops.com.crt  wms.qa.ops.com.csr  wms.qa.ops.com.key

```

### 6、查看颁发的证书

```bash
client opt]# openssl x509 -in wms.qa.ops.com.crt -noout -text

Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=CN, ST=ZheJiang, L=HangZhou, O=ZTYC, OU=ztyc
        Validity
            Not Before: Dec 18 03:33:30 2019 GMT
            Not After : Dec 17 03:33:30 2020 GMT
        Subject: C=CN, ST=ZheJiang, O=ZTYC, OU=ztyc, CN=wms.qa.ops.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:b9:20:cf:dc:bc:d4:06:b6:a0:15:1a:22:52:21:
                    1f:64:c1:81:90:47:83:70:21:00:0a:ba:2a:ac:00:
                    22:3d:3d:c3:d7:4a:2c:51:11:5e:df:e8:6c:41:2e:
.....
.....

```

### 7、crt转pem格式

```bash
client opt]# openssl x509 -in wms.qa.ops.com.crt -inform DER -outform PEM -out wms.qa.ops.com.pem
client opt]# ls
wms.qa.ops.com.crt  wms.qa.ops.com.csr  wms.qa.ops.com.key  wms.qa.ops.com.pem
```

### 8、证书转换为PKCS12文件

```shell
client opt]# openssl pkcs12 -export -clcerts -in wms.qa.ops.com.crt \
-inkey wms.qa.ops.com.key -out wms.qa.ops.com.key.p12
client opt]# ls
wms.qa.ops.com.crt  wms.qa.ops.com.csr  wms.qa.ops.com.key  wms.qa.ops.com.pem   wms.qa.ops.com.key.p12
```



## 三、CA上吊销证书

### 查看证书的serial以及subject信息

1、在申请吊销证书的客户机上查看需要吊销的证书的serial以及subject信息，并提交给CA

```bash
client opt]# openssl x509 -in qa.ops.com.crt -noout -serial -subject
serial=03
subject= /C=CN/ST=ZheJiang/O=ZTYC/OU=ops/CN=qa.ops.com/emailAddress=ops@ztyc.com
```

2、在CA上根据客户提交的serial以及subject信息，比对服务器上index.txt文件中的信息一致后，执行吊销证书操作

```bash
# pwd
/etc/pki/CA

# openssl x509 -in certs/qa.ops.com.crt -noout -serial -subject
serial=03
subject= /C=CN/ST=ZheJiang/O=ZTYC/OU=ops/CN=qa.ops.com/emailAddress=ops@ztyc.com

# cat index.txt

V	291215081847Z		03	unknown	/C=CN/ST=ZheJiang/O=ZTYC/OU=ops/CN=qa.ops.com/emailAddress=ops@ztyc.com
```

3、信息确认一致，正式执行吊销操作

```bash
# openssl ca -revoke newcerts/03.pem 
Using configuration from /etc/pki/tls/openssl.cnf
Revoking Certificate 03.
Data Base Updated

```

4、生成吊销证书的编号（第一次吊销证书时才需要执行本操作)

```bash
# pwd
/etc/pki/CA

# echo 01 > crlnumber

# openssl ca -gencrl -out crl/qa.ops.com.csr 
Using configuration from /etc/pki/tls/openssl.cnf

# openssl crl -in crl/qa.ops.com.csr -noout -text
Certificate Revocation List (CRL):
        Version 2 (0x1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: /C=CN/ST=ZheJiang/L=HangZhou/O=ZTYC/OU=ztyc
        Last Update: Dec 18 08:32:01 2019 GMT
        Next Update: Jan 17 08:32:01 2020 GMT
        CRL extensions:
            X509v3 CRL Number: 
                1
Revoked Certificates:
    Serial Number: 01
        Revocation Date: Dec 18 08:29:24 2019 GMT
    Serial Number: 03
        Revocation Date: Dec 18 08:29:31 2019 GMT
    Signature Algorithm: sha256WithRSAEncryption
         5e:68:d9:a1:ef:1d:7f:83:23:a4:57:95:19:1b:7a:36:82:cc:
         3a:2a:73:d8:1d:77:03:1a:e5:fd:5d:40:a8:e2:0a:af:34:d7:
         04:e5:7e:a8:c6:58:36:34:33:d7:79:bf:e0:07:29:f3:72:5b:
         e8:5d:f4:06:ba:e3:1f:00:2e:f5:4b:47:18:7c:e1:0d:00:3e:
         2e:13:eb:57:06:be:7f:48:5a:13:ef:62:cc:1e:92:76:22:f3:
         c2:6b:d0:12:e0:26:4c:33:be:fe:fd:14:de:77:da:6a:20:ce:
         f5:41:6e:e7:f1:e0:5d:d1:4f:91:e3:97:49:0d:a4:c9:0d:c4:
         cd:3a:51:5f:31:5b:ed:fc:55:9f:6b:9c:72:c9:7d:92:25:7b:
         e8:ec:e0:96:b6:98:96:ac:b7:63:40:d5:ec:b7:09:74:e9:c0:
         96:b6:2c:55:4b:de:fa:fa:2c:74:2e:f8:96:2e:4f:bc:5f:d2:
         0b:15:1a:6d:1f:e7:1e:8b:d3:af:51:d6:ca:2d:90:9f:9f:03:
         c2:da:03:f7:0f:a5:6a:e4:f7:3d:25:a1:06:05:c4:de:5e:62:
         5e:a5:7d:25:7e:9c:16:82:7f:21:28:d0:a3:d6:5c:e7:26:48:
         03:e0:93:84:fb:f3:b3:0a:d9:e6:35:3e:ae:d7:9f:65:b5:b6:
         fa:6a:69:67

```

## 四、在浏览器中访问

在浏览器中打开https://<domain_name>来访问。

在Firefox浏览器中可以添加 Security Exception 来忽略HTTPS错误警告。

Chrome浏览器可以尝试通过导入CA证书的方式来忽略HTTPS错误警告。

>注意：Chrome 浏览器可能有导入CA证书后仍然无法访问的问题；不同浏览器对自签名SSL证书的检查和限制也有所区别。



## 五、脚本

### 一、结合上面文档使用

```shell
#!/bin/bash -e

SSL_IP=''
SSL_DNS='wms.qa.opt.com'
CN=${SSL_DNS}
SSL_SIZE=2048

DATE=${DATE:-3650}

SSL_CONFIG='openssl.cnf'
SSL_SUBJECT="/C=CN/ST=ZheJiang/L=HangZhou/O=ZTYC/OU=ops/CN=${CN}/emailAddress=ops@ztyc.com"
CA_DIR='/etc/pki/CA'

if [[ -z $SILENT ]]; then
echo "----------------------------"
echo "| SSL Cert Generator |"
echo "----------------------------"
echo
fi

export SSL_DNS=${SSL_DNS}
export SSL_IP=${SSL_IP}
export SSL_KEY=$CN.key
export SSL_CSR=$CN.csr
export SSL_SUBJECT=${SSL_SUBJECT}
export CA_DIR=${CA_DIR}
export SSL_CERT=$CN.crt
export SSL_PEM=$CN.pem

dir=$(pwd)
echo -e "The current working directory is \033[36m ${dir} \033[0m"

echo "====> Generating new config file ${SSL_CONFIG}"
cat > ${SSL_CONFIG} <<EOM
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOM

if [[ -n ${SSL_DNS} || -n ${SSL_IP} ]]; then
cat >> ${SSL_CONFIG} <<EOM
subjectAltName = @alt_names
[alt_names]
EOM
    IFS=","
    dns=(${SSL_DNS})
    for i in "${!dns[@]}"; do
      echo DNS.$((i+1)) = ${dns[$i]} >> ${SSL_CONFIG}
    done

    if [[ -n ${SSL_IP} ]]; then
        ip=(${SSL_IP})
        for i in "${!ip[@]}"; do
          echo IP.$((i+1)) = ${ip[$i]} >> ${SSL_CONFIG}
        done
    fi
fi

[[ -z $SILENT ]] && echo "====> Generating new SSL KEY ${SSL_KEY}"
echo -e "\033[36m openssl genrsa -out ${SSL_KEY} ${SSL_SIZE} \033[0m"
openssl genrsa -out ${SSL_KEY} ${SSL_SIZE} > /dev/null || exit 1

[[ -z $SILENT ]] && echo "====> Generating new SSL CSR ${SSL_CSR}"
echo -e "\033[36m openssl req -sha256 -new -key ${SSL_KEY} -out ${SSL_CSR} -subj \"${SSL_SUBJECT}\" -config ${SSL_CONFIG} \033[0m"
openssl req -sha256 -new -key ${SSL_KEY} -out ${SSL_CSR} \
-subj "${SSL_SUBJECT}" -config ${SSL_CONFIG} > /dev/null || exit 1

[[ -z $SILENT ]] && echo "====> Generating new SSL CERT ${SSL_CERT}"
\cp ${SSL_CSR} ${CA_DIR}/crl
cd ${CA_DIR}
echo -e "The current working directory is \033[36m $(pwd)\033[0m"
echo -e "\033[36m openssl ca -in crl/${SSL_CSR} -out certs/${SSL_CERT}  -days ${DATE} \033[0m"
#openssl ca -in crl/${SSL_CSR} -out certs/${SSL_CERT}  -days ${DATE}  || exit 1
/usr/bin/expect <<END
  spawn openssl ca -in crl/${SSL_CSR} -out certs/${SSL_CERT}  -days ${DATE}
  expect {
    "*y/n]:" {send "y\r";exp_continue}
    "*y/n]" {send "y\r";exp_continue}
  }
END
\cp certs/${SSL_CERT} ${dir}
cd ${dir}

echo -e "The current working directory is \033[36m $(pwd)\033[0m"
echo -e "\033[36m openssl x509 -in ${SSL_CERT} -out ${SSL_PEM} -outform PEM \033[0m"
openssl x509 -in ${SSL_CERT}  -out ${SSL_PEM} -outform PEM
ls


if [[ -z $SILENT ]]; then
echo "====> Complete"
echo -e "keys can be found in volume mapped to \033[36m $(pwd)\033[0m"
echo
echo "====> Output results as YAML"
openssl x509 -in ${SSL_CERT} -noout -text
fi

```

### 二、独立使用

```shell
#!/bin/bash -e

# * 为必改项
# * 更换为你自己的域名
CN='' # 例如: demo.rancher.com

# 扩展信任IP或域名
## 一般ssl证书只信任域名的访问请求，有时候需要使用ip去访问server，那么需要给ssl证书添加扩展IP，
## 多个IP用逗号隔开。如果想多个域名访问，则添加扩展域名（SSL_DNS）,多个SSL_DNS用逗号隔开
SSL_IP='' # 例如: 1.2.3.4
SSL_DNS='' # 例如: demo.rancher.com

# 国家名(2个字母的代号)
C=CN

# 证书加密位数
SSL_SIZE=2048

# 证书有效期
DATE=${DATE:-3650}

# 配置文件
SSL_CONFIG='openssl.cnf'

if [[ -z $SILENT ]]; then
echo "----------------------------"
echo "| SSL Cert Generator |"
echo "----------------------------"
echo
fi

export CA_KEY=${CA_KEY-"cakey.pem"}
export CA_CERT=${CA_CERT-"cacerts.pem"}
export CA_SUBJECT=ca-$CN
export CA_EXPIRE=${DATE}

export SSL_CONFIG=${SSL_CONFIG}
export SSL_KEY=$CN.key
export SSL_CSR=$CN.csr
export SSL_CERT=$CN.crt
export SSL_EXPIRE=${DATE}

export SSL_SUBJECT=${CN}
export SSL_DNS=${SSL_DNS}
export SSL_IP=${SSL_IP}

export K8S_SECRET_COMBINE_CA=${K8S_SECRET_COMBINE_CA:-'true'}

[[ -z $SILENT ]] && echo "--> Certificate Authority"

if [[ -e ./${CA_KEY} ]]; then
    [[ -z $SILENT ]] && echo "====> Using existing CA Key ${CA_KEY}"
else
    [[ -z $SILENT ]] && echo "====> Generating new CA key ${CA_KEY}"
    openssl genrsa -out ${CA_KEY} ${SSL_SIZE} > /dev/null
fi

if [[ -e ./${CA_CERT} ]]; then
    [[ -z $SILENT ]] && echo "====> Using existing CA Certificate ${CA_CERT}"
else
    [[ -z $SILENT ]] && echo "====> Generating new CA Certificate ${CA_CERT}"
    openssl req -x509 -sha256 -new -nodes -key ${CA_KEY} \
    -days ${CA_EXPIRE} -out ${CA_CERT} -subj "/CN=${CA_SUBJECT}" > /dev/null || exit 1
fi

echo "====> Generating new config file ${SSL_CONFIG}"
cat > ${SSL_CONFIG} <<EOM
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOM

if [[ -n ${SSL_DNS} || -n ${SSL_IP} ]]; then
    cat >> ${SSL_CONFIG} <<EOM
subjectAltName = @alt_names
[alt_names]
EOM
    IFS=","
    dns=(${SSL_DNS})
    dns+=(${SSL_SUBJECT})
    for i in "${!dns[@]}"; do
      echo DNS.$((i+1)) = ${dns[$i]} >> ${SSL_CONFIG}
    done

    if [[ -n ${SSL_IP} ]]; then
        ip=(${SSL_IP})
        for i in "${!ip[@]}"; do
          echo IP.$((i+1)) = ${ip[$i]} >> ${SSL_CONFIG}
        done
    fi
fi

[[ -z $SILENT ]] && echo "====> Generating new SSL KEY ${SSL_KEY}"
openssl genrsa -out ${SSL_KEY} ${SSL_SIZE} > /dev/null || exit 1

[[ -z $SILENT ]] && echo "====> Generating new SSL CSR ${SSL_CSR}"
openssl req -sha256 -new -key ${SSL_KEY} -out ${SSL_CSR} \
-subj "/CN=${SSL_SUBJECT}" -config ${SSL_CONFIG} > /dev/null || exit 1

[[ -z $SILENT ]] && echo "====> Generating new SSL CERT ${SSL_CERT}"
openssl x509 -sha256 -req -in ${SSL_CSR} -CA ${CA_CERT} \
    -CAkey ${CA_KEY} -CAcreateserial -out ${SSL_CERT} \
    -days ${SSL_EXPIRE} -extensions v3_req \
    -extfile ${SSL_CONFIG} > /dev/null || exit 1

if [[ -z $SILENT ]]; then
echo "====> Complete"
echo "keys can be found in volume mapped to $(pwd)"
echo
echo "====> Output results as YAML"
echo "---"
echo "ca_key: |"
cat $CA_KEY | sed 's/^/  /'
echo
echo "ca_cert: |"
cat $CA_CERT | sed 's/^/  /'
echo
echo "ssl_key: |"
cat $SSL_KEY | sed 's/^/  /'
echo
echo "ssl_csr: |"
cat $SSL_CSR | sed 's/^/  /'
echo
echo "ssl_cert: |"
cat $SSL_CERT | sed 's/^/  /'
echo
fi

if [[ -n $K8S_SECRET_NAME ]]; then

  if [[ -n $K8S_SECRET_COMBINE_CA ]]; then
    [[ -z $SILENT ]] && echo "====> Adding CA to Cert file"
    cat ${CA_CERT} >> ${SSL_CERT}
  fi

  [[ -z $SILENT ]] && echo "====> Creating Kubernetes secret: $K8S_SECRET_NAME"
  kubectl delete secret $K8S_SECRET_NAME --ignore-not-found

  if [[ -n $K8S_SECRET_SEPARATE_CA ]]; then
    kubectl create secret generic \
    $K8S_SECRET_NAME \
    --from-file="tls.crt=${SSL_CERT}" \
    --from-file="tls.key=${SSL_KEY}" \
    --from-file="ca.crt=${CA_CERT}"
  else
    kubectl create secret tls \
    $K8S_SECRET_NAME \
    --cert=${SSL_CERT} \
    --key=${SSL_KEY}
  fi

  if [[ -n $K8S_SECRET_LABELS ]]; then
    [[ -z $SILENT ]] && echo "====> Labeling Kubernetes secret"
    IFS=$' \n\t' # We have to reset IFS or label secret will misbehave on some systems
    kubectl label secret \
      $K8S_SECRET_NAME \
      $K8S_SECRET_LABELS
  fi
fi

echo "4. 重命名服务证书"
mv ${CN}.key tls.key
mv ${CN}.crt tls.crt
```

