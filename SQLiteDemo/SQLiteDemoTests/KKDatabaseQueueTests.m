//
//  KKDatabaseQueueTests.m
//  SQLiteDemoTests
//
//  Created by Sands on 2023/4/21.
//

#import <XCTest/XCTest.h>
#import "KKDatabase.h"
#import "KKResultSet.h"
#import "KKDatabaseQueue.h"

@interface KKDatabaseQueueTests : XCTestCase

@property (nonatomic, strong) KKDatabaseQueue *dbQueue;

@end

@implementation KKDatabaseQueueTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *testDBQueuePath = [documentDir stringByAppendingPathComponent:@"kkdbqueue_test_.sqlite"];
    NSLog(@">>>>>> %@", testDBQueuePath);
    self.dbQueue = [KKDatabaseQueue databaseQueueWithPath:testDBQueuePath];
    XCTAssert(self.dbQueue, @"Error: Wasn't able to create database queue!!!");
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testQueueCreateTable {
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        NSString *sql = @"create table if not exists t_queue_test (id integer primary key autoincrement, key text, value integer)";
        BOOL result = [db executeUpdate:sql];
        XCTAssertTrue(result, @"Should success to create table.");
    }];
}

- (void)testQueueInsertData {
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        BOOL result = [db executeUpdate:@"insert into t_queue_test (key, value) values \
                       (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), \
                       (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), \
                       (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?), (?, ?)",
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random()),
                       [self randomString], @(arc4random()), [self randomString], @(arc4random())];
        XCTAssertTrue(result, @"Should success to insert data.");
    }];
}

- (void)testQueueSelectAll {
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        KKResultSet *rs = [db executeQuery:@"select * from t_queue_test"];
        XCTAssertNotNil(rs, @"Should have a non-nil result set");
        while ([rs next]) {
            NSLog(@">>>>>> %@", rs.resultDictionary);
            XCTAssertNotNil(rs.resultDictionary, @"Should have a non-nil result set");
        }
        [rs close];
        XCTAssertFalse([db hasOpenResultSets], @"Shouldn't have any open result sets");
    }];
}

- (void)testQueueTransactionCommit {
    __block int beforeRowCount = -1;
    __block int afterRowCount = -1;
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        KKResultSet *rs = [db executeQuery:@"select count(*) cnt from t_queue_test"];
        while ([rs next]) {
            NSLog(@">>>>>> %@", rs.resultDictionary);
            beforeRowCount = [rs intForColumn:@"cnt"];
        }
        [rs close];
        XCTAssertFalse([db hasOpenResultSets], @"Shouldn't have any open result sets");
    }];
    NSLog(@">>>>>> Before transaction row count: %d", beforeRowCount);
    
    [self.dbQueue inTransaction:^(KKDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        int i = 0;
        BOOL result = false;
        while (i++ < 10000) {
            NSString *key = [self randomString];
            NSNumber *value = @(arc4random());
            result = [db executeUpdate:@"insert into t_queue_test (key, value) values (?, ?)", key, value];
            XCTAssertTrue(result, @"Should success to insert data.");
        }
        // 提交事务
        *rollback = NO;
    }];
    
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        KKResultSet *rs = [db executeQuery:@"select count(*) cnt from t_queue_test"];
        while ([rs next]) {
            NSLog(@">>>>>> %@", rs.resultDictionary);
            afterRowCount = [rs intForColumn:@"cnt"];
        }
        [rs close];
        XCTAssertFalse([db hasOpenResultSets], @"Shouldn't have any open result sets");
    }];
    NSLog(@">>>>>> After transaction row count: %d", afterRowCount);
    
    XCTAssertEqual(beforeRowCount + 10000, afterRowCount, @"Should insert 10000 records in transaction.");
}

- (void)testQueueTransactionRollback {
    __block int beforeRowCount = -1;
    __block int afterRowCount = -1;
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        KKResultSet *rs = [db executeQuery:@"select count(*) cnt from t_queue_test"];
        while ([rs next]) {
            NSLog(@">>>>>> %@", rs.resultDictionary);
            beforeRowCount = [rs intForColumn:@"cnt"];
        }
        [rs close];
        XCTAssertFalse([db hasOpenResultSets], @"Shouldn't have any open result sets");
    }];
    NSLog(@">>>>>> Before transaction row count: %d", beforeRowCount);
    
    [self.dbQueue inTransaction:^(KKDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        int i = 0;
        BOOL result = false;
        while (i++ < 10000) {
            NSString *key = [self randomString];
            NSNumber *value = @(arc4random());
            result = [db executeUpdate:@"insert into t_queue_test (key, value) values (?, ?)", key, value];
            XCTAssertTrue(result, @"Should success to insert data.");
        }
        // 回滚事务
        *rollback = YES;
    }];
    
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        KKResultSet *rs = [db executeQuery:@"select count(*) cnt from t_queue_test"];
        while ([rs next]) {
            NSLog(@">>>>>> %@", rs.resultDictionary);
            afterRowCount = [rs intForColumn:@"cnt"];
        }
        [rs close];
        XCTAssertFalse([db hasOpenResultSets], @"Shouldn't have any open result sets");
    }];
    NSLog(@">>>>>> After transaction row count: %d", afterRowCount);
    
    XCTAssertEqual(beforeRowCount, afterRowCount, @"Should not insert any records in transaction.");
}

- (void)testClose {
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        KKResultSet *rs = [db executeQuery:@"select count(*) cnt from t_queue_test"];
        while ([rs next]) {
            NSLog(@">>>>>> count: %d", [rs intForColumn:@"cnt"]);
        }
        [rs close];
        XCTAssertFalse([db hasOpenResultSets], @"Shouldn't have any open result sets");
        
        BOOL success = [db close];
        XCTAssertTrue(success, @"Should close database success.");
    }];
    
    [self.dbQueue inDatabase:^(KKDatabase * _Nonnull db) {
        KKResultSet *rs = [db executeQuery:@"select count(*) cnt from t_queue_test where value > ?", @(3290020865)];
        while ([rs next]) {
            NSLog(@">>>>>> count: %d", [rs intForColumn:@"cnt"]);
        }
        [rs close];
        XCTAssertFalse([db hasOpenResultSets], @"Shouldn't have any open result sets");
        
        BOOL success = [db close];
        XCTAssertTrue(success, @"Should close database success.");
    }];
    
    
}

- (NSString *)randomString {
    int length = (int)(arc4random_uniform(128) + 1);
    return [self randomStringWith:length];
}

- (NSString *)randomStringWith:(int)length {
    if (length <= 0) {
        return nil;
    }
    NSString * strAll = @"#$&%0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    NSMutableString * result = [NSMutableString stringWithCapacity:length];
    for (int i = 0; i < length; i++) {
        NSInteger index = arc4random() % (strAll.length-1);
        char tempStr = [strAll characterAtIndex:index];
        [result appendFormat:@"%c", tempStr];
    }
    
    return [result copy];
}




//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
