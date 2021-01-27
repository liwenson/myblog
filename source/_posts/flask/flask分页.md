---
title: flask自定义分页
date: 2020-02-13 14:00:00
categories: 
- flask
tags:
- python
- flask
---



## flask 自定义fenye

page_utils.py

```python
#!usr/bin/env python
# -*- coding:utf-8 -*-
from urllib import urlencode
class Pagination(object):
    """
    自定义分页
    """
    def __init__(self, current_page, total_count, base_url, params, per_page_count=10, max_pager_count=11):
        try:
            current_page = int(current_page)
        except Exception as e:
            current_page = 1
        if current_page <=0:
            current_page = 1
        self.current_page = current_page
        # 数据总条数
        self.total_count = total_count
  
        # 每页显示10条数据
        self.per_page_count = per_page_count
  
        # 页面上应该显示的最大页码
        max_page_num, div = divmod(total_count, per_page_count)
        if div:
            max_page_num += 1
        self.max_page_num = max_page_num
  
        # 页面上默认显示11个页码（当前页在中间）
        self.max_pager_count = max_pager_count
        self.half_max_pager_count = int((max_pager_count - 1) / 2)
  
        # URL前缀
        self.base_url = base_url
  
        # request.GET
        import copy
        params = copy.deepcopy(params)
        get_dict = params.to_dict()
  
        self.params = get_dict
  
    @property
    def start(self):
        return (self.current_page - 1) * self.per_page_count
  
    @property
    def end(self):
        return self.current_page * self.per_page_count
  
    def page_html(self):
        # 如果总页数 <= 11
        if self.max_page_num <= self.max_pager_count:
            pager_start = 1
            pager_end = self.max_page_num
        # 如果总页数 > 11
        else:
            # 如果当前页 <= 5
            if self.current_page <= self.half_max_pager_count:
                pager_start = 1
                pager_end = self.max_pager_count
            else:
                # 当前页 + 5 > 总页码
                if (self.current_page + self.half_max_pager_count) > self.max_page_num:
                    pager_end = self.max_page_num
                    pager_start = self.max_page_num - self.max_pager_count + 1   #倒这数11个
                else:
                    pager_start = self.current_page - self.half_max_pager_count
                    pager_end = self.current_page + self.half_max_pager_count
  
        page_html_list = []
        # {source:[2,], status:[2], gender:[2],consultant:[1],page:[1]}
        # 首页
        self.params['page'] = 1
        first_page = '<li><a href="%s?%s">首页</a></li>'.decode("utf-8") % (self.base_url,urlencode(self.params),)
        page_html_list.append(first_page)
        # 上一页
        self.params["page"] = self.current_page - 1
        if self.params["page"] < 1:
            pervious_page = '<li class="disabled"><a href="%s?%s" aria-label="Previous">上一页</span></a></li>'.decode("utf-8") % (self.base_url, urlencode(self.params))
        else:
            pervious_page = '<li><a href = "%s?%s" aria-label = "Previous" >上一页</span></a></li>'.decode("utf-8") % ( self.base_url, urlencode(self.params))
        page_html_list.append(pervious_page)
        # 中间页码
        for i in range(pager_start, pager_end + 1):
            self.params['page'] = i
            if i == self.current_page:
                temp = '<li class="active"><a href="%s?%s">%s</a></li>' % (self.base_url,urlencode(self.params), i,)
            else:
                temp = '<li><a href="%s?%s">%s</a></li>' % (self.base_url,urlencode(self.params), i,)
            page_html_list.append(temp)
  
        # 下一页
        self.params["page"] = self.current_page + 1
        if self.params["page"] > self.max_page_num:
            self.params["page"] = self.current_page
            next_page = '<li class="disabled"><a href = "%s?%s" aria-label = "Next">下一页</span></a></li >'.decode("utf-8") % (self.base_url, urlencode(self.params))
        else:
            next_page = '<li><a href = "%s?%s" aria-label = "Next">下一页</span></a></li>'.decode("utf-8") % (self.base_url, urlencode(self.params))
        page_html_list.append(next_page)
  
        # 尾页
        self.params['page'] = self.max_page_num
        last_page = '<li><a href="%s?%s">尾页</a></li>'.decode("utf-8") % (self.base_url, urlencode(self.params),)
        page_html_list.append(last_page)
  
        return ''.join(page_html_list)

```



自定义方法中的参数：
current_page——表示当前页。
total_count——表示数据总条数。
base_url——表示分页URL前缀，请求的前缀获取可以通过Flask的request.path方法，无需自己指定。
例如：我们的路由方法为@app.route('/test')，request.path方法即可获取/test。
params——表示请求传入的数据，params可以通过request.args动态获取。
例如：我们链接点击为：http://localhost:5000/test?page=10，此时request.args获取数据为ImmutableMultiDict([('page', u'10')])
per_page_count——指定每页显示数。
max_pager_count——指定页面最大显示页码



## 测试类

test.py:

```python
#!usr/bin/env python
# -*- coding:utf-8 -*-
from flask import Flask, render_template, request
from page_utils import Pagination
app = Flask(__name__)
  
@app.route('/test')
def test():
    li = []
    for i in range(1, 100):
        li.append(i)
    pager_obj = Pagination(request.args.get("page", 1), len(li), request.path, request.args, per_page_count=10)
    print(request.path)
    print(request.args)
    index_list = li[pager_obj.start:pager_obj.end]
    html = pager_obj.page_html()
    return render_template("obj/test.html", index_list=index_list, html=html)
  
if __name__ == '__main__':
    app.run(debug=True)
```



在上面的程序中，li为我们要分页的对象，数组list，我们获取到这个list之后，把他用工具类中的起止方法包起来。
传递数据用包装后的list，这样就达到了需要哪一段数据我们传递哪一段的效果，包装的方法：index_list = li[pager_obj.start:pager_obj.end]

 

我们用一个HTML页面去显示它，分页样式不是重点，我们这里直接引入bootstrap封装好的分页效果，代码如下：

test.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/bootstrap.min.css') }}">
    <style>
        .container{
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="row " style="margin-top: 10px">
                <ul>
                    {% for foo in index_list %}
                        <li>{{ foo }}：这是列表内容~~</li>
                    {% endfor %}
                </ul>
                <nav aria-label="Page navigation" class="pull-right">
                    <ul class="pagination">
                        {{ html|safe }}
                    </ul>
                </nav>
        </div>
    </div>
</body>
</html>
```

