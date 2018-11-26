//
//  MHKeyValueStore.m
//  MHKeyValueStore
//
//  Created by Mortar on 2018/11/23.
//  Copyright © 2018 Yan. All rights reserved.
//

#import "MHKeyValueStore.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>

#ifdef DEBUG
#if MHShowDebugLog
#define MHDebugLog(...)    NSLog(__VA_ARGS__)
#else
#define MHDebugLog(...)
#endif
#else
#define MHDebugLog(...)
#endif

@implementation MHKeyValueItem

- (NSString *)description {
    return [NSString stringWithFormat:@"key=%@, value=%@, timeStamp=%@", _itemKey, _itemObject, _createdTime];
}

@end

@interface MHKeyValueStore ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, copy) NSString *documentPath;    ///< Document 文件夹路径

@end

// 默认数据库名
static NSString * const kMHDefaultDBNameKey = @"kMHDefaultDatabase.sqlite";

// 创建
static NSString * const kMHCreateTableSQL = @"CREATE TABLE IF NOT EXISTS '%@' (key TEXT NOT NULL, json TEXT NOT NULL, createdTime TEXT NOT NULL, PRIMARY KEY(key))";

// 更新
static NSString * const kMHUpdateItemSQL = @"REPLACE INTO '%@' (key, json, createdTime) values (?, ?, ?)";

// 查询
static NSString * const kMHQueryItemSQL = @"SELECT json, createdTime from '%@' where key = ? Limit 1";

// 查询所有
static NSString * const kMHQueryAllSQL = @"SELECT * from '%@'";

// 个数
static NSString * const kMHCountAllSQL = @"SELECT count(*) as num from '%@'";

// 删除所有
static NSString * const kMHDeleteAllSQL = @"DELETE from '%@'";

// 删除一个
static NSString * const kMHDeleteItemSQL = @"DELETE from '%@' where key = ?";

// 删除多个
static NSString * const kMHDeleteItemsSQL = @"DELETE from '%@' where key in ( %@ )";

// 删除前缀
static NSString * const kMHDeleteItemsWithPrefixSQL = @"DELETE from '%@' where key like ? ";

// 清除表
static NSString * const kMHDropTableSQL = @"DROP TABLE '%@'";

@implementation MHKeyValueStore

#pragma mark -
#pragma mark - Initialize

- (instancetype)init {
    if (self = [super init]) {
        NSString *dbPath = [self.documentPath stringByAppendingPathComponent:kMHDefaultDBNameKey];
        [self createDatabaseQueueWithPath:dbPath];
    }
    return self;
}

- (instancetype)initDBWithName:(NSString *)dbName {
    if (self = [super init]) {
        NSString *dbPath = [self.documentPath stringByAppendingPathComponent:dbName];
        [self createDatabaseQueueWithPath:dbPath];
    }
    return self;
}

- (instancetype)initWithDBWithPath:(NSString *)dbPath {
    if (self = [super init]) {
        [self createDatabaseQueueWithPath:dbPath];
    }
    return self;
}

- (void)createDatabaseQueueWithPath:(NSString *)dbPath {
    MHDebugLog(@"dbPath = %@", dbPath);
    if (_dbQueue) {
        [self close];
    }
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
}

- (void)createTableWithName:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return;
    }
    NSString *createSQL = [NSString stringWithFormat:kMHCreateTableSQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdate:createSQL];
    }];
    if (!result) {
        MHDebugLog(@"ERROR, failed to create table: '%@'", tableName);
    }
}

- (BOOL)isTableExists:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return NO;
    }
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db tableExists:tableName];
    }];
    return result;
}

- (void)clearTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return;
    }
    NSString *clearSQL = [NSString stringWithFormat:kMHDeleteAllSQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:clearSQL];
    }];
    if (!result) {
        MHDebugLog(@"ERROR, failed to clear table: '%@'", tableName);
    }
}

- (void)dropTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return;
    }
    NSString *dropSQL = [NSString stringWithFormat:kMHDropTableSQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:dropSQL];
    }];
    if (!result) {
        MHDebugLog(@"ERROR, failed to drop table: '%@'", tableName);
    }
}

- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}

#pragma mark -
#pragma mark - Operate

- (void)setObject:(id)object forKey:(NSString *)key intoTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return;
    }
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (error) {
        MHDebugLog(@"ERROR, faild to get json data");
        return;
    }
    NSString * jsonString = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
    NSDate *createdTime = [NSDate date];
    NSString *updateSQL = [NSString stringWithFormat:kMHUpdateItemSQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:updateSQL, key, jsonString, createdTime];
    }];
    if (!result) {
        MHDebugLog(@"ERROR, failed to insert/replace into table: %@", tableName);
    }
}

- (id)objectForKey:(NSString *)key fromTable:(NSString *)tableName {
    MHKeyValueItem *item = [self itemForKey:key fromTable:tableName];
    if (item) {
        return item.itemObject;
    } else {
        return nil;
    }
}

- (MHKeyValueItem *)itemForKey:(NSString *)key fromTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return nil;
    }
    NSString *queryItemSQL = [NSString stringWithFormat:kMHQueryItemSQL, tableName];
    __block NSString *json = nil;
    __block NSDate *createdTime = nil;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:queryItemSQL, key];
        if ([rs next]) {
            json = [rs stringForColumn:@"json"];
            createdTime = [rs dateForColumn:@"createdTime"];
        }
        [rs close];
    }];
    if (json) {
        NSError *error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingAllowFragments) error:&error];
        if (error) {
            MHDebugLog(@"ERROR, faild to prase to json");
            return nil;
        }
        MHKeyValueItem *item = [[MHKeyValueItem alloc] init];
        item.itemKey = key;
        item.itemObject = result;
        item.createdTime = createdTime;
        return item;
    } else {
        return nil;
    }
}

- (void)setString:(NSString *)string forKey:(NSString *)key intoTable:(NSString *)tableName {
    if (string == nil) {
        MHDebugLog(@"error, string is nil");
        return;
    }
    [self setObject:@[string] forKey:key intoTable:tableName];
}

- (NSString *)stringForKey:(NSString *)key fromTable:(NSString *)tableName {
    NSArray *array = [self objectForKey:key fromTable:tableName];
    if (array && [array isKindOfClass:[NSArray class]]) {
        return array[0];
    }
    return nil;
}

- (void)setNumber:(NSNumber *)number forKey:(NSString *)key intoTable:(NSString *)tableName {
    if (number == nil) {
        MHDebugLog(@"error, number is nil");
        return;
    }
    [self setObject:@[number] forKey:key intoTable:tableName];
}

- (NSNumber *)numberForKey:(NSString *)key fromTable:(NSString *)tableName {
    NSArray * array = [self objectForKey:key fromTable:tableName];
    if (array && [array isKindOfClass:[NSArray class]]) {
        return array[0];
    }
    return nil;
}

- (NSArray<MHKeyValueItem *> *)getAllItemsFromTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return nil;
    }
    NSString *queryAllSQL = [NSString stringWithFormat:kMHQueryAllSQL, tableName];
    __block NSMutableArray<MHKeyValueItem *> * result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:queryAllSQL];
        while ([rs next]) {
            MHKeyValueItem *item = [[MHKeyValueItem alloc] init];
            item.itemKey = [rs stringForColumn:@"key"];
            item.itemObject = [rs stringForColumn:@"json"];
            item.createdTime = [rs dateForColumn:@"createdTime"];
            [result addObject:item];
        }
        [rs close];
    }];
    NSError *error = nil;
    for (MHKeyValueItem *item in result) {
        error = nil;
        id object = [NSJSONSerialization JSONObjectWithData:[item.itemObject dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingAllowFragments) error:&error];
        if (error) {
            MHDebugLog(@"ERROR, faild to prase to json.");
        } else {
            item.itemObject = object;
        }
    }
    return result;
}

- (NSUInteger)getCountFromTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return 0;
    }
    NSString *countSQL = [NSString stringWithFormat:kMHCountAllSQL, tableName];
    __block NSInteger count = 0;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:countSQL];
        if ([rs next]) {
            count = [rs unsignedLongLongIntForColumn:@"num"];
        }
        [rs close];
    }];
    return count;
}

- (void)deleteObjectForKey:(NSString *)key fromTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return;
    }
    NSString *deleteItemSQL = [NSString stringWithFormat:kMHDeleteItemSQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:deleteItemSQL, key];
    }];
    if (!result) {
        MHDebugLog(@"ERROR, failed to delete item from table: '%@'", tableName);
    }
}

- (void)deleteObjectsForKeys:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return;
    }
    NSMutableString *stringBuilder = [NSMutableString string];
    for (id objectId in keys) {
        NSString *item = [NSString stringWithFormat:@" '%@' ", objectId];
        if (stringBuilder.length == 0) {
            [stringBuilder appendString:item];
        } else {
            [stringBuilder appendString:@","];
            [stringBuilder appendString:item];
        }
    }
    NSString *deleteItemsSQL = [NSString stringWithFormat:kMHDeleteItemsSQL, tableName, stringBuilder];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:deleteItemsSQL];
    }];
    if (!result) {
        MHDebugLog(@"ERROR, failed to delete items by keys from table: '%@'", tableName);
    }
}

- (void)deleteObjectsForKeyPrefix:(NSString *)keyPrefix fromTable:(NSString *)tableName {
    if (![MHKeyValueStore checkTableName:tableName]) {
        return;
    }
    NSString *deleteItemWithPrefixSQL = [NSString stringWithFormat:kMHDeleteItemsWithPrefixSQL, tableName];
    NSString *prefixArgument = [NSString stringWithFormat:@"%@%%", keyPrefix];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:deleteItemWithPrefixSQL, prefixArgument];
    }];
    if (!result) {
        MHDebugLog(@"ERROR, failed to delete items by key prefix from table: '%@'", tableName);
    }
}

#pragma mark -
#pragma mark - Tools

+ (BOOL)checkTableName:(NSString *)tableName {
    if (tableName == nil || tableName.length == 0) {
        MHDebugLog(@"ERROR, table name: '%@' format error.", tableName);
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark - lazy

- (NSString *)documentPath {
    NSArray<NSString *> *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentPath = array.firstObject;
    return _documentPath;
}

@end
