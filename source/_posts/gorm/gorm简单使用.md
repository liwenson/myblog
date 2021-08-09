---
title: gorm  简单使用
date: 2021-07-21 14:32
categories:
- go
tags:
- gorm
- go
---
	
	
摘要: gorm  简单使用
<!-- more -->



## 创建例子
```
package main

import (
	"fmt"
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/sqlite"
)

// UserInfo 用户信息
type UserInfo struct {
	ID uint
	Name string
	Gender string
	Hobby string
}


func main() {
	db, err := gorm.Open("sqlite3", "/db/gorm.db")
	if err != nil {
		fmt.Println("%v\n", err)
		panic(err)
	}
	defer db.Close()

	// 自动迁移
	db.AutoMigrate(&UserInfo{})

}

```

## 简单 CURD 

```

// UserInfo 用户信息
type UserInfo struct {
	ID     uint
	Name   string
	Age    int
	Gender string
	Hobby  string
}

func main() {
	db, err := gorm.Open("sqlite3", "db/gorm.db")
	if err != nil {
		fmt.Println("%v\n", err)
		panic(err)
	}
	defer db.Close()
	// 自动迁移
	db.AutoMigrate(&UserInfo{})


	// ######### 添加数据

	// 定义对象
	u1 := UserInfo{1, "七米", 18,"男", "篮球"}
	u2 := UserInfo{2, "沙河娜扎", 23,"女", "足球"}

	// 创建记录
	db.Create(&u1)
	db.Create(&u2)


	// ##########  查询
	var u = new(UserInfo)
	db.First(u)
	fmt.Printf("查询一条： %#v\n", u)

	//查询最后一行
	var u3 UserInfo
	db.Last(&u3)
	fmt.Printf("查询最后一条：%#v\n", u3)

	// 条件查询
	var uu UserInfo
	db.Find(&uu, "hobby=?", "足球")
	fmt.Printf("条件查询：%#v\n", uu)



	// 查看  age大于12 的数据
	u4 := []UserInfo{}
	db.Where("age>12").Find(&u4)
	fmt.Printf("查询age大于12的数据：%#v\n", u4)

	// 查询age大于20的数据
	var n = 20
	u5 := []UserInfo{}
	db.Where("age>?", n).Find(&u5) // 动态的数据使用占位符
	fmt.Printf("传参查询age大于20的数据：%#v\n", u5)

	var n1 = 10
	var n2 = 20
	u6 := []UserInfo{}
	db.Where("age > ? AND age < ?", n1, n2).Find(&u6)
	fmt.Printf("查询age 范围在10,20的数据：%#v\n", u6)

	// 查询age等于3 5 6的数据
	u7 := []UserInfo{}
	db.Where("age in (?)", []int{18, 23, 6}).Find(&u7)
	fmt.Printf("传参查询age等于的数据：%#v\n", u7)

	// 查询 名称包含 '米' 的数据
	u8 := []UserInfo{}
	db.Where("name like ?", "%米%").Find(&u8)
	fmt.Printf("查询名字包含米的名称：%#v\n", u8)

	// 查询id在什么之间
	u9 := []UserInfo{}
	db.Where("age between ? and ?", 3, 25).Find(&u9)
	fmt.Printf("查询ID 的数据：%#v\n", u9)


	// Or 条件
	u10 := []UserInfo{}
	db.Where("age=? OR age=?", 28, 23).Find(&u10)
	fmt.Printf("age 为28 或者23 的数据：%#v\n", u10)
	// 另一种写法
	u11 := []UserInfo{}
	db.Where("age=?", 18).Or("age=?", 23).Or("id=4").Find(&u11)
	fmt.Printf("age 为28 或者23 的数据：%#v\n", u11)

	// 选择字段查询
	u12 := []UserInfo{}
	db.Select("id, name, age").Find(&u12)
	fmt.Printf("选择字段查询：%#v\n", u12)

	/*
	   SubQuery 子查询
	   models.DB.Table("user").Select("avg(age)").SubQuery()
	*/
	u13 := []UserInfo{}
	// 先查出平均年龄 models.DB.Table("user").Select("avg(age)").SubQuery()
	// 在当做参数传给问号
	// 在Find一下
	db.Where("age<?",db.Table("user_infos").Select("avg(age)").SubQuery()).Find(&u13)
	fmt.Printf("子查询：%#v\n", u13)


	//排序
	u14 := []UserInfo{}
	// id Asc 按照id进行升序排序
	db.Where("id>1").Order("id Asc").Find(&u14)
	fmt.Printf("升序：%#v\n", u14)

	// desc 降序
	u15 := []UserInfo{}
	db.Where("id>0").Order("hobby Desc").Order("id Asc").Find(&u15)
	fmt.Printf("降序：%#v\n", u15)

	// 只要前面两条
	u16 := []UserInfo{}
	db.Where("id>1").Limit(2).Find(&u16)
	fmt.Printf("查询前面两条：%#v\n", u16)

	// 跳过2条查询2条
	u17 := []UserInfo{}
	db.Where("id>1").Offset(2).Limit(2).Find(&u17)
	fmt.Printf("跳过2条查询2条：%#v\n", u17)

	// 查询总数
	var total int
	var ut = []UserInfo{}
	db.Find(&ut).Count(&total)
	fmt.Printf("总数,%#v\n", total)

	// ################  更新
	//u1 := UserInfo{1, "七米", 18,"男", "篮球"}
	db.Model(&u).Update("hobby", "双色球")
	fmt.Printf("查询一条： %#v\n", u)

	// ###############  删除
	db.Delete(&u)

}


```

## 多对多 操作
```


//文章表
type Article struct {
	Id         int      `json:"id"`
	Title      string   `json:"title"`
	CategoryId int      `json:"category_id"`
	Category   Category `json:"category";gorm:"foreignkey:CategoryID"` //指定关联外键
	Tag        []*Tag   `gorm:"many2many:article_tag" json:"tag"`      //多对多关系.
	//article_tag表默认article_id字段对应article表id.tag_id字段对应tag表id
	//可以把对应sql日志打印出来,便于调试
}

//标签表
type Tag struct {
	Id      int    `json:"id" `
	TagName string `json:"tag_name"`
	Articles []*Article  `gorm:"many2many:article_tag" json:"article"`      //多对多关系.
}

//分类表
type Category struct {
	ID           int       `json:"id"`
	CategoryName string    `json:"category_name"`
	Status       int       `json:"status"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func main() {
	db, err := gorm.Open("sqlite3", "db/gorm.db")
	if err != nil {
		fmt.Println("%v\n", err)
		panic(err)
	}
	db.LogMode(true)
	defer db.Close()
	// 自动迁移
	//db.AutoMigrate(&Article{},&ArticleTag{},&Tag{},&Category{})
	//db.AutoMigrate(&Article{},&Tag{},&Category{})

	//// 手动添加tag
	//newTag := Tag{
	//	TagName: "科学",
	//}
	//db.Create(&newTag)
	//

	//// 添加 Category 类型
	//newCategory := Category{
	//	CategoryName: "Test",
	//	Status: 1,
	//}
	//db.Create(&newCategory)
	//fmt.Println(newCategory)


	//// ############ 增加

	////  01  插入  会重复创建标签并关联
	//newArticle := Article{Title: fmt.Sprintf("china-01-%s", RandomString(8)) , Tag: []*Tag{&Tag{TagName: "中文"}}}
	//db.Create(&newArticle)
	//fmt.Println(newArticle)

	// 02 开始已有标签-不必重复添加标签
	// 后来文章选择已有标签ID进行关联-还是会更新关联
	//taglist := []*Tag{}
	////db.Where("id = 1 ").Find(&taglist)
	//db.Where("id IN (?)", []int{1,2}).Find(&taglist)
	//newArticle2 := Article{Title: fmt.Sprintf("计算机基础02-%s", RandomString(8)) }
	//newArticle2.Tag= taglist
	//db.Create(&newArticle2)
	//fmt.Println(newArticle2)

	// 03  正确使用添加后关联-这个不会更新关联
	//newArticle02 := Article{Title: fmt.Sprintf("china-04-%s", RandomString(8))}
	//db.Create(&newArticle02)
	//taglist02 := []*Tag{}
	////db.First(&taglist02, 1) ## 关联一个
	//db.Where("id IN (?)", []int{1,2}).Find(&taglist02)  ## 关联多个
	//db.Model(&newArticle02).Association("Tag").Append(taglist02)
	//fmt.Println(newArticle02)


	// 04 使用标签关联文章
	//newTag := Tag{
	//	TagName: "数学",
	//}
	//db.Create(&newTag)
	//
	//tag01 := Tag{}
	//db.First(&tag01, newTag.Id)
	//a := Article{}
	//db.First(&a, 2)
	//db.Model(&tag01).Association("Articles").Append(a)

	/// #### 查询
	//a := Article{}
	//db.First(&a, 2)
	// 01 通过 Related 使用 many to many 关联
	//db.Model(&a).Related(&a.Tag, "Tag")

	// 02 查找匹配的关联
	//db.Debug().Model(&a).Association("Tag").Find(&a.Tag)

	// 03 预加载分两条查询语句
	//a := Article{}
	//db.Debug().Preload("Tag").Find(&a, "id = ?", 2)
	//
	//fmt.Print(a.Title + " : [")
	//for _, tag := range a.Tag {
	//	fmt.Print( tag.TagName + " ")
	//}
	//fmt.Print("]")


	// 04 使用标签查询关联的文章
	//t := Tag{}
	//db.First(&t, 1)
	//db.Model(&t).Related(&t.Articles, "Articles")
	//fmt.Print(t.TagName + " : ")
	//for _, a := range t.Articles {
	// fmt.Print(a.Title + "  ")
	//}




}


```
