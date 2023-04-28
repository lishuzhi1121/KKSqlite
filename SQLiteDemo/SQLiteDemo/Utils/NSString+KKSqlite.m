//
//  NSString+KKSqlite.m
//  SQLiteDemo
//
//  Created by Sands on 2023/4/23.
//

#import "NSString+KKSqlite.h"

@implementation NSString (KKSqlite)

- (NSUInteger)countOccurrencesOfString:(NSString *)searchString {
    NSString *trimStr = [self stringByReplacingOccurrencesOfString:searchString withString:@""];
    return (self.length - trimStr.length) / searchString.length;
}

- (void)trimSuffix:(NSString *)suffix {
    // trim suffix
    if ([self isKindOfClass:[NSMutableString class]] && [self hasSuffix:suffix]) {
        [(NSMutableString *)self deleteCharactersInRange:NSMakeRange(self.length - suffix.length, suffix.length)];
    }
}

@end
