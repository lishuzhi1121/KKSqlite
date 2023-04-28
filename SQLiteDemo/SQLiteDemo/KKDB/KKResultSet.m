//
//  KKResultSet.m
//  SQLiteDemo
//
//  Created by Sands on 2023/4/19.
//

#import "KKResultSet.h"
#import "KKStatement.h"
#import "KKDatabase.h"
#import <sqlite3.h>

@interface KKResultSet ()
{
    NSMutableDictionary *_columnNameToIndexMap;
}

@property (nonatomic, assign) BOOL shouldAutoClose;

@end


@implementation KKResultSet

+ (instancetype)resultSetWithStatement:(KKStatement *)statement
                   usingParentDatabase:(KKDatabase *)aDB
                       shouldAutoClose:(BOOL)shouldAutoClose {
    KKResultSet *rs = [[KKResultSet alloc] init];
    rs.statement = statement;
    rs.parentDB = aDB;
    rs.shouldAutoClose = shouldAutoClose;
    
    statement.inUse = YES;
    
    return rs;
}

- (void)close {
    [_statement reset];
    _statement = nil;
    
    [_parentDB resultSetDidClose:self];
    _parentDB = nil;
}

- (BOOL)next {
    return [self nextWithError:nil];
}

- (BOOL)nextWithError:(NSError * _Nullable __autoreleasing *)outError {
    int rc = [self internalStepWithError:outError];
    return SQLITE_ROW == rc;
}

- (int)internalStepWithError:(NSError * _Nullable __autoreleasing *)outError {
    int rc = sqlite3_step(_statement.statement);
    if (SQLITE_BUSY == rc || SQLITE_LOCKED == rc) {
        NSLog(@">>>>>> %s:%d Database busy (%@)", __FUNCTION__, __LINE__, _parentDB.databasePath);
        if (outError) {
            *outError = [_parentDB lastError];
        }
    } else if (SQLITE_DONE == rc || SQLITE_ROW == rc) {
        // all is well, just return
    } else if (SQLITE_ERROR == rc) {
        NSLog(@">>>>>> Error calling sqlite3_step (%d: %@) rs.", rc, [_parentDB lastErrorMessage]);
        if (outError) {
            *outError = [_parentDB lastError];
        }
    } else if (SQLITE_MISUSE == rc) {
        NSLog(@">>>>>> Error calling sqlite3_step (%d: %@) rs.", rc, [_parentDB lastErrorMessage]);
        if (outError) {
            if (_parentDB) {
                *outError = [_parentDB lastError];
            } else {
                // If 'next' or 'nextWithError' is called after the result set is closed,
                // we need to return the appropriate error.
                NSDictionary* errorMsg = [NSDictionary dictionaryWithObject:@"parentDB does not exist" forKey:NSLocalizedDescriptionKey];
                *outError = [NSError errorWithDomain:@"KKDatabase" code:SQLITE_MISUSE userInfo:errorMsg];
            }
        }
    } else {
        NSLog(@">>>>>> Error calling sqlite3_step (%d: %@) rs.", rc, [_parentDB lastErrorMessage]);
        if (outError) {
            *outError = [_parentDB lastError];
        }
    }
    
    if (SQLITE_ROW != rc && _shouldAutoClose) {
        [self close];
    }
    
    return rc;
}

#pragma mark - 获取结果集中的数据

- (int)columnIndexForName:(NSString *)columnName {
    NSNumber *idx = [self.columnNameToIndexMap objectForKey:columnName];
    if (idx == nil) {
        NSLog(@">>>>>> Warning: I could not find the column named '%@'.", columnName);
        return -1;
    }
    
    return [idx intValue];
}

- (NSString *)columnNameForIndex:(int)columnIdx {
    return [NSString stringWithUTF8String:sqlite3_column_name(_statement.statement, columnIdx)];
}

- (int)intForColumn:(NSString *)columnName {
    return [self intForColumnIndex:[self columnIndexForName:columnName]];
}

- (int)intForColumnIndex:(int)columnIdx {
    return sqlite3_column_int(_statement.statement, columnIdx);
}

- (long)longForColumn:(NSString *)columnName {
    return [self longForColumnIndex:[self columnIndexForName:columnName]];
}

- (long)longForColumnIndex:(int)columnIdx {
    return (long)sqlite3_column_int64(_statement.statement, columnIdx);
}

- (long long)longLongIntForColumn:(NSString *)columnName {
    return [self longLongIntForColumnIndex:[self columnIndexForName:columnName]];
}

- (long long int)longLongIntForColumnIndex:(int)columnIdx {
    return sqlite3_column_int64(_statement.statement, columnIdx);
}

- (unsigned long long)unsignedLongLongIntForColumn:(NSString *)columnName {
    return (unsigned long long)[self longLongIntForColumn:columnName];
}

- (unsigned long long)unsignedLongLongIntForColumnIndex:(int)columnIdx {
    return (unsigned long long)[self longLongIntForColumnIndex:columnIdx];
}

- (double)doubleForColumn:(NSString *)columnName {
    return [self doubleForColumnIndex:[self columnIndexForName:columnName]];
}

- (double)doubleForColumnIndex:(int)columnIdx {
    return sqlite3_column_double(_statement.statement, columnIdx);
}

- (BOOL)boolForColumn:(NSString *)columnName {
    return [self boolForColumnIndex:[self columnIndexForName:columnName]];
}

- (BOOL)boolForColumnIndex:(int)columnIdx {
    return [self intForColumnIndex:columnIdx] != 0;
}

- (NSString *)stringForColumn:(NSString *)columnName {
    return [self stringForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSString *)stringForColumnIndex:(int)columnIdx {
    if (columnIdx < 0 || columnIdx >= sqlite3_column_count(_statement.statement)) {
        return nil;
    }
    if (SQLITE_NULL == sqlite3_column_type(_statement.statement, columnIdx)) {
        return nil;
    }
    
    const char *c = (const char *)sqlite3_column_text(_statement.statement, columnIdx);
    if (!c) {
        return nil;
    }
    
    return [NSString stringWithUTF8String:c];
}

- (NSDate *)dateForColumn:(NSString *)columnName {
    return [self dateForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSDate *)dateForColumnIndex:(int)columnIdx {
    if (columnIdx < 0 || columnIdx >= [self columnCount] ||
        SQLITE_NULL == sqlite3_column_type(_statement.statement, columnIdx)) {
        return nil;
    }
    
    if ([_parentDB hasDateFormatter]) {
        return [_parentDB dateFromString:[self stringForColumnIndex:columnIdx]];
    }
    
    return [NSDate dateWithTimeIntervalSince1970:[self doubleForColumnIndex:columnIdx]];
}

- (NSData *)dataForColumn:(NSString *)columnName {
    return [self dataForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSData *)dataForColumnIndex:(int)columnIdx {
    if (columnIdx < 0 || columnIdx >= sqlite3_column_count(_statement.statement)) {
        return nil;
    }
    if (SQLITE_NULL == sqlite3_column_type(_statement.statement, columnIdx)) {
        return nil;
    }
    const char *dataBuff = sqlite3_column_blob(_statement.statement, columnIdx);
    int dataSize = sqlite3_column_bytes(_statement.statement, columnIdx);
    if (dataBuff == NULL || dataSize <= 0) {
        return nil;
    }
    
    return [NSData dataWithBytes:dataBuff length:dataSize];
}

- (const unsigned char *)UTF8StringForColumn:(NSString *)columnName {
    return [self UTF8StringForColumnIndex:[self columnIndexForName:columnName]];
}

- (const unsigned char *)UTF8StringForColumnIndex:(int)columnIdx {
    if (columnIdx < 0 || columnIdx >= [self columnCount] ||
        SQLITE_NULL == sqlite3_column_type(_statement.statement, columnIdx)) {
        return NULL;
    }
    
    return sqlite3_column_text(_statement.statement, columnIdx);
}

- (id)objectForColumn:(NSString *)columnName {
    return [self objectForColumnIndex:[self columnIndexForName:columnName]];
}

- (id)objectForColumnIndex:(int)columnIdx {
    if (columnIdx < 0 || columnIdx >= sqlite3_column_count(_statement.statement)) {
        return nil;
    }
    id returnValue = nil;
    int columnType = sqlite3_column_type(_statement.statement, columnIdx);
    if (SQLITE_INTEGER == columnType) {
        returnValue = [NSNumber numberWithLongLong:[self longLongIntForColumnIndex:columnIdx]];
    } else if (SQLITE_FLOAT == columnType) {
        returnValue = [NSNumber numberWithDouble:[self doubleForColumnIndex:columnIdx]];
    } else if (SQLITE_BLOB == columnType) {
        returnValue = [self dataForColumnIndex:columnIdx];
    } else {
        // default to a string
        returnValue = [self stringForColumnIndex:columnIdx];
    }
    
    if (returnValue == nil) {
        returnValue = [NSNull null];
    }
    
    return returnValue;
}

- (BOOL)isNullForColumn:(NSString *)columnName {
    return [self isNullForColumnIndex:[self columnIndexForName:columnName]];
}

- (BOOL)isNullForColumnIndex:(int)columnIdx {
    return SQLITE_NULL == sqlite3_column_type(_statement.statement, columnIdx);
}

#pragma mark - setter&getter

- (int)columnCount {
    return sqlite3_column_count(_statement.statement);
}

- (NSDictionary *)resultDictionary {
    int num_cols = sqlite3_data_count(_statement.statement);
    if (num_cols > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:num_cols];
        int columnCount = sqlite3_column_count(_statement.statement);
        int columnIdx = 0;
        for (columnIdx = 0; columnIdx < columnCount; columnIdx++) {
            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(_statement.statement, columnIdx)];
            id obj = [self objectForColumnIndex:columnIdx];
            [dict setObject:obj forKey:columnName];
        }
        return dict;
    } else {
        NSLog(@">>>>>> Warning: There seem to be no columns in this set!");
    }
    
    return nil;
}

- (NSMutableDictionary *)columnNameToIndexMap {
    if (!_columnNameToIndexMap) {
        int columnCount = [self columnCount];
        _columnNameToIndexMap = [NSMutableDictionary dictionaryWithCapacity:columnCount];
        for (int i = 0; i < columnCount; i++) {
            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(_statement.statement, i)];
            [_columnNameToIndexMap setValue:@(i) forKey:columnName];
        }
    }
    return _columnNameToIndexMap;
}

@end
