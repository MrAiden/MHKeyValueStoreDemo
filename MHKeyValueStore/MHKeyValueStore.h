//
//  MHKeyValueStore.h
//  MHKeyValueStore
//
//  Created by Mortar on 2018/11/23.
//  Copyright © 2018 Yan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MHShowDebugLog 1

NS_ASSUME_NONNULL_BEGIN

@interface MHKeyValueItem : NSObject

@property (nonatomic, copy) NSString *itemKey;      ///< key
@property (nonatomic, strong) id itemObject;        ///< value
@property (nonatomic, strong) NSDate *createdTime;  ///< time

@end

@interface MHKeyValueStore : NSObject

// 初始化数据库
- (instancetype)initDBWithName:(NSString *)dbName;
- (instancetype)initWithDBWithPath:(NSString *)dbPath;
// 创建表
- (void)createTableWithName:(NSString *)tableName;

// 是否存在
- (BOOL)isTableExists:(NSString *)tableName;
// 清空表
- (void)clearTable:(NSString *)tableName;
// 删除表
- (void)dropTable:(NSString *)tableName;
// 关闭
- (void)close;

/** set&get methods */

- (void)setObject:(id)object forKey:(NSString *)key intoTable:(NSString *)tableName;
- (id)objectForKey:(NSString *)key fromTable:(NSString *)tableName;
- (nullable MHKeyValueItem *)itemForKey:(NSString *)key fromTable:(NSString *)tableName;

- (void)setString:(NSString *)string forKey:(NSString *)key intoTable:(NSString *)tableName;
- (nullable NSString *)stringForKey:(NSString *)key fromTable:(NSString *)tableName;

- (void)setNumber:(NSNumber *)number forKey:(NSString *)key intoTable:(NSString *)tableName;
- (nullable NSNumber *)numberForKey:(NSString *)key fromTable:(NSString *)tableName;

- (nullable NSArray<MHKeyValueItem *> *)getAllItemsFromTable:(NSString *)tableName;

- (NSUInteger)getCountFromTable:(NSString *)tableName;

- (void)deleteObjectForKey:(NSString *)key fromTable:(NSString *)tableName;
- (void)deleteObjectsForKeys:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName;
- (void)deleteObjectsForKeyPrefix:(NSString *)keyPrefix fromTable:(NSString *)tableName;

@end

NS_ASSUME_NONNULL_END
