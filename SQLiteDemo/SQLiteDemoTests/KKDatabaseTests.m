//
//  KKDatabaseTests.m
//  SQLiteDemoTests
//
//  Created by Sands on 2023/4/21.
//

#import <XCTest/XCTest.h>
#import "KKDatabase.h"
#import "KKResultSet.h"

@interface KKDatabaseTests : XCTestCase

@property (nonatomic, strong) KKDatabase *db;

@end

@implementation KKDatabaseTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *testDBPath = [documentDir stringByAppendingPathComponent:@"kkdb_test.sqlite"];
    NSLog(@">>>>>> %@", testDBPath);
    self.db = [KKDatabase databaseWithPath:testDBPath];
    XCTAssertTrue([self.db open], @"Error: Wasn't able to open database!!!");
    self.db.shouldCacheStatements = YES;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testConnection {
    XCTAssertTrue([self.db goodConnection], "Error: Wasn't able to connect database!!!");
}

- (void)testCreateTable {
    // create table
    BOOL result = [self.db executeUpdate:@"create table if not exists t_user ( \
                   id integer primary key autoincrement, \
                   name varchar(50), \
                   age int, \
                   birthday text, \
                   gender varchar(1), \
                   salary double,\
                   description text)"];
    XCTAssertTrue(result, @"Should success to create table.");
}

- (void)testInsert {
    // insert
    BOOL result = [self.db executeUpdate:@"insert into t_user (name, age, birthday, gender, salary, description) \
                   values (?, ?, ?, ?, ?, ?), (?, ?, ?, ?, ?, ?)",
                   @"Sands", @(28), @"1992-11-21", @"男", @(9999.99), @"He is a boy !!（有趣的灵魂，万里挑一！）",
                   @"Asahi", @(38), @"1982-02-14", @"女", @(999.99), @"She is a girl !!（好看的皮囊，千篇一律！）"];
    XCTAssertTrue(result, @"Should success to insert data.");
}

- (void)testUpdate {
    // insert
    BOOL result = [self.db executeUpdate:@"update t_user set age = ? where id = ?", @(18), @(1)];
    XCTAssertTrue(result, @"Should success to update data.");
}

- (void)testDelete {
    // insert
    BOOL result = [self.db executeUpdate:@"delete from t_user where id = ?", @(2)];
    XCTAssertTrue(result, @"Should success to delete data.");
}

- (void)testSelectCount {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    KKResultSet *rs = [self.db executeQuery:@"select count(*) cc from t_user"];
    XCTAssertNotNil(rs, @"Should have a non-nil result set");
    while ([rs next]) {
        NSLog(@">>>>>> %@", rs.resultDictionary);
        XCTAssertNotNil(rs.resultDictionary, @"Should have a non-nil result set");
    }
    [rs close];
    XCTAssertFalse([self.db hasOpenResultSets], @"Shouldn't have any open result sets");
}

- (void)testSelectAll {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    KKResultSet *rs = [self.db executeQuery:@"select * from t_user"];
    XCTAssertNotNil(rs, @"Should have a non-nil result set");
    while ([rs next]) {
        NSLog(@">>>>>> %@", rs.resultDictionary);
        XCTAssertNotNil(rs.resultDictionary, @"Should have a non-nil result set");
    }
    [rs close];
    XCTAssertFalse([self.db hasOpenResultSets], @"Shouldn't have any open result sets");
}

- (void)testSelectColumn {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    KKResultSet *rs = [self.db executeQuery:@"select id, name, age, description from t_user"];
    XCTAssertNotNil(rs, @"Should have a non-nil result set");
    while ([rs next]) {
        NSLog(@">>>>>> %@", rs.resultDictionary);
        XCTAssertNotNil(rs.resultDictionary, @"Should have a non-nil result set");
    }
    [rs close];
    XCTAssertFalse([self.db hasOpenResultSets], @"Shouldn't have any open result sets");
}

- (void)testSelectValueForColumn {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    KKResultSet *rs = [self.db executeQuery:@"select id, name, age, description from t_user"];
    XCTAssertNotNil(rs, @"Should have a non-nil result set");
    while ([rs next]) {
        NSLog(@">>>>>> id: %d name: %@ age: %d desc: %@", [rs intForColumn:@"id"], [rs stringForColumn:@"name"], [rs intForColumn:@"age"], [rs stringForColumn:@"description"]);
        XCTAssertNotNil(rs.resultDictionary, @"Should have a non-nil result set");
    }
    [rs close];
    XCTAssertFalse([self.db hasOpenResultSets], @"Shouldn't have any open result sets");
}

#pragma mark - 测试批量执行SQL
- (void)testExecuteStatements {
    NSString *sql = @"select count(*) cc from t_user;"
                     "select id, name, age from t_user;"
                     "select * from t_user;";
    [self.db executeStatements:sql withResultBlock:^int(NSDictionary * _Nonnull resultsDictionary) {
        NSLog(@">>>>>> %@", resultsDictionary);
        XCTAssertNotNil(resultsDictionary, @"Should have a non-nil result set");
        return 0;
    }];
}

#pragma mark - 测试事务

- (void)testTransaction {
    // create table
    BOOL result = [self.db executeUpdate:@"create table if not exists t_transaction_test (id integer primary key autoincrement, name varchar(50),age int)"];
    XCTAssertTrue(result, @"Should success to create table.");
    // begin transaction
    [self.db beginTransaction];
    int i = 0;
    while (i++ < 10000) {
        int len = (int)(arc4random_uniform(50) + 1);
        NSString *name = [self randomStringWith:len];
        NSNumber *age = [NSNumber numberWithInt:(int)(arc4random_uniform(100) + 1)];
        result = [self.db executeUpdate:@"insert into t_transaction_test (name, age) values (?, ?)", name, age];
        XCTAssertTrue(result, @"Should success to insert data.");
    }
    // commit transaction
    result = [self.db commit];
    XCTAssertTrue(result, @"Should success to commit transaction.");
}


#pragma mark - 测试关闭数据库

- (void)testClose {
    NSString *sql = @"select count(*) cc from t_user;"
                     "select id, name, age from t_user;"
                     "select * from t_user;";
    BOOL success = [self.db executeStatements:sql withResultBlock:^int(NSDictionary * _Nonnull resultsDictionary) {
        NSLog(@">>>>>> %@", resultsDictionary);
        XCTAssertNotNil(resultsDictionary, @"Should have a non-nil result set");
        return 0;
    }];
    XCTAssertTrue(success, @"Should excuteStatements success.");
    
    success = [self.db close];
    XCTAssertTrue(success, @"Should close database success.");
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


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
