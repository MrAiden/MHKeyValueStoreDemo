# MHKeyValueStoreDemo
==========

![License MIT](https://go-shields.herokuapp.com/license-MIT-blue.png)
![Pod version](http://img.shields.io/cocoapods/v/MHKeyValueStore.svg?style=flat)
![Platform info](http://img.shields.io/cocoapods/p/MHKeyValueStore.svg?style=flat)

## 集成说明
你可以在 Podfile 中加入下面一行代码来使用MHKeyValueStore

    pod 'MHKeyValueStore'

## 使用说明

所有的接口都封装在`MHKeyValueStore`类中。以下是一些常用方法说明。

### 打开（或创建）数据库

```
// MHKeyValueStore *store = [[MHKeyValueStore alloc] initDBWithName:@"test.db"];
```
