# MHKeyValueStoreDemo

![License MIT](https://go-shields.herokuapp.com/license-MIT-blue.png)
![Pod version](http://img.shields.io/cocoapods/v/MHKeyValueStore.svg?style=flat)
![Platform info](http://img.shields.io/cocoapods/p/MHKeyValueStore.svg?style=flat)

## 集成说明
你可以在 Podfile 中加入下面一行代码来使用MHKeyValueStore

    pod 'MHKeyValueStore'

## 使用说明

所有的接口都封装在`MHKeyValueStore`类中。以下是一些常用方法说明。

### 打开（或创建）数据库
通过`initDBWithName`方法，即可在程序的`Document`目录打开指定的数据库文件。如果该文件不存在，则会创建一个新的数据库。

```
MHKeyValueStore *store = [[MHKeyValueStore alloc] initDBWithName:@"testDatabase.sqlite"];
```

### 创建数据库表
通过`createTableWithName`方法，我们可以在打开的数据库中创建表，如果表名已经存在，则会忽略该操作。如下所示：
```
[store createTableWithName:@"testTable"];
```

### 读写数据
`MHKeyValueStore`类提供key-value的存储接口，存入的所有数据需要提供key以及其对应的value，读取的时候需要提供key来获得相应的value。
`MHKeyValueStore`类支持的value类型包括：NSString, NSNumber, NSDictionary和NSArray，为此提供了以下接口：
```
- (void)setString:(NSString *)string forKey:(NSString *)key intoTable:(NSString *)tableName;
- (void)setNumber:(NSNumber *)number forKey:(NSString *)key intoTable:(NSString *)tableName;
- (void)setObject:(id)object forKey:(NSString *)key intoTable:(NSString *)tableName;
```
与此对应，有以下value为NSString, NSNumber, NSDictionary和NSArray的读取接口：
```
- (nullable NSString *)stringForKey:(NSString *)key fromTable:(NSString *)tableName;
- (nullable NSNumber *)numberForKey:(NSString *)key fromTable:(NSString *)tableName;
- (id)objectForKey:(NSString *)key fromTable:(NSString *)tableName;
```

### 删除数据接口
`MHKeyValueStore`提供了以下接口用于删除数据。
```
// 清空表
- (void)clearTable:(NSString *)tableName;
// 删除表
- (void)dropTable:(NSString *)tableName;
// 删除一个
- (void)deleteObjectForKey:(NSString *)key fromTable:(NSString *)tableName;
// 删除多个
- (void)deleteObjectsForKeys:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName;
// 根据 key 前缀删除
- (void)deleteObjectsForKeyPrefix:(NSString *)keyPrefix fromTable:(NSString *)tableName;
```