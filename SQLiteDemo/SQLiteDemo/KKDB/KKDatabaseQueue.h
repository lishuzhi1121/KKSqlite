//
//  KKDatabaseQueue.h
//  SQLiteDemo
//
//  Created by Sands on 2023/4/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KKDatabase;

@interface KKDatabaseQueue : NSObject

@property (nonatomic, readonly, copy) NSString *databasePath;

/// 数据库队列对象构造方法
/// - Parameter aPath: SQLite数据库文件路径
+ (instancetype)databaseQueueWithPath:(NSString *)aPath;

- (void)inDatabase:(__attribute__((noescape)) void (^)(KKDatabase *db))block;

- (void)inTransaction:(__attribute__((noescape)) void (^)(KKDatabase *db, BOOL *rollback))block;
- (void)inDeferredTransaction:(__attribute__((noescape)) void (^)(KKDatabase *db, BOOL *rollback))block;
- (void)inExclusiveTransaction:(__attribute__((noescape)) void (^)(KKDatabase *db, BOOL *rollback))block;
- (void)inImmediateTransaction:(__attribute__((noescape)) void (^)(KKDatabase *db, BOOL *rollback))block;

@end

NS_ASSUME_NONNULL_END
