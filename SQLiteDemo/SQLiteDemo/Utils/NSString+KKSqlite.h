//
//  NSString+KKSqlite.h
//  SQLiteDemo
//
//  Created by Sands on 2023/4/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (KKSqlite)

/// 统计字符串中某个子字符串出现的次数
/// - Parameter searchString: 要搜索的子字符串
- (NSUInteger)countOccurrencesOfString:(NSString *)searchString;

/// 去除字符串指定后缀
/// - 务必是可变字符串调用该方法才有效果
/// - Parameter suffix: 后缀
- (void)trimSuffix:(NSString *)suffix;

@end

NS_ASSUME_NONNULL_END
