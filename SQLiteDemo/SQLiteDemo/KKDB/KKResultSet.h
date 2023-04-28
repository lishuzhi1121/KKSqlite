//
//  KKResultSet.h
//  SQLiteDemo
//
//  Created by Sands on 2023/4/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class KKStatement, KKDatabase;

/// SQL执行结果类
@interface KKResultSet : NSObject

/// 执行的SQL语句封装对象
@property (nonatomic, strong) KKStatement *statement;
/// 数据库对象
@property (nonatomic, strong) KKDatabase *parentDB;
/// SQL语句字符串
@property (nonatomic, copy) NSString *query;
/// SQL执行结果 key为column name
@property (nonatomic, readonly, strong, nullable) NSDictionary *resultDictionary;
/// 结果集中列的总数
@property (nonatomic, readonly, assign) int columnCount;
/// SQL执行结果 key为column name, value为column index
@property (nonatomic, readonly, strong) NSMutableDictionary *columnNameToIndexMap;

/// 结果集构造方法
/// - Parameters:
///   - statement: SQL语句封装对象
///   - aDB: 数据库对象
///   - shouldAutoClose: 是否自动关闭, YES 则表示执行next或者internalStep方法发生错误时将自动关闭结果集
+ (instancetype)resultSetWithStatement:(KKStatement *)statement
                   usingParentDatabase:(KKDatabase *)aDB
                       shouldAutoClose:(BOOL)shouldAutoClose;

/// 关闭结果集, 使用完成时务必调用
- (void)close;

/// 检索下一行数据, 访问数据之前务必执行
- (BOOL)next;
- (BOOL)nextWithError:(NSError * _Nullable *)outError;
- (int)internalStepWithError:(NSError * _Nullable *)outError;

#pragma mark - 获取结果集中的数据
/// 列
- (int)columnIndexForName:(NSString *)columnName;
- (NSString * _Nullable)columnNameForIndex:(int)columnIdx;

/// 数据值
- (int)intForColumn:(NSString *)columnName;
- (int)intForColumnIndex:(int)columnIdx;

- (long)longForColumn:(NSString *)columnName;
- (long)longForColumnIndex:(int)columnIdx;

- (long long int)longLongIntForColumn:(NSString *)columnName;
- (long long int)longLongIntForColumnIndex:(int)columnIdx;

- (unsigned long long int)unsignedLongLongIntForColumn:(NSString *)columnName;
- (unsigned long long int)unsignedLongLongIntForColumnIndex:(int)columnIdx;

- (double)doubleForColumn:(NSString *)columnName;
- (double)doubleForColumnIndex:(int)columnIdx;

- (BOOL)boolForColumn:(NSString *)columnName;
- (BOOL)boolForColumnIndex:(int)columnIdx;

- (NSString * _Nullable)stringForColumn:(NSString *)columnName;
- (NSString * _Nullable)stringForColumnIndex:(int)columnIdx;

- (NSDate * _Nullable)dateForColumn:(NSString *)columnName;
- (NSDate * _Nullable)dateForColumnIndex:(int)columnIdx;

- (NSData * _Nullable)dataForColumn:(NSString *)columnName;
- (NSData * _Nullable)dataForColumnIndex:(int)columnIdx;

- (const unsigned char * _Nullable)UTF8StringForColumn:(NSString *)columnName;
- (const unsigned char * _Nullable)UTF8StringForColumnIndex:(int)columnIdx;

- (id _Nullable)objectForColumn:(NSString *)columnName;
- (id _Nullable)objectForColumnIndex:(int)columnIdx;

- (BOOL)isNullForColumn:(NSString *)columnName;
- (BOOL)isNullForColumnIndex:(int)columnIdx;

@end

NS_ASSUME_NONNULL_END
