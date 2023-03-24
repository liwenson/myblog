---
title: 深度学习训练识别url
date: 2023-03-24 14:51
categories:
- tensorflow
tags:
- ai
---
  
  
摘要: desc
<!-- more -->

## 代码

```txt
<https://blog.csdn.net/To_be_little/article/details/124438800>
```

```python
import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.models import Sequential
from tensorflow.keras.preprocessing import sequence
from tensorflow.keras.callbacks import TensorBoard
from tensorflow.keras.layers import LSTM, Dense, Dropout
from tensorflow.keras.layers import Embedding
import urllib


# 获取文本中的请求列表
# 分词
# 张量转换

# 获取文本中的请求列表
def get_query_list(filename):
    filepath = "./" + filename
    data = open(filepath, 'r', encoding='UTF-8').readlines()
    query_list = []
    for d in data:
        # 解码
        d = str(urllib.parse.unquote(d))   #converting url encoded data to simple string
        #print(d)
        query_list.append(d)
    return list(set(query_list))


# 获取恶意请求
bad_query_list = get_query_list('badqueries.txt')
print(u"恶意请求: ", len(bad_query_list))
for  i in range(0, 5):
    print(bad_query_list[i].strip('\n'))
print("\n")

# 获取正常请求
good_query_list = get_query_list('goodqueries.txt')
print(u"正常请求: ", len(good_query_list))
for  i in range(0, 5):
    print(good_query_list[i].strip('\n'))
print("\n")

queries = bad_query_list + good_query_list


print(queries[0])


# 预处理 
# good_y标记为0
# bad_y标记为1
good_y = [0 for i in range(0, len(good_query_list))]
print(good_y[:5])
bad_y = [1 for i in range(0, len(bad_query_list))]
print(bad_y[:5])

Y = bad_y + good_y



tokenizer = tf.keras.preprocessing.text.Tokenizer(
    num_words=None,
    filters='!"#$%&()*+,-./:;<=>?@[\\]^_`{|}~\t\n',
    lower=True,
    split=' ',
    char_level=False,
    oov_token=None,
    analyzer=None,

)

# tokenizer = Tokenizer(filters='/', char_level=True)

max_log_length = 1024
train_size = int(len(queries) * .75)

tokenizer.fit_on_texts(queries)

num_words = len(tokenizer.word_index)+1

queries = tokenizer.texts_to_sequences(queries)

queries_processed = sequence.pad_sequences(queries, maxlen=max_log_length)


X_train, X_test = queries_processed[0:train_size], queries_processed[train_size:len(queries_processed)]
Y_train, Y_test = Y[0:train_size], Y[train_size:len(Y)]

X_train = tf.convert_to_tensor(X_train, dtype=tf.float32)
Y_train = tf.convert_to_tensor(Y_train, dtype=tf.float32)
X_test = tf.convert_to_tensor(X_test, dtype=tf.float32)
Y_test = tf.convert_to_tensor(Y_test, dtype=tf.float32)

print(X_test)


tb_callback = TensorBoard(log_dir='./logs', embeddings_freq=1)

from tensorflow.keras.layers  import ELU, PReLU, LeakyReLU

model = Sequential()
model.add(Embedding(num_words, 32, input_length=max_log_length))
model.add(Dropout(0.5))
model.add(LSTM(64, recurrent_dropout=0.5))
model.add(Dropout(0.5))
model.add(Dense(1,activation='sigmoid'))
model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])

model.summary()

# 训练
history  = model.fit(X_train, Y_train, validation_split=0.25, epochs=3, batch_size=32, callbacks=[tb_callback])

# 评估模型
score, acc = model.evaluate(X_test, Y_test, verbose=1, batch_size=64)

print("Model Accuracy: {:0.2f}%".format(acc * 100))
```
