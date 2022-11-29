---
title: sonar集成p3c
date: 2022-05-16 11:47
categories:
- sonar
tags:
- p3c
---
  
  
摘要: SonarQube集成阿里巴巴开发手册
<!-- more -->

## 前言

sonar 自带检测 java 代码规则插件，也可以开发自定义的插件。《阿里巴巴Java开发手册》在业界影响很大，很多公司领导希望在自己的团队推行起来，让团队有一套共同的开发准则。我们把阿里的p3c规则集成到sonar，用这套方案来检测 java 代码质量。

Sonar是一个用于代码质量管理的开源平台，用于管理Java源代码的质量。

sonar-pmd 是sonar官方的支持pmd的插件，但是还不支持p3c，需要在pmd插件源码中添加p3c支持。

p3c是阿里在pmd基础上根据阿里巴巴开发手册实现了其中的49开发规则。

通过 sonar-pmd 插件集成 p3c 来实现sonar 支持p3c规则。

## 当前最新版本

sonar-pmd 版本: 3.4.0
p3c-pmd 版本: 2.1.1

## 获取 Sonar-PMD

```bash
git clone https://github.com/jborgers/sonar-pmd.git
```

## 添加p3c规则

### 添加p3c pom依赖

```bash
vim sonar-pmd-plugin/pom.xml
```

p3cm-pmd依赖gson

```xml
    <dependency>
      <groupId>com.alibaba.p3c</groupId>
      <artifactId>p3c-pmd</artifactId>
      <version>2.1.1</version>
    </dependency>
    <dependency>
      <groupId>com.google.code.gson</groupId>
      <artifactId>gson</artifactId>
      <version>2.9.0</version>
    </dependency>
```

### 集成p3c规则

将 <https://github.com/xiaozi0lei/sonar-pmd-p3c-chinese> 仓库中的规则文件替换，追加到最新的sonar-pmd 中

涉及变更的文件

PmdRulesDefinition.java (src/main/java/org/sonar/plugins/pmd/rule/PmdRulesDefinition.java)

pmd.properties (src/main/resources/org/sonar/l10n/pmd.properties)

<!-- p3c-pmd的描述信息在 `p3c/p3c-pmd/src/main/resources/messages.xml` -->
rules.xml (src/main/resources/org/sonar/plugins/pmd/rules.xml)

pmd-model.xml (src/main/resources/com/sonar/sqale/pmd-model.xml)

提示文件 (src/main/resources/org/sonar/l10n/pmd/rules/pmd-p3c)

#### pmd.properties

在 pmd.properties 文件结尾追加

将 sonar-pmd-p3c-chinese 项目的pmd.properties 中p3c 注释后的内容追加到sonar-pmd的pmd.properties 文件

pmd.properties (src/main/resources/org/sonar/l10n/pmd.properties)

```ini

##p3c##
#AlibabaJavaComments
rule.pmd.CommentsMustBeJavadocFormatRule.name=[p3c]Javadoc should be used for classes, class variables and methods. The format should be '/** comment **/', rather than '// xxx'.
rule.pmd.AbstractMethodOrInterfaceMethodMustUseJavadocRule.name=[p3c]Abstract methods (including methods in interface) should be commented by Javadoc.
rule.pmd.ClassMustHaveAuthorRule.name=[p3c]Every class should include information of author(s) and date.
rule.pmd.EnumConstantsMustHaveCommentRule.name=[p3c]All enumeration type fields should be commented as Javadoc style.
rule.pmd.AvoidCommentBehindStatementRule.name=[p3c]Single line comments in a method should be put above the code to be commented, by using // and multiple lines by using /* */.
rule.pmd.RemoveCommentedCodeRule.name=[p3c]Codes or configuration that is noticed to be obsoleted should be resolutely removed from projects.

#AlibabaJavaConcurrent
rule.pmd.ThreadPoolCreationRule.name=[p3c]Manually create thread pool is better.
rule.pmd.AvoidUseTimerRule.name=[p3c]Use ScheduledExecutorService instead.
rule.pmd.ThreadShouldSetNameRule.name=[p3c]A meaningful thread name is helpful to trace the error information,so assign a name when creating threads or thread pools.
rule.pmd.AvoidCallStaticSimpleDateFormatRule.name=[p3c]SimpleDataFormat is unsafe, do not define it as a static variable. If have to, lock or DateUtils class must be used.
rule.pmd.ThreadLocalShouldRemoveRule.name=[p3c]type 'ThreadLocal' must call remove() method at least one times.
rule.pmd.AvoidConcurrentCompetitionRandomRule.name=[p3c]Avoid using [Math.random()] by multiple threads.
rule.pmd.CountDownShouldInFinallyRule.name=[p3c]should be called in finally block.
rule.pmd.AvoidManuallyCreateThreadRule.name=[p3c]Explicitly creating threads is not allowed, use thread pool instead.
rule.pmd.LockShouldWithTryFinallyRule.name=[p3c]Lock operation [%s] must immediately follow by try block, and unlock operation must be placed in the first line of finally block.

#AlibabaJavaConstants
rule.pmd.UpperEllRule.name=[p3c]'L' instead of 'l' should be used for long or Long variable.
rule.pmd.UndefineMagicConstantRule.name=[p3c]Magic values, except for predefined, are forbidden in coding.

#AlibabaJavaExceptions
rule.pmd.MethodReturnWrapperTypeRule.name=[p3c]If the return type is primitive, return a value of wrapper class may cause NullPointerException.
rule.pmd.AvoidReturnInFinallyRule.name=[p3c]Never use return within a finally block.
rule.pmd.TransactionMustHaveRollbackRule.name=[p3c]Attribute rollbackFor of annotation Transactional must be set.

#AlibabaJavaFlowControl
rule.pmd.SwitchStatementRule.name=[p3c]In a switch block, each case should be finished by break/return.
rule.pmd.NeedBraceRule.name=[p3c]Braces are used with if, else, for, do and while statements, even if the body contains only a single statement.
rule.pmd.AvoidComplexConditionRule.name=[p3c]Do not use complicated statements in conditional statements.
rule.pmd.AvoidNegationOperatorRule.name=[p3c]The negation operator is not easy to be quickly understood.

#AlibabaJavaNaming
rule.pmd.ClassNamingShouldBeCamelRule.name=[p3c]Class names should be nouns in UpperCamelCase except domain models: DO, BO, DTO, VO, etc.
rule.pmd.AbstractClassShouldStartWithAbstractNamingRule.name=[p3c]Abstract class names must start with Abstract or Base.
rule.pmd.ExceptionClassShouldEndWithExceptionRule.name=[p3c]Must be ended with Exception.
rule.pmd.TestClassShouldEndWithTestNamingRule.name=[p3c]Test cases should be ended with Test.
rule.pmd.LowerCamelCaseVariableNamingRule.name=[p3c]Method names, parameter names, member variable names, and local variable names should be written in lowerCamelCase.
rule.pmd.AvoidStartWithDollarAndUnderLineNamingRule.name=[p3c]All names should not start or end with an underline or a dollar sign.
rule.pmd.ServiceOrDaoClassShouldEndWithImplRule.name=[p3c]Constant variable names should be written in upper characters separated by underscores.
rule.pmd.ConstantFieldShouldBeUpperCaseRule.name=[p3c]Constant variable names should be written in upper characters separated by underscores.
rule.pmd.PackageNamingRule.name=[p3c]All Service and DAO classes must be interface based on SOA principle. Implementation class names.
rule.pmd.BooleanPropertyShouldNotStartWithIsRule.name=[p3c]Do not add 'is' as prefix while defining Boolean variable.
rule.pmd.ArrayNamingShouldHaveBracketRule.name=[p3c]Brackets are a part of an Array type. The definition could be: String[] args

#AlibabaJavaOop
rule.pmd.EqualsAvoidNullRule.name=[p3c]Equals should be invoked by a constant or an object that is definitely not null.
rule.pmd.WrapperTypeEqualityRule.name=[p3c]The wrapper classes should be compared by equals method rather than by symbol of '==' directly.
rule.pmd.PojoMustUsePrimitiveFieldRule.name=[p3c]Rules for using primitive data types and wrapper classes.
rule.pmd.PojoNoDefaultValueRule.name=[p3c]While defining POJO classes like DO, DTO, VO, etc., do not assign any default values to the members.
rule.pmd.PojoMustOverrideToStringRule.name=[p3c]We can call the toString method in a POJO directly to print property values.
rule.pmd.StringConcatRule.name=[p3c]Use the append method in StringBuilder inside a loop body when concatenating multiple strings.
rule.pmd.BigDecimalAvoidDoubleConstructorRule.name=[p3c]Avoid using the constructor BigDecimal(double) to convert double value to a BigDecimal object.

#orm
rule.pmd.IbatisMethodQueryForListRule.name=[p3c]iBatis built in com.ibatis.sqlmap.client.SqlMapClient.queryForList(String statementName,int start,int size) is not recommended

#AlibabaJavaOthers
rule.pmd.AvoidPatternCompileInMethodRule.name=[p3c]When using regex, precompile needs to be done in order to increase the matching performance.
rule.pmd.AvoidApacheBeanUtilsCopyRule.name=[p3c]Avoid using *Apache BeanUtils* to copy attributes.
rule.pmd.AvoidNewDateGetTimeRule.name=[p3c]Use System.currentTimeMillis() to get the current millisecond. Do not use new Date().getTime().
rule.pmd.AvoidMissUseOfMathRandomRule.name=[p3c]The return type of Math.random() is double, value range is 0<=x<1 (0 is possible).
rule.pmd.MethodTooLongRule.name=[p3c]The total number of lines for a method should not be more than 80.
rule.pmd.UseRightCaseForDateFormatRule.name=[p3c]Date format string [%s] is error,When doing date formatting, 'y' should be written in lowercase for 'year'.
rule.pmd.AvoidDoubleOrFloatEqualCompareRule.name=[p3c]To judge the equivalence of floating-point numbers, == cannot be used for primitive types, while equals cannot be used for wrapper classes.

#AlibabaJavaSets
rule.pmd.ClassCastExceptionWithToArrayRule.name=[p3c]Do not use toArray method without arguments.
rule.pmd.UnsupportedExceptionWithModifyAsListRule.name=[p3c]Do not use methods which will modify the list after using Arrays.asList to convert array to list.
rule.pmd.ClassCastExceptionWithSubListToArrayListRule.name=[p3c]Do not cast subList in class ArrayList, otherwise ClassCastException will be thrown.
rule.pmd.ConcurrentExceptionWithModifyOriginSubListRule.name=[p3c]When using subList, be careful to modify the size of original list.
rule.pmd.DontModifyInForeachCircleRule.name=[p3c]Do not remove or add elements to a collection in a foreach loop.
rule.pmd.CollectionInitShouldAssignCapacityRule.name=[p3c]HashMap should set a size when initializing.

```

#### rules.xml

创建新的rules文件

将 sonar-pmd-p3c-chinese 项目的rules-p3c.xml 文件复制到项目 sonar-pmd 中

<!-- p3c-pmd的描述信息在 `p3c/p3c-pmd/src/main/resources/messages.xml` -->
rules-p3c.xml (src/main/resources/org/sonar/plugins/pmd/rules-p3c.xml)

#### pmd-model.xml

将 sonar-pmd-p3c-chinese 项目的 pmd-model.xml 中 P3C-PMD (约3927行左右)节点的内容追加到sonar-pmd的 pmd-model.xml文件(主要节点层级关系)

#### 提示文件

将 sonar-pmd-p3c-chinese 项目的 pmd-p3c 目录，复制到 sonar-pmd 项目中

(src/main/resources/org/sonar/l10n/pmd/rules/pmd-p3c)

#### 添加调用路径

在 java代码(约66 行)中添加规则路径

PmdRulesDefinition.java (src/main/java/org/sonar/plugins/pmd/rule/PmdRulesDefinition.java)

```java

    @Override
    public void define(Context context) {
        NewRepository repository = context
                .createRepository(PmdConstants.REPOSITORY_KEY, PmdConstants.LANGUAGE_KEY)
                .setName(PmdConstants.REPOSITORY_NAME);

        extractRulesData(repository, "/org/sonar/plugins/pmd/rules.xml", "/org/sonar/l10n/pmd/rules/pmd");
        // pmd-p3c
        extractRulesData(repository, "/org/sonar/plugins/pmd/rules-p3c.xml", "/org/sonar/l10n/pmd/rules/pmd-p3c");

        repository.done();
    }

```

## 编译

```bash
./mvnw clean verify
```

这个命令会执行集成测试,会下载sonar启动测试，由于网络问题，一直没有成功

打包

```bash
mvn clean install -Dmaven.test.skip=true
```

将生成的 sonar-pmd-plugin-3.4.0.jar 包丢到sonarQube的插件目录 extensions/plugins 即可(注意权限)，然后重新启动服务

## 使用

Quality Proifles(质量配置) -- Create (创建) -- 添加名称,语言选择 java  -- 完成

Quality Proifles() 选择新创建的规则  -- 点击Active More(更多激活规则)

左侧filter搜 索p3c,并选择 Bulk Change(批量修改)，将p3c规则加入刚创建的profile中
