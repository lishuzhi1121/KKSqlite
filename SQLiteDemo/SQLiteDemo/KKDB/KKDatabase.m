//
//  KKDatabase.m
//  SQLiteDemo
//
//  Created by Sands on 2023/4/19.
//

#import "KKDatabase.h"
#import <sqlite3.h>
#import "KKStatement.h"
#import "KKResultSet.h"


@interface KKDatabase ()
{
    /// 数据库对象
    sqlite3 *           _db;
    /// 是否正在执行SQL语句
    BOOL                _isExecutingStatement;
    /// 日期格式化器
    NSDateFormatter     *_dateFormatter;
    /// SQL执行结果对象缓存
    NSMutableSet        *_openResultSets;
    
}

@end

@implementation KKDatabase

// 重写了该属性的setter&getter
@synthesize shouldCacheStatements = _shouldCacheStatements;


+ (instancetype)databaseWithPath:(NSString *)aPath {
    return [[self alloc] initWithPath:aPath];
}

- (instancetype)initWithPath:(NSString *)path {
    // make sure sqlite it happy with what we're going to do
    assert(sqlite3_threadsafe());
    
    if (self = [super init]) {
        _databasePath = [path copy];
        _isOpen = NO;
        _db = NULL;
        _isExecutingStatement = NO;
        _dateFormatter = nil;
        _openResultSets = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Public

- (BOOL)open {
    if (_isOpen) {
        return YES;
    }
    // if we previously tried to open, but it failed, make sure to close it before we try again.
    if (_db) {
        [self close];
    }
    // now open database
    int rc = sqlite3_open([self sqlitePath], &_db);
    if (SQLITE_OK != rc) {
        NSLog(@">>>>>> Error opening: %d", rc);
        return NO;
    }
    
    _isOpen = YES;
    return YES;
}

- (BOOL)close {
    if (!_db) {
        return YES;
    }
    
    BOOL retry = NO;
    BOOL triedFinalizingOpenStatements = NO;
    do {
        retry = NO;
        int rc = sqlite3_close(_db);
        // 数据库正忙
        if (SQLITE_BUSY == rc || SQLITE_LOCKED == rc) {
            if (!triedFinalizingOpenStatements) {
                triedFinalizingOpenStatements = YES;
                sqlite3_stmt *pStmt = NULL;
                while ((pStmt = sqlite3_next_stmt(_db, NULL)) != NULL) {
                    NSLog(@">>>>>> Closing leaked statements...");
                    sqlite3_finalize(pStmt);
                    pStmt = NULL;
                    retry = YES;
                }
            }
        } else if (SQLITE_OK != rc) {
            NSLog(@">>>>>> Error closing: %d", rc);
        }
    } while (retry);
    
    _db = nil;
    _isOpen = NO;
    return YES;
}

- (BOOL)goodConnection {
    if (!_isOpen) {
        return NO;
    }
#ifdef SQLCIPHER_CRYPTO
    // Starting with Xcode8 / iOS 10 we check to make sure we really are linked with
    // SQLCipher because there is no longer a linker error if we accidently link
    // with unencrypted sqlite library.
    //
    // https://discuss.zetetic.net/t/important-advisory-sqlcipher-with-xcode-8-and-new-sdks/1688
    KKResultSet *rs = [self executeQuery:@"PRAGMA cipher_version"];
    if ([rs next]) {
        NSString *ver = rs.resultDictionary[@"cipher_version"];
        NSLog(@">>>>>> SQLCipher version: %@", ver);
        [rs close];
        return YES;
    }
#else
    KKResultSet *rs = [self executeQuery:@"select name from sqlite_master where type='table'"];
    if ([rs next]) {
        NSLog(@">>>>>> %@", rs.resultDictionary);
        [rs close];
        return YES;
    }
#endif
    
    return NO;
}

#pragma mark - 更新

- (BOOL)executeUpdate:(NSString *)sql, ... {
    va_list args;
    va_start(args, sql);
    BOOL result = [self executeUpdate:sql
                                error:nil
                 withArgumentsInArray:nil
                         orDictionary:nil
                             orVAList:args];
    va_end(args);
    return result;
}

- (BOOL)executeUpdate:(NSString *)sql withErrorAndBindings:(NSError * _Nullable __autoreleasing *)outError, ... {
    va_list args;
    va_start(args, outError);
    BOOL result = [self executeUpdate:sql
                                error:outError
                 withArgumentsInArray:nil
                         orDictionary:nil
                             orVAList:args];
    va_end(args);
    return result;
}

-(BOOL)executeUpdateWithFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSMutableString *sql = [NSMutableString stringWithCapacity:format.length];
    NSMutableArray *arguments = [NSMutableArray array];
    // 将format字符串解析为sql语句和参数信息
    [self extractSQL:format argumentsList:args intoString:sql arguments:arguments];
    va_end(args);
    return [self executeUpdate:sql withArgumentsInArray:arguments];
}

- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
    return [self executeUpdate:sql
                         error:nil
          withArgumentsInArray:arguments
                  orDictionary:nil
                      orVAList:nil];
}

- (BOOL)executeUpdate:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments {
    return [self executeUpdate:sql
                         error:nil
          withArgumentsInArray:nil
                  orDictionary:arguments
                      orVAList:nil];
}

- (BOOL)executeUpdate:(NSString *)sql values:(NSArray *)values error:(NSError * _Nullable __autoreleasing *)error {
    return [self executeUpdate:sql
                         error:error
          withArgumentsInArray:values
                  orDictionary:nil
                      orVAList:nil];
}

#pragma mark - 查询

- (KKResultSet *)executeQuery:(NSString *)sql, ... {
    va_list args;
    va_start(args, sql);
    KKResultSet *result = [self executeQuery:sql
                        withArgumentsInArray:nil
                                orDictionary:nil
                                    orVAList:args
                                  shouldBind:YES];
    va_end(args);
    return result;
}

- (KKResultSet *)executeQueryWithFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSMutableString *sql = [NSMutableString stringWithCapacity:format.length];
    NSMutableArray *arguments = [NSMutableArray array];
    // 将format字符串解析为sql语句和参数信息
    [self extractSQL:format argumentsList:args intoString:sql arguments:arguments];
    va_end(args);
    return [self executeQuery:sql withArgumentsInArray:arguments];
}

- (KKResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
    return [self executeQuery:sql
         withArgumentsInArray:arguments
                 orDictionary:nil
                     orVAList:nil
                   shouldBind:YES];
}

- (KKResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments {
    return [self executeQuery:sql
         withArgumentsInArray:nil
                 orDictionary:arguments
                     orVAList:nil
                   shouldBind:YES];
}

- (KKResultSet *)executeQuery:(NSString *)sql values:(NSArray *)values error:(NSError * _Nullable __autoreleasing *)error {
    KKResultSet *rs = [self executeQuery:sql
                    withArgumentsInArray:values
                            orDictionary:nil
                                orVAList:nil
                              shouldBind:YES];
    if (!rs && error) {
        *error = [self lastError];
    }
    return rs;
}

#pragma mark - 批量执行SQL

/// sqlite3_exec 执行的回调函数
/// - Parameters:
///   - theBlockAsVoid: 自定义的透传参数, 这里透传回调的block
///   - columns: 执行结果列数
///   - values: 执行结果
///   - names: 列名称
int KKDBExecuteBulkSQLCallback(void *theBlockAsVoid, int columns, char **values, char **names) {
    if (!theBlockAsVoid) {
        return SQLITE_OK;
    }
    
    int (^execCallbackBlock)(NSDictionary *dictionary) = (__bridge int (^)(NSDictionary *__strong))(theBlockAsVoid);
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:columns];
    for (int i = 0; i < columns; i++) {
        NSString *key = [NSString stringWithUTF8String:names[i]];
        id value = values[i] ? [NSString stringWithUTF8String:values[i]] : [NSNull null];
        value = value ? value : [NSNull null];
        [dictionary setValue:value forKey:key];
    }
    
    return execCallbackBlock(dictionary);
}

- (BOOL)executeStatements:(NSString *)sql {
    return [self executeStatements:sql withResultBlock:nil];
}

- (BOOL)executeStatements:(NSString *)sql withResultBlock:(__attribute__((noescape)) KKDBExecuteStatementsCallbackBlock)block {
    char *errmsg = NULL;
    int rc = sqlite3_exec(_db,
                          [sql UTF8String],
                          block ? KKDBExecuteBulkSQLCallback : nil,
                          (__bridge void *)(block),
                          &errmsg);
    if (errmsg) {
        NSLog(@">>>>>> Error execute statements: %s", errmsg);
        sqlite3_free(errmsg);
        return NO;
    }
    
    return SQLITE_OK == rc;
}

#pragma mark - 事务
- (BOOL)beginTransaction {
    return [self beginTransactionWithType:KKDBTransactionTypeDefault];
}

- (BOOL)beginTransactionWithType:(KKDBTransactionType)type {
    NSString *transactionType = nil;
    switch (type) {
        case KKDBTransactionTypeDeferred:
            transactionType = @"deferred";
            break;
        case KKDBTransactionTypeImmediate:
            transactionType = @"immediate";
            break;
        case KKDBTransactionTypeExclusive:
            transactionType = @"exclusive";
            break;
            
        default:
            transactionType = @"exclusive";
            break;
    }
    NSString *transactionSql = [NSString stringWithFormat:@"begin %@ transaction", transactionType];
    BOOL b = [self executeUpdate:transactionSql];
    if (b) {
        _isInTransaction = YES;
    }
    return b;
}

- (BOOL)commit {
    BOOL b = [self executeUpdate:@"commit transaction"];
    if (b) {
        _isInTransaction = NO;
    }
    return b;
}

- (BOOL)rollback {
    BOOL b = [self executeUpdate:@"rollback transaction"];
    if (b) {
        _isInTransaction = NO;
    }
    return b;
}



#pragma mark - Other

- (void)resultSetDidClose:(KKResultSet *)resultSet {
    NSValue *value = [NSValue valueWithNonretainedObject:resultSet];
    [_openResultSets removeObject:value];
}

- (void)setDateFormatter:(NSDateFormatter *)formatter {
    _dateFormatter = formatter;
}

- (BOOL)hasDateFormatter {
    return _dateFormatter != nil;
}

- (NSDate *)dateFromString:(NSString *)s {
    return [_dateFormatter dateFromString:s];
}

- (NSString *)stringFromDate:(NSDate *)date {
    return [_dateFormatter stringFromDate:date];
}

- (int)lastErrorCode {
    return sqlite3_errcode(_db);
}

- (NSString *)lastErrorMessage {
    return [NSString stringWithUTF8String:sqlite3_errmsg(_db)];
}

- (NSError *)lastError {
    return [self errorWithMessage:[self lastErrorMessage]];
}

- (NSError *)errorWithMessage:(NSString *)message {
    NSDictionary *errorMsg = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"KKDatabase"
                               code:[self lastErrorCode]
                           userInfo:errorMsg];
}

#pragma mark - Private

- (BOOL)executeUpdate:(NSString *)sql
                error:(NSError * _Nullable *)outError
 withArgumentsInArray:(NSArray *)arrayArgs
         orDictionary:(NSDictionary *)dictionaryArgs
             orVAList:(va_list)args {
    KKResultSet *rs = [self executeQuery:sql
                    withArgumentsInArray:arrayArgs
                            orDictionary:dictionaryArgs
                                orVAList:args
                              shouldBind:YES];
    if (!rs) {
        if (outError) {
            *outError = [self lastError];
        }
        return NO;
    }
    
    return SQLITE_DONE == [rs internalStepWithError:outError];
}

- (KKResultSet *)executeQuery:(NSString *)sql
         withArgumentsInArray:(NSArray *)arrayArgs
                 orDictionary:(NSDictionary *)dictionaryArgs
                     orVAList:(va_list)args
                   shouldBind:(BOOL)shouldBind {
    if (![self databaseExists]) {
        return nil;
    }
    
    if (_isExecutingStatement) {
        NSLog(@">>>>>> Warning: The KKDatabase %@ is currently in use.", self);
        return nil;
    }
    _isExecutingStatement = YES;
    NSLog(@">>>>>> %@ executeQuery: %@", self, sql);
    
    KKStatement *statement = nil;
    sqlite3_stmt *pStmt = NULL;
    if (_shouldCacheStatements) {
        statement = [self cachedStatementForQuery:sql];
        pStmt = statement ? [statement statement] : NULL;
        [statement reset];
    }
    
    if (!pStmt) {
        int rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &pStmt, 0);
        if (SQLITE_OK != rc) {
            NSLog(@">>>>>> DB %@ prepare for: %@ error. code: %d, error message: %@", self, sql, [self lastErrorCode], [self lastErrorMessage]);
            sqlite3_finalize(pStmt);
            pStmt = NULL;
            _isExecutingStatement = NO;
            return nil;
        }
    }
    
    if (shouldBind) {
        BOOL success = [self bindStatement:pStmt
                      WithArgumentsInArray:arrayArgs
                              orDictionary:dictionaryArgs
                                  orVAList:args];
        if (!success) {
            return nil;
        }
    }
    
    if (!statement) {
        statement = [[KKStatement alloc] init];
        statement.statement = pStmt;
        if(_shouldCacheStatements && sql) {
            [self setCachedStatement:statement forQuery:sql];
        }
    }
    
    KKResultSet *rs = [KKResultSet resultSetWithStatement:statement
                                      usingParentDatabase:self
                                          shouldAutoClose:shouldBind];
    rs.query = sql;
    
    NSValue *value = [NSValue valueWithNonretainedObject:rs];
    [_openResultSets addObject:value];
    
    statement.useCount = statement.useCount + 1;
    
    _isExecutingStatement = NO;
    return rs;
}

- (BOOL)bindStatement:(sqlite3_stmt *)pStmt
 WithArgumentsInArray:(NSArray *)arrayArgs
         orDictionary:(NSDictionary *)dictionaryArgs
             orVAList:(va_list)args {
    int queryCount = sqlite3_bind_parameter_count(pStmt);
    int idx = 0; // binding count
    id obj = nil;
    // if dictionaryArgs passed in, that means we are using sqlite's named parameter suppor
    if ([dictionaryArgs isKindOfClass:[NSDictionary class]] && dictionaryArgs.count > 0) {
        for (NSString *dictionaryKey in dictionaryArgs.allKeys) {
            // Prefix the key with a colon
            NSString *parameterName = [NSString stringWithFormat:@":%@", dictionaryKey];
            // Get the index for the parameter name
            int namedIdx = sqlite3_bind_parameter_index(pStmt, [parameterName UTF8String]);
            if (namedIdx > 0) {
                // Stardard binding from here.
                int rc = [self bindObject:[dictionaryArgs objectForKey:dictionaryKey]
                                 toColumn:namedIdx
                              inStatement:pStmt];
                if (SQLITE_OK != rc) {
                    NSLog(@">>>>>> Error: unable to bind (%d, %s", rc, sqlite3_errmsg(_db));
                    sqlite3_finalize(pStmt);
                    pStmt = NULL;
                    _isExecutingStatement = NO;
                    return NO;
                }
                // increment the binding count
                idx++;
            } else {
                NSLog(@">>>>>> Error: could not find index for %@", dictionaryKey);
            }
        }
    } else {
        while (idx < queryCount) {
            if (arrayArgs && idx < arrayArgs.count) {
                obj = [arrayArgs objectAtIndex:idx];
            } else if (args) {
                obj = va_arg(args, id);
            } else {
                break;
            }
            
            // increment the binding count, index from 1
            idx++;
            
            int rc = [self bindObject:obj
                             toColumn:idx
                          inStatement:pStmt];
            if (SQLITE_OK != rc) {
                NSLog(@">>>>>> Error: unable to bind (%d, %s)", rc, sqlite3_errmsg(_db));
                sqlite3_finalize(pStmt);
                pStmt = NULL;
                _isExecutingStatement = NO;
                return NO;
            }
        }
    }
    
    if (idx != queryCount) {
        NSLog(@">>>>>> Error: the bind count is not correct for the # of variables (executeQuery)");
        sqlite3_finalize(pStmt);
        pStmt = NULL;
        _isExecutingStatement = NO;
        return NO;
    }
    
    return YES;
}

- (int)bindObject:(id)obj
         toColumn:(int)idx
      inStatement:(sqlite3_stmt *)pStmt {
    // 绑定空值
    if (!obj || ((NSNull *)obj == [NSNull null])) {
        return sqlite3_bind_null(pStmt, idx);
    }
    // 绑定Data类型
    else if ([obj isKindOfClass:[NSData class]]) {
        const void *bytes = [obj bytes];
        if (!bytes) {
            // it's an empty NSData object, aka [NSData data].
            // Don't pass a NULL pointer, or sqlite will bind a SQL null instead of a blob.
            bytes = "";
        }
        return sqlite3_bind_blob(pStmt, idx, bytes, (int)[obj length], SQLITE_TRANSIENT);
    }
    // 绑定日期类型
    else if ([obj isKindOfClass:[NSDate class]]) {
        if ([self hasDateFormatter]) {
            return sqlite3_bind_text(pStmt, idx, [[self stringFromDate:obj] UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            return sqlite3_bind_double(pStmt, idx, [obj timeIntervalSince1970]);
        }
    }
    // 绑定NSNumber类型
    else if ([obj isKindOfClass:[NSNumber class]]) {
        // number有很多类型: char, unsigned char, short, int, long, float, double,bool 等等
        if (strcmp([obj objCType], @encode(char)) == 0) {
            return sqlite3_bind_int(pStmt, idx, [obj charValue]);
        } else if (strcmp([obj objCType], @encode(unsigned char)) == 0) {
            return sqlite3_bind_int(pStmt, idx, [obj unsignedCharValue]);
        } else if (strcmp([obj objCType], @encode(short)) == 0) {
            return sqlite3_bind_int(pStmt, idx, [obj shortValue]);
        } else if (strcmp([obj objCType], @encode(unsigned short)) == 0) {
            return sqlite3_bind_int(pStmt, idx, [obj unsignedShortValue]);
        } else if (strcmp([obj objCType], @encode(int)) == 0) {
            return sqlite3_bind_int(pStmt, idx, [obj intValue]);
        } else if (strcmp([obj objCType], @encode(unsigned int)) == 0) {
            return sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedIntValue]);
        } else if (strcmp([obj objCType], @encode(long)) == 0) {
            return sqlite3_bind_int64(pStmt, idx, [obj longValue]);
        } else if (strcmp([obj objCType], @encode(unsigned long)) == 0) {
            return sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongValue]);
        } else if (strcmp([obj objCType], @encode(long long)) == 0) {
            return sqlite3_bind_int64(pStmt, idx, [obj longLongValue]);
        } else if (strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            return sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongLongValue]);
        } else if (strcmp([obj objCType], @encode(float)) == 0) {
            return sqlite3_bind_double(pStmt, idx, [obj floatValue]);
        } else if (strcmp([obj objCType], @encode(double)) == 0) {
            return sqlite3_bind_double(pStmt, idx, [obj doubleValue]);
        } else if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            return sqlite3_bind_int(pStmt, idx, [obj boolValue] ? 1 : 0);
        } else {
            return sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_TRANSIENT);
        }
    }
    // 绑定其他类型(字符串)
    return sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_TRANSIENT);
}

- (void)extractSQL:(NSString *)sql
     argumentsList:(va_list)args
        intoString:(NSMutableString *)cleanedSQL
         arguments:(NSMutableArray *)arguments {
    NSUInteger length = sql.length;
    unichar last = '\0';
    for (NSUInteger i = 0; i < length; i++) {
        id arg = nil;
        unichar current = [sql characterAtIndex:i];
        unichar add = current;
        if (last == '%') {
            switch (current) {
                case '@':
                    arg = va_arg(args, id);
                    break;
                case 'c':
                    arg = [NSString stringWithFormat:@"%c", va_arg(args, int)];
                    break;
                case 's':
                    arg = [NSString stringWithUTF8String:va_arg(args, char*)];
                    break;
                case 'd':
                case 'D':
                case 'i':
                    arg = [NSNumber numberWithInt:va_arg(args, int)];
                    break;
                case 'u':
                case 'U':
                    arg = [NSNumber numberWithUnsignedInt:va_arg(args, unsigned int)];
                    break;
                case 'h':
                    i++;
                    if (i< length && [sql characterAtIndex:i] == 'i') {
                        arg = [NSNumber numberWithShort:(short)(va_arg(args, int))];
                    } else if (i < length && [sql characterAtIndex:i] == 'u') {
                        arg = [NSNumber numberWithUnsignedShort:(unsigned short)(va_arg(args, uint))];
                    } else {
                        i--;
                    }
                    break;
                case 'q':
                    i++;
                    if (i< length && [sql characterAtIndex:i] == 'i') {
                        arg = [NSNumber numberWithLongLong:(long long)va_arg(args, long long)];
                    } else if (i < length && [sql characterAtIndex:i] == 'u') {
                        arg = [NSNumber numberWithUnsignedLongLong:(unsigned long long)(va_arg(args, unsigned long long))];
                    } else {
                        i--;
                    }
                    break;
                case 'f':
                    arg = [NSNumber numberWithDouble:va_arg(args, double)];
                    break;
                case 'g':
                    arg = [NSNumber numberWithFloat:(float)va_arg(args, double)];
                    break;
                case 'l':
                    i++;
                    if (i < length) {
                        unichar next = [sql characterAtIndex:i];
                        if (next == 'l') {
                            i++;
                            if (i< length && [sql characterAtIndex:i] == 'd') {
                                // %lld
                                arg = [NSNumber numberWithLongLong:(long long)(va_arg(args, long long))];
                            } else if (i < length && [sql characterAtIndex:i] == 'u') {
                                // %llu
                                arg = [NSNumber numberWithUnsignedLongLong:(unsigned long long)(va_arg(args, unsigned long long))];
                            } else {
                                i--;
                            }
                        } else if (next == 'd') {
                            // %ld
                            arg = [NSNumber numberWithLong:va_arg(args, long)];
                        } else if (next == 'u') {
                            // %lu
                            arg = [NSNumber numberWithUnsignedLong:va_arg(args, unsigned long)];
                        } else {
                            i--;
                        }
                    } else {
                        i--;
                    }
                    break;
                    
                default:
                    // something else that we can't interpret.
                    break;
            }
        } else if (current == '%') {
            // percent sign; skip
            add = '\0';
        }
        
        if (arg != nil) {
            [cleanedSQL appendString:@"?"];
            [arguments addObject:arg];
        } else if (add == ((unichar)'@') && last == ((unichar)'%')) {
            [cleanedSQL appendString:@"NULL"];
        } else if (add != '\0') {
            [cleanedSQL appendFormat:@"%c", add];
        }
        
        last = current;
    }
}

- (void)setCachedStatement:(KKStatement *)statement forQuery:(NSString *)query {
    if ([query isKindOfClass:[NSString class]] && query.length > 0) {
        query = [query copy];
        statement.query = query;
        
        NSMutableSet *statements = [_cachedStatements objectForKey:query];
        if (!statements) {
            statements = [NSMutableSet set];
        }
        [statements addObject:statement];
        [_cachedStatements setObject:statements forKey:query];
    }
}

- (KKStatement *)cachedStatementForQuery:(NSString *)query {
    if ([query isKindOfClass:[NSString class]] && query.length > 0) {
        NSMutableSet *statements = [_cachedStatements objectForKey:query];
        return [[statements objectsPassingTest:^BOOL(KKStatement * _Nonnull statement, BOOL * _Nonnull stop) {
            *stop = ![statement inUse];
            return *stop;
        }] anyObject];
    }
    return nil;
}

- (BOOL)databaseExists {
    if (!_isOpen) {
        NSLog(@">>>>>> The KKDatabase %@ is not open.", self);
        return NO;
    }
    return YES;
}

- (const char *)sqlitePath {
    if (!_databasePath) {
        return ":memory:";
    }
    if (_databasePath.length <= 0) {
        return ""; // this create a temporary database (it's an sqlite thing).
    }
    return [_databasePath fileSystemRepresentation];
}

#pragma mark - setter & getter

- (void)setShouldCacheStatements:(BOOL)shouldCacheStatements {
    _shouldCacheStatements = shouldCacheStatements;
    
    if (_shouldCacheStatements & !_cachedStatements) {
        self.cachedStatements = [NSMutableDictionary dictionary];
    }
    
    if (!_shouldCacheStatements) {
        self.cachedStatements = nil;
    }
}

- (BOOL)shouldCacheStatements {
    return _shouldCacheStatements;
}

- (BOOL)hasOpenResultSets {
    return _openResultSets.count > 0;
}

@end

