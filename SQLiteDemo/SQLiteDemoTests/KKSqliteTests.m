//
//  KKSqliteTests.m
//  SQLiteDemoTests
//
//  Created by Sands on 2023/4/21.
//

#import <XCTest/XCTest.h>
#import "KKSqlite.h"
#import "KKHitokoto.h"

static int count = 0;

@interface KKSqliteTests : XCTestCase

@property (nonatomic, strong) KKSqlite *kkdb;
@property (nonatomic, strong) NSMutableSet<KKHitokoto *> *hitokotos;

@end

@implementation KKSqliteTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *testDBPath = [documentDir stringByAppendingPathComponent:@"kksqlite_test.db"];
    NSLog(@">>>>>> %@", testDBPath);
    self.kkdb = [KKSqlite instanceWithFilePath:testDBPath];
    [self.kkdb setDateFormatterWithString:@"yyyy-MM-dd HH:mm:ss"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDropTable {
    BOOL success = [self.kkdb dropTable:@"t_hitokoto"];
    XCTAssertTrue(success, @"Should drop table success.");
}

- (void)testCreateHitokotoTable {
    BOOL success = [self.kkdb createTable:@"t_hitokoto" columns:@[
        @{@"id": @"integer primary key autoincrement not null"},
        @{@"uuid": @"varchar(64) not null unique"},
        @{@"hitokoto": @"text"},
        @{@"type": @"varchar(4)"},
        @{@"from_who": @"text"},
        @{@"creator": @"text"},
        @{@"created_at": @"text"},
        @{@"length": @"integer"}]];
    XCTAssertTrue(success, @"Should create table success.");
}

- (void)testCreateTable {
    BOOL success = [self.kkdb createTable:@"t_kksqlite" columns:@[
        @{@"id": @"integer primary key autoincrement not null"},
        @{@"name": @"varchar(32) not null"},
        @{@"age": @"tinyint"},
        @{@"gender": @"varchar(1)"},
        @{@"birthday": @"date"},
        @{@"salary": @"double"},
        @{@"info": @"text"},
        @{@"other": @"blob"}]];
    XCTAssertTrue(success, @"Should create table success.");
}

- (void)testSelectAll {
    NSArray *rs = [self.kkdb selectFromTable:@"t_kksqlite" columns:nil];
    NSLog(@"%@", rs);
    XCTAssertNotNil(rs, @"Should not nil.");
}

- (void)testSelect {
    NSArray *rs = [self.kkdb selectFromTable:@"t_hitokoto"
                                     columns:nil
                                  conditions:@[@"length > 20"]
                                      groups:@[@"type"]
                                      orders:@{@"created_at": @"desc"}
                                   pageStart:0
                                    pageSize:100];
    NSLog(@"%@", rs);
    XCTAssertNotNil(rs, @"Should not nil.");
}

- (void)testInsertNoColumn {
    BOOL success = [self.kkdb insertIntoTable:@"t_kksqlite" columns:nil values:@[
        @[@1, @"key1", @"value1"],
        @[@2, @"key2", @"value2"],
        @[@3, @"key3", @"value3"],
    ]];
    XCTAssertTrue(success, @"Should insert data success.");
}

- (void)testInsertWithColumns {
    BOOL success = [self.kkdb insertIntoTable:@"t_kksqlite" columns:@[@"key", @"value"] values:@[
        @[@"key4", @"value4"],
        @[@"key5", @"value5"],
        @[@"key6", @(6)],
    ]];
    XCTAssertTrue(success, @"Should insert data success.");
}

- (void)testInsertWithSomeColumns {
    BOOL success = [self.kkdb insertIntoTable:@"t_kksqlite" columns:@[@"value"] values:@[
        @[@"value7"],
        @[@"value8"],
        @[@(9)],
    ]];
    XCTAssertTrue(success, @"Should insert data success.");
}

- (void)testInsertWithSomeKeys {
    BOOL success = [self.kkdb insertIntoTable:@"t_kksqlite" columns:@[@"key"] values:@[
        @[@"key10"],
        @[@"key11"],
        @[@(12.12)],
    ]];
    XCTAssertTrue(success, @"Should insert data success.");
}

- (void)testInsertDate {
    BOOL success = [self.kkdb insertIntoTable:@"t_kksqlite" columns:@[@"key", @"value"] values:@[
        @[@"key13", [NSDate date]],
        @[@"key14", [NSDate dateWithTimeIntervalSinceNow:60*60*24*3]],
        @[@"key15", [self dateFromString:@"2023-04-23 14:36:47"]]
    ]];
    XCTAssertTrue(success, @"Should insert data success.");
}

- (NSDate *)dateFromString:(NSString *)fmtString {
//    NSLog(@"%@", NSTimeZone.knownTimeZoneNames);
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    NSLog(@"%@", [fmt stringFromDate:[NSDate date]]);
    
    return [fmt dateFromString:fmtString];
}

- (void)testDeleteByKey {
    BOOL success = [self.kkdb deleteFromTable:@"t_kksqlite" withColumn:@"id" inArray:@[@10, @11, @12]];
    XCTAssertTrue(success, @"Should delete data success.");
}

- (void)testDeleteByNullCondition {
    BOOL success = [self.kkdb deleteFromTable:@"t_kksqlite" conditions:@[@"key is null"]];
    XCTAssertTrue(success, @"Should delete data success.");
}

- (void)testDeleteByLikeCondition {
    BOOL success = [self.kkdb deleteFromTable:@"t_kksqlite" conditions:@[@"value like 'value%'"]];
    XCTAssertTrue(success, @"Should delete data success.");
}

- (void)testUpdateAll {
    BOOL success = [self.kkdb updateToTable:@"t_kksqlite" changes:@{@"value": [NSDate date]} conditions:nil];
    XCTAssertTrue(success, @"Should update data success.");
}

- (void)testUpdateByCondition {
    BOOL success = [self.kkdb updateToTable:@"t_kksqlite" changes:@{@"value": @9} conditions:@[@"id = 6"]];
    XCTAssertTrue(success, @"Should update data success.");
}

- (NSString *)random32String {
    int length = (int)(arc4random_uniform(32) + 1);
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

- (NSNumber *)randomOneToOneHundred {
    return [NSNumber numberWithInt:(int)(arc4random_uniform(100) + 1)];
}

- (NSString *)randomGender {
    int g = (int)(arc4random() % 3);
    switch (g) {
        case 0:
            return @"男";
            break;
        case 1:
            return @"女";
            break;
            
        default:
            return @"无";
            break;
    }
    return @"无";
}


/// yyyy-MM-dd
- (NSString *)randomDate {
    // yyyy
    int y = (int)(arc4random_uniform(223) + 1800);
    int m = (int)(arc4random_uniform(12) + 1);
    int d = (int)(arc4random_uniform(30) + 1);
    return [NSString stringWithFormat:@"%d-%d-%d", y, m, d];
}

/// 10923.528
- (NSNumber *)randomDouble {
    // (50000 - 100000) / 3
    return [NSNumber numberWithDouble:((double)(arc4random_uniform(50000) + 50000) / 3.0)];
}

- (void)testGetHitokoto {
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Oh, timeout!!!"];
    NSURL *url = [NSURL URLWithString:@"https://v1.hitokoto.cn"];
    [[[NSURLSession sharedSession] dataTaskWithURL:url
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        XCTAssertNil(error, "Error should be nil.");
        XCTAssertNotNil(data, "Data should not be nil.");
        NSDictionary *hitokotoDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        KKHitokoto *hitokoto = [KKHitokoto hitokotoWithDict:hitokotoDict];
        NSLog(@"---> %d %@", ++count, hitokoto.hitokoto);
        XCTAssertNotNil(hitokoto);
        
        [self.hitokotos addObject:hitokoto];
        
        [ex fulfill];
    }] resume];
    
    [self waitForExpectations:@[ex]];
    
    if (self.hitokotos.count > 100) {
        NSMutableArray *values = [NSMutableArray array];
        for (KKHitokoto *h in self.hitokotos) {
            [values addObject:@[h.uuid,
                                [self selfOrNull:h.hitokoto],
                                [self selfOrNull:h.type],
                                [self selfOrNull:h.fromWho],
                                [self selfOrNull:h.creator],
                                [self dateFromTimestamp:h.createdAt],
                                @(h.length)
                              ]];
        }
        BOOL success = [self.kkdb insertOrIgnoreIntoTable:@"t_hitokoto"
                                                  columns:@[@"uuid",
                                                            @"hitokoto",
                                                            @"type",
                                                            @"from_who",
                                                            @"creator",
                                                            @"created_at",
                                                            @"length"]
                                                   values:values];
        XCTAssertTrue(success, @"Should insert data success.");
    } else {
        [self testGetHitokoto];
    }
}

- (id)selfOrNull:(id)obj {
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj length] > 0 ? obj : [NSNull null];
    } else if (!obj) {
        return [NSNull null];
    }
    return obj;
}

- (NSDate *)dateFromTimestamp:(NSString *)timestamp {
    return [NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]];
}

- (NSMutableSet<KKHitokoto *> *)hitokotos {
    if (!_hitokotos) {
        _hitokotos = [NSMutableSet set];
    }
    
    return _hitokotos;
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
