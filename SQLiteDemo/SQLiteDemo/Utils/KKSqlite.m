//
//  KKSqlite.m
//  SQLiteDemo
//
//  Created by Sands on 2023/4/18.
//

#import "KKSqlite.h"
#import <sqlite3.h>
#import "KKDatabase.h"
#import "KKResultSet.h"
#import "KKDatabaseQueue.h"
#import "NSString+KKSqlite.h"

@interface KKSqlite ()
{
    NSDateFormatter *_dateFormatter;
}
/// SQLite数据库文件
@property (nonatomic, copy) NSString *filePath;
/// 数据库对象
@property (nonatomic, strong) KKDatabase *db;


@end

@implementation KKSqlite

+ (instancetype)instanceWithFilePath:(NSString *)filePath {
    return [[self alloc] initWithFilePath:filePath];
}

- (instancetype)initWithFilePath:(NSString *)filePath {
    if (self = [super init]) {
        self.filePath = filePath;
        self.db = [KKDatabase databaseWithPath:filePath];
        if (![self.db open]) {
            NSLog(@"---> Error: Wasn't able to open database at path: %@", filePath);
        }
        self.db.shouldCacheStatements = YES;
    }
    return self;
}

#pragma mark - Public

- (BOOL)createTable:(NSString *)tablename columns:(nonnull NSArray<NSDictionary<NSString *,NSString *> *> *)columns {
    if (tablename.length <= 0 || columns.count <= 0) {
        return NO;
    }
    NSMutableString *sql = [NSMutableString stringWithFormat:@"create table if not exists %@ (", tablename];
    for (NSDictionary *columnDict in columns) {
        [columnDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [sql appendFormat:@"%@ %@, ", key, obj];
        }];
    }
    // trim suffix
    [sql trimSuffix:@", "];
    [sql appendString:@")"];
    return [self.db executeUpdate:sql];
}

- (BOOL)dropTable:(NSString *)tablename {
    if (tablename.length <= 0) {
        return NO;
    }
    NSString *sql = [NSString stringWithFormat:@"drop table if exists %@", tablename];
    return [self.db executeUpdate:sql];
}

- (BOOL)insertIntoTable:(NSString *)tablename columns:(NSArray<NSString *> *)columns values:(NSArray<NSArray *> *)values {
    return [self insertIntoTable:tablename columns:columns values:values onDuplicate:nil];
}

- (BOOL)insertOrReplaceIntoTable:(NSString *)tablename
                         columns:(NSArray<NSString *> *)columns
                          values:(NSArray<NSArray *> *)values {
    return [self insertIntoTable:tablename columns:columns values:values onDuplicate:@"replace"];
}

- (BOOL)insertOrIgnoreIntoTable:(NSString *)tablename
                        columns:(NSArray<NSString *> *)columns
                         values:(NSArray<NSArray *> *)values {
    return [self insertIntoTable:tablename columns:columns values:values onDuplicate:@"ignore"];
}

- (BOOL)insertIntoTable:(NSString *)tablename
                columns:(NSArray<NSString *> *)columns
                 values:(NSArray<NSArray *> *)values
            onDuplicate:(NSString *)method {
    if (tablename.length <= 0 || values.count <= 0) {
        return NO;
    }
    NSMutableString *sql = [NSMutableString stringWithString:@"insert "];
    if ([method isKindOfClass:[NSString class]] &&
        ([method isEqualToString:@"replace"] || [method isEqualToString:@"ignore"])) {
        [sql appendFormat:@"or %@ ", method];
    }
    [sql appendFormat:@"into %@ ", tablename];
    
    if (columns.count > 0) {
        NSString *columnsStr = [columns componentsJoinedByString:@", "];
        [sql appendString:@"("];
        [sql appendString:columnsStr];
        [sql appendString:@")"];
    }
    
    // "insert into tablename (c1, c2, c3) values
    [sql appendString:@"values "];
    // 用于展开参数列表
    NSMutableArray *valuesFlatList = [NSMutableArray array];
    int insertValuesCount = columns.count > 0 ? (int)columns.count : [self columnCountsInTable:tablename];
    for (NSArray *value in values) {
        // 参数个数要与列名个数一致
        NSAssert(value.count == insertValuesCount, @"参数个数要与列名个数一致!!!");
        if (value.count != insertValuesCount) {
            return NO;
        }
        // 参数添加到展开列表中
        [valuesFlatList addObjectsFromArray:value];
        // (
        [sql appendString:@"("];
        // ?, ?, ?, ...
        for (int i = 0; i < insertValuesCount; i++) {
            [sql appendFormat:@"?, "];
        }
        // trim suffix
        [sql trimSuffix:@", "];
        // ), "
        [sql appendString:@"), "];
    }
    // trim suffix
    [sql trimSuffix:@", "];
    
    // double check
    NSString *sqlOfValues = [sql substringFromIndex:[sql rangeOfString:@"values"].location];
    NSUInteger countOfValuePlaceholder = [sqlOfValues countOccurrencesOfString:@"?"];
    NSAssert(valuesFlatList.count == countOfValuePlaceholder, @"SQL语句与参数个数要匹配!!!");
    if (valuesFlatList.count != countOfValuePlaceholder) {
        return NO;
    }
    
    return [self.db executeUpdate:sql withArgumentsInArray:valuesFlatList];
}

- (BOOL)deleteFromTable:(NSString *)tablename withColumn:(nonnull NSString *)column inArray:(nonnull NSArray *)values {
    __block BOOL result = YES;
    NSMutableArray *conditions = [NSMutableArray arrayWithCapacity:1];
    // column in (v1, v2, v3)
    NSMutableString *conditionStr = [NSMutableString stringWithFormat:@"%@ in (", column];
    [values enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            [conditionStr appendString:obj];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            [conditionStr appendString:[obj stringValue]];
        } else {
            // error
            *stop = YES;
            result = NO;
        }
        if (idx == values.count - 1) {
            // last
            [conditionStr appendString:@")"];
        } else {
            [conditionStr appendString:@", "];
        }
    }];
    if (result) {
        [conditions addObject:conditionStr];
    }
    
    return result ? [self deleteFromTable:tablename conditions:conditions] : result;
}

- (BOOL)deleteFromTable:(NSString *)tablename conditions:(NSArray<NSString *> *)conditions {
    NSAssert(conditions.count > 0, @"DELETE操作请务必指定条件!");
    if (tablename.length <= 0 || conditions.count <= 0) {
        return NO;
    }
    NSMutableString *sql = [NSMutableString stringWithFormat:@"delete from %@ where ", tablename];
    for (NSString *condition in conditions) {
        [sql appendFormat:@"%@ and ", condition];
    }
    // trim suffix
    [sql trimSuffix:@" and "];
    
    return [self.db executeUpdate:sql];
}

- (BOOL)updateToTable:(NSString *)tablename
              changes:(nonnull NSDictionary<NSString *,id> *)changes
           conditions:(NSArray<NSString *> * _Nullable)conditions {
    if (tablename.length <= 0 || changes.count <= 0) {
        return NO;
    }
    // 用于展开参数列表
    NSMutableArray *valuesFlatList = [NSMutableArray array];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"update %@ set ", tablename];
    [changes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [sql appendFormat:@"%@ = ?, ", key];
        [valuesFlatList addObject:obj];
    }];
    // trim suffix
    [sql trimSuffix:@", "];
    
    // where
    if (conditions.count > 0) {
        [sql appendString:@" where "];
        [conditions enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx == conditions.count - 1) {
                // last
                [sql appendString:obj];
            } else {
                [sql appendFormat:@"%@ and ", obj];
            }
        }];
    }
    
    return [self.db executeUpdate:sql withArgumentsInArray:valuesFlatList];
}

- (NSArray<NSDictionary *> *)selectFromTable:(NSString *)tablename columns:(NSArray<NSString *> *)columns {
    if (tablename.length <= 0) {
        return nil;
    }
    NSMutableArray *resultArr = [NSMutableArray array];
    NSMutableString *sql = [NSMutableString stringWithString:@"select "];
    if (columns.count > 0) {
        NSString *columnsStr = [columns componentsJoinedByString:@", "];
        [sql appendFormat:@"%@ from %@", columnsStr, tablename];
    } else {
        [sql appendFormat:@"* from %@", tablename];
    }
    
    KKResultSet *rs = [self.db executeQuery:sql];
    while ([rs next]) {
        [resultArr addObject:rs.resultDictionary];
    }
    [rs close];
    
    return [resultArr copy];
}

- (NSArray<NSDictionary *> *)selectFromTable:(NSString *)tablename columns:(NSArray<NSString *> *)columns conditions:(NSArray<NSString *> *)conditions {
    return [self selectFromTable:tablename
                         columns:columns
                      conditions:conditions
                          groups:nil
                          orders:nil
                       pageStart:0
                        pageSize:0];
}

- (NSArray<NSDictionary *> *)selectFromTable:(NSString *)tablename
                                     columns:(NSArray<NSString *> *)columns
                                  conditions:(NSArray<NSString *> *)conditions
                                      groups:(NSArray<NSString *> *)groups
                                      orders:(NSDictionary<NSString *,NSString *> *)orders
                                   pageStart:(int)start
                                    pageSize:(int)size {
    if (tablename.length <= 0) {
        return nil;
    }
    
    NSMutableArray *resultArr = [NSMutableArray array];
    NSMutableString *sql = [NSMutableString stringWithString:@"select "];
    if (columns.count > 0) {
        NSString *columnsStr = [columns componentsJoinedByString:@", "];
        [sql appendFormat:@"%@ from %@", columnsStr, tablename];
    } else {
        [sql appendFormat:@"* from %@", tablename];
    }
    
    // where
    if (conditions.count > 0) {
        [sql appendString:@" where "];
        [sql appendString:[conditions componentsJoinedByString:@" and "]];
    }
    // trim suffix
    [sql trimSuffix:@" and "];
    
    // group by
    if (groups.count > 0) {
        [sql appendString:@" group by "];
        [sql appendString:[groups componentsJoinedByString:@", "]];
    }
    // trim suffix
    [sql trimSuffix:@", "];
    
    // order by
    if (orders.count > 0) {
        [sql appendString:@" order by "];
        [orders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [sql appendFormat:@"%@ %@, ", key, obj];
        }];
    }
    // trim suffix
    [sql trimSuffix:@", "];
    
    // limit
    if (start >= 0 && size > 0) {
        [sql appendFormat:@" limit %d, %d", start, size];
    }
    
    KKResultSet *rs = [self.db executeQuery:sql];
    while ([rs next]) {
        [resultArr addObject:rs.resultDictionary];
    }
    [rs close];
    
    return [resultArr copy];
}






- (void)setDateFormatterWithString:(NSString *)fmtString {
    if (!fmtString) {
        [self.db setDateFormatter:nil];
        return;
    }
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeZone = NSTimeZone.localTimeZone;
    }
    _dateFormatter.dateFormat = fmtString;
    [self.db setDateFormatter:_dateFormatter];
}

#pragma mark - Private

- (int)columnCountsInTable:(NSString *)tablename {
    int columnCount = 0;
    NSString *sql = [NSString stringWithFormat:@"select * from %@ limit ?", tablename];
    KKResultSet *rs = [self.db executeQuery:sql, @1];
    columnCount = rs.columnCount;
    [rs close];
    return columnCount;
}



#pragma mark - setter&getter

- (NSDateFormatter *)dateFormatter {
    return _dateFormatter;
}

- (NSError *)lastError {
    return [self.db lastError];
}

@end
