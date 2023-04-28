//
//  KKSqlite.h
//  SQLiteDemo
//
//  Created by Sands on 2023/4/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKSqlite : NSObject

/// 日期格式化
@property (nonatomic, readonly, strong) NSDateFormatter *dateFormatter;

/// 错误信息
@property (nonatomic, readonly, strong) NSError *lastError;

+ (instancetype)instanceWithFilePath:(NSString *)filePath;

/// 创建表
/// - 根据指定列描述创建数据表, 调用示例:
///   ```
///   BOOL success = [self.kkdb createTable:@"t_kksqlite" columns:@[
///                 @{@"id": @"integer primary key autoincrement"},
///                 @{@"key": @"text"},
///                 @{@"value": @"integer"}]];
///   ```
/// - Parameters:
///   - tablename: 表名
///   - columns: 列字段数组字典, 数组中每个字典的key: 列名, value: 类型及约束描述, 例如:  @[@{@"id": @"integer primary key autoincrement"}, @{@"name": @"text"}, @{@"age": @"integer"}]
/// - Returns: YES 成功, 否则 NO
///
- (BOOL)createTable:(NSString *)tablename columns:(NSArray<NSDictionary<NSString *, NSString *> *> *)columns;

/// 删除表
/// - Parameter tablename: 表名
/// - Returns: YES 成功, 否则 NO
///
- (BOOL)dropTable:(NSString *)tablename;

/// 插入数据
/// - 根据指定列插入数据, 调用示例:
///   ```
///   BOOL success = [self.kkdb insertIntoTable:@"t_kksqlite" columns:nil values:@[
///                     @[@1, @"key1", @"value1"],
///                     @[@2, @"key2", @"value2"],
///                     @[@3, @"key3", @"value3"]]
///                  ];
///   BOOL success = [self.kkdb insertIntoTable:@"t_kksqlite" columns:@[@"key", @"value"] values:@[
///                     @[@"key4", @"value4"],
///                     @[@"key5", @"value5"],
///                     @[@"key6", @(6)]]
///                  ];
///   ```
/// - Parameters:
///   - tablename: 表名
///   - columns: 列名, 没有使用默认值的列时可以不传, 那么数据就要覆盖所有列, 例如: @[@"name", @"age"]
///   - values: 值, 二维数组, 支持同时插入多条数据, 例如: @[@[@"sands", @(18)], @[@"asahi", @(29)], @[@"alice", @(16)]]
/// - Returns: YES 成功, 否则 NO
///
- (BOOL)insertIntoTable:(NSString *)tablename
                columns:(NSArray <NSString *> * _Nullable)columns
                 values:(NSArray<NSArray *> *)values;

/// 插入或更新数据（用于数据表中存在唯一索引时, 插入重复数据的处理）
/// - 根据指定列插入数据, 对于存在唯一索引, 插入重复数据时将自动更新为新插入的数据, 调用示例:
///   ```
///   BOOL success = [self.kkdb insertOrReplaceIntoTable:@"t_kksqlite" columns:nil values:@[
///                     @[@1, @"key1", @"value1"],
///                     @[@2, @"key2", @"value2"],
///                     @[@3, @"key3", @"value3"]]
///                  ];
///   BOOL success = [self.kkdb insertOrReplaceIntoTable:@"t_kksqlite" columns:@[@"key", @"value"] values:@[
///                     @[@"key4", @"value4"],
///                     @[@"key5", @"value5"],
///                     @[@"key6", @(6)]]
///                  ];
///   ```
/// - Parameters:
///   - tablename: 表名
///   - columns: 列名, 没有使用默认值的列时可以不传, 那么数据就要覆盖所有列, 例如: @[@"name", @"age"]
///   - values: 值, 二维数组, 支持同时插入多条数据, 例如: @[@[@"sands", @(18)], @[@"asahi", @(29)], @[@"alice", @(16)]]
/// - Returns: YES 成功, 否则 NO
///
- (BOOL)insertOrReplaceIntoTable:(NSString *)tablename
                         columns:(NSArray <NSString *> * _Nullable)columns
                          values:(NSArray<NSArray *> *)values;

/// 插入或忽略数据（用于数据表中存在唯一索引时, 插入重复数据的处理）
/// - 根据指定列插入数据, 对于存在唯一索引, 插入重复数据时将被忽略, 调用示例:
///   ```
///   BOOL success = [self.kkdb insertOrIgnoreIntoTable:@"t_kksqlite" columns:nil values:@[
///                     @[@1, @"key1", @"value1"],
///                     @[@2, @"key2", @"value2"],
///                     @[@3, @"key3", @"value3"]]
///                  ];
///   BOOL success = [self.kkdb insertOrIgnoreIntoTable:@"t_kksqlite" columns:@[@"key", @"value"] values:@[
///                     @[@"key4", @"value4"],
///                     @[@"key5", @"value5"],
///                     @[@"key6", @(6)]]
///                  ];
///   ```
/// - Parameters:
///   - tablename: 表名
///   - columns: 列名, 没有使用默认值的列时可以不传, 那么数据就要覆盖所有列, 例如: @[@"name", @"age"]
///   - values: 值, 二维数组, 支持同时插入多条数据, 例如: @[@[@"sands", @(18)], @[@"asahi", @(29)], @[@"alice", @(16)]]
/// - Returns: YES 成功, 否则 NO
///
- (BOOL)insertOrIgnoreIntoTable:(NSString *)tablename
                        columns:(NSArray <NSString *> * _Nullable)columns
                         values:(NSArray<NSArray *> *)values;

/// 删除数据
/// - 根据列名删除指定范围的数据, 等价于 DELETE FROM tablename WHERE column in (value1, value2, ...), 调用示例:
///   ```
///   [instance deleteFromTable:@"t_kksqlite" withColumn:@"id" inArray:@[@10, @11, @12]]
///   ```
/// - Parameters:
///   - tablename: 表名
///   - column: 列名, 根据哪一列的条件进行删除
///   - values: 值域
/// - Returns: YES 成功, 否则 NO
///
- (BOOL)deleteFromTable:(NSString *)tablename withColumn:(NSString *)column inArray:(NSArray *)values;

/// 删除数据
/// - 根据条件删除指定范围的数据, 等价于 DELETE FROM tablename WHERE conditions, 调用示例:
///   ```
///   [instance deleteFromTable:@"t_kksqlite" conditions:@[@"key is null", @"value like 'value%'"]]
///   ```
/// - Parameters:
///   - tablename: 表名
///   - conditions: 条件, 多个条件默认以 AND 连接
/// - Returns: YES 成功, 否则 NO
///
- (BOOL)deleteFromTable:(NSString *)tablename conditions:(NSArray<NSString *> *)conditions;

/// 更新数据
/// - 根据条件更新指定范围的数据, 等价于 UPDATE tablename SET key = value WHERE conditions, 调用示例:
///   ```
///   // 更新指定范围
///   [instance updateToTable:@"t_kksqlite" changes:@{@"value": @9} conditions:@[@"id = 6"]];
///   // 更新全部
///   [instance updateToTable:@"t_kksqlite" changes:@{@"value": [NSDate date]} conditions:nil];
///   ```
/// - Parameters:
///   - tablename: 表名
///   - changes: 更新内容, key为要更新的列名, value为更新的值
///   - conditions: 条件, 多个条件默认以 AND 连接
/// - Returns: YES 成功, 否则 NO
///
- (BOOL)updateToTable:(NSString *)tablename
              changes:(NSDictionary<NSString *, id> *)changes
           conditions:(NSArray<NSString *> * _Nullable)conditions;



/// 查询数据
/// - Parameters:
///   - tablename: 表名
///   - columns: 查询的列名, 传 nil 表示查询所有列, 相当于 SELECT * FROM tablename ...
/// - Returns: 查询结果列表, 列表中的元素是查询到的每一行结果字典, 为空时表示未查询到数据
///
- (NSArray<NSDictionary *> * _Nullable)selectFromTable:(NSString *)tablename
                                               columns:(NSArray <NSString *> * _Nullable)columns;

/// 查询数据
/// - 根据条件、分组、排序、分页等各种方式查询指定范围的数据
/// - Parameters:
///   - tablename: 表名
///   - columns: 查询的列名, 传 nil 表示查询所有列, 相当于 SELECT * FROM tablename ...
///   - conditions: 条件, 多个条件默认以 AND 连接
/// - Returns: 查询结果列表, 列表中的元素是查询到的每一行结果字典, 为空时表示未查询到数据
///
- (NSArray<NSDictionary *> * _Nullable)selectFromTable:(NSString *)tablename
                                               columns:(NSArray <NSString *> * _Nullable)columns
                                            conditions:(NSArray<NSString *> * _Nullable)conditions;

/// 查询数据
/// - 根据条件、分组、排序、分页等各种方式查询指定范围的数据
/// - Parameters:
///   - tablename: 表名
///   - columns: 查询的列名, 传 nil 表示查询所有列, 相当于 SELECT * FROM tablename ...
///   - conditions: 条件, 多个条件默认以 AND 连接
///   - groups: 分组字段
///   - orders: 排序方式, key为排序字段名, value为排序方式描述, 例如: @{@"age": @"asc", @"salary": @"desc"}
///   - start: 分页起始值, 计算方式: (目标页数 - 1) * size, 不需要分页时传0
///   - size: 分页的每页条数, 不需要分页时传0, 相当于 SELECT * FROM tablename LIMIT start, size
/// - Returns: 查询结果列表, 列表中的元素是查询到的每一行结果字典, 为空时表示未查询到数据
///
- (NSArray<NSDictionary *> * _Nullable)selectFromTable:(NSString *)tablename
                                               columns:(NSArray <NSString *> * _Nullable)columns
                                            conditions:(NSArray<NSString *> * _Nullable)conditions
                                                groups:(NSArray<NSString *> * _Nullable)groups
                                                orders:(NSDictionary<NSString *, NSString *> * _Nullable)orders
                                             pageStart:(int)start
                                              pageSize:(int)size;


/// 设置日期格式化形式
/// - Parameter fmtString: 日期格式化字符串, 为空表示不需要进行格式化
- (void)setDateFormatterWithString:(NSString *_Nullable)fmtString;

@end

NS_ASSUME_NONNULL_END
