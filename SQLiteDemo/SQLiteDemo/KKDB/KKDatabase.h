//
//  KKDatabase.h
//  SQLiteDemo
//
//  Created by Sands on 2023/4/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 执行多条SQL语句时的结果回调
typedef int(^KKDBExecuteStatementsCallbackBlock)(NSDictionary *resultsDictionary);

/// 事务类型枚举
typedef NS_ENUM(NSUInteger, KKDBTransactionType) {
    KKDBTransactionTypeDefault = 0,
    KKDBTransactionTypeDeferred,
    KKDBTransactionTypeImmediate,
    KKDBTransactionTypeExclusive
};

@class KKResultSet;

/// SQL数据库类
@interface KKDatabase : NSObject

/// 数据库文件路径
@property (nonatomic, readonly, copy) NSString *databasePath;
/// 数据库是否已经打开
@property (nonatomic, readonly, assign) BOOL isOpen;
/// 数据库连接状态
@property (nonatomic, readonly, assign) BOOL goodConnection;
/// 是否应该缓存SQL语句
@property (nonatomic, assign) BOOL shouldCacheStatements;
/// 缓存SQL语句的容器 NSMutableDictionary<NSString, NSMutableSet<KKStatement *> *> *
@property (atomic, strong, nullable) NSMutableDictionary *cachedStatements;
/// 是否存在未关闭的执行结果
@property (nonatomic, readonly, assign) BOOL hasOpenResultSets;
/// 是否处于事务开启中
@property (nonatomic, readonly, assign) BOOL isInTransaction;

/// 数据库对象构造方法
/// - Parameter aPath: SQLite数据库文件路径
+ (instancetype)databaseWithPath:(NSString *)aPath;
/// 打开数据库
- (BOOL)open;
/// 关闭数据库
- (BOOL)close;

#pragma mark - 更新数据 DML

/// 执行更新数据SQL, 例如: CREATE, INSERT, DELETE, UPDATE
/// - Parameter sql: sql语句字符串
- (BOOL)executeUpdate:(NSString *)sql, ...;
- (BOOL)executeUpdate:(NSString *)sql withErrorAndBindings:(NSError * _Nullable *)outError, ...;
- (BOOL)executeUpdateWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;
- (BOOL)executeUpdate:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments;
- (BOOL)executeUpdate:(NSString *)sql values:(NSArray * _Nullable)values error:(NSError * _Nullable *)error;

#pragma mark - 查询数据 DQL

/// 执行查询数据SQL, 主要是 SELECT
/// - Parameter sql: sql语句字符串
- (KKResultSet * _Nullable)executeQuery:(NSString *)sql, ...;
- (KKResultSet * _Nullable)executeQueryWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (KKResultSet * _Nullable)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;
- (KKResultSet * _Nullable)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments;
- (KKResultSet * _Nullable)executeQuery:(NSString *)sql values:(NSArray * _Nullable)values error:(NSError * _Nullable *)error;

#pragma mark - 批量执行SQL
- (BOOL)executeStatements:(NSString *)sql;
- (BOOL)executeStatements:(NSString *)sql withResultBlock:(__attribute__((noescape)) KKDBExecuteStatementsCallbackBlock _Nullable)block;

#pragma mark - 事务

/// 开启事务, 默认开启的是 Exclusive 类型的事务
- (BOOL)beginTransaction;
- (BOOL)beginTransactionWithType:(KKDBTransactionType)type;
/// 提交事务
- (BOOL)commit;
/// 回滚事务
- (BOOL)rollback;

#pragma mark - Other

/// 执行结果关闭
/// - Parameter resultSet: 结果对象
- (void)resultSetDidClose:(KKResultSet *)resultSet;

- (BOOL)hasDateFormatter;
/// 设置日期格式化器(仅用于数据库内部日期数据处理)
/// - Parameter formatter: 日期格式化器对象
- (void)setDateFormatter:(NSDateFormatter * _Nullable)formatter;
- (NSDate * _Nullable)dateFromString:(NSString *)s;
- (NSString * _Nullable)stringFromDate:(NSDate *)date;

- (int)lastErrorCode;
- (NSString *)lastErrorMessage;
- (NSError *)lastError;

@end

NS_ASSUME_NONNULL_END
