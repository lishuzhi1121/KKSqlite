//
//  KKStatement.h
//  SQLiteDemo
//
//  Created by Sands on 2023/4/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// SQL语句封装类
@interface KKStatement : NSObject

/// sqlite3_stmt 对象
@property (atomic, assign) void *statement;
/// SQL语句
@property (nonatomic, copy) NSString *query;
/// 标识SQL语句是否正在使用中
@property (atomic, assign) BOOL inUse;
/// 执行次数
@property (nonatomic, assign) long useCount;

/// 重置SQL语句状态
- (void)reset;

/// 关闭SQL语句
- (void)close;

@end

NS_ASSUME_NONNULL_END
