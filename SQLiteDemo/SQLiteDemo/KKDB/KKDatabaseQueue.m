//
//  KKDatabaseQueue.m
//  SQLiteDemo
//
//  Created by Sands on 2023/4/21.
//

#import "KKDatabaseQueue.h"
#import <sqlite3.h>
#import "KKDatabase.h"

static const void *const kKKDBDispatchQueueSpecificKey = &kKKDBDispatchQueueSpecificKey;

@interface KKDatabaseQueue ()
{
    KKDatabase *_db;
    dispatch_queue_t _queue;
}

@end

@implementation KKDatabaseQueue

+ (instancetype)databaseQueueWithPath:(NSString *)aPath {
    return [[self alloc] initWithPath:aPath];
}

- (void)inDatabase:(__attribute__((noescape)) void (^)(KKDatabase * _Nonnull))block {
#ifndef NDEBUG
    // deadlock check
    KKDatabaseQueue *currentSyncQueue = (__bridge KKDatabaseQueue *)(dispatch_get_specific(kKKDBDispatchQueueSpecificKey));
    assert(currentSyncQueue != self && "inDatabase: is called reentrantly on the same queue, which would lead to a deadlock!");
#endif
    
    dispatch_sync(_queue, ^{
        KKDatabase *db = [self database];
        block(db);
        
        if ([db hasOpenResultSets]) {
            NSLog(@">>>>>> Warning: there is at least one open result set around after performing [KKDatabaseQueue inDatabase:]");
        }
    });
}

- (void)inTransaction:(__attribute__((noescape)) void (^)(KKDatabase * _Nonnull, BOOL * _Nonnull))block {
    [self beginTransaction:KKDBTransactionTypeDefault withBlock:block];
}

- (void)inDeferredTransaction:(__attribute__((noescape)) void (^)(KKDatabase * _Nonnull, BOOL * _Nonnull))block {
    [self beginTransaction:KKDBTransactionTypeDeferred withBlock:block];
}

- (void)inExclusiveTransaction:(__attribute__((noescape)) void (^)(KKDatabase * _Nonnull, BOOL * _Nonnull))block {
    [self beginTransaction:KKDBTransactionTypeExclusive withBlock:block];
}

- (void)inImmediateTransaction:(__attribute__((noescape)) void (^)(KKDatabase * _Nonnull, BOOL * _Nonnull))block {
    [self beginTransaction:KKDBTransactionTypeImmediate withBlock:block];
}

- (void)beginTransaction:(KKDBTransactionType)transaction
               withBlock:(__attribute__((noescape)) void (^)(KKDatabase *db, BOOL *rollback))block {
    dispatch_sync(_queue, ^{
        BOOL shouldRollback = NO;
        
        KKDatabase *db = [self database];
        [db beginTransactionWithType:transaction];
        
        block(db, &shouldRollback);
        
        if (shouldRollback) {
            [db rollback];
        } else {
            [db commit];
        }
    });
}

#pragma mark - Private

- (instancetype)initWithPath:(NSString *)aPath {
    return [self initWithPath:aPath flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE vfs:nil];
}

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags vfs:(NSString *)vfsName {
    if (self = [super init]) {
        _db = [[[self class] databaseClass] databaseWithPath:aPath];
        BOOL success = [_db open];
        if (!success) {
            NSLog(@">>>>>> Error: couldn't create database queue for path: %@", aPath);
        }
        _databasePath = aPath;
        const char *label = [[NSString stringWithFormat:@"kkdbqueue.%@", self] UTF8String];
        _queue = dispatch_queue_create(label, NULL);
        // 设置队列标识
        dispatch_queue_set_specific(_queue, kKKDBDispatchQueueSpecificKey, (__bridge void *)(self), NULL);
    }
    
    return self;
}

+ (Class)databaseClass {
    return [KKDatabase class];
}

- (KKDatabase *)database {
    if (![_db isOpen]) {
        if (!_db) {
            _db = [[[self class] databaseClass] databaseWithPath:_databasePath];
        }
        BOOL success = [_db open];
        if (!success) {
            NSLog(@">>>>>> Error: couldn't create database queue for path: %@", _databasePath);
            _db = nil;
            return nil;
        }
    }
    return _db;
}





@end
