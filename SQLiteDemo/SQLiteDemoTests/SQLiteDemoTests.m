//
//  SQLiteDemoTests.m
//  SQLiteDemoTests
//
//  Created by Sands on 2023/4/18.
//

#import <XCTest/XCTest.h>
#import "KKHitokoto.h"

@interface SQLiteDemoTests : XCTestCase

@end

@implementation SQLiteDemoTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testHitokotoHash {
    NSMutableSet *hitokotos = [NSMutableSet set];
    KKHitokoto *tk1 = [KKHitokoto hitokotoWithDict:@{
        @"id": @6966,
        @"uuid": @"03e5936d-6d26-4394-9bcd-52de5a557c5d",
        @"hitokoto": @"要是心情郁闷的时候，用手托腮就好，手臂会因为帮上忙而开心的。",
        @"type": @"e",
        @"from": @"随感",
        @"from_who": @"Litten",
        @"creator": @"BlueHeart0621",
        @"creator_uid": @8312,
        @"reviewer": @1044,
        @"commit_from": @"web",
        @"created_at": @"1611458997",
        @"length": @30
        }];
    KKHitokoto *tk2 = [KKHitokoto hitokotoWithDict:@{
        @"id": @7332,
        @"uuid": @"84070447-4997-46c8-8194-061d3440adb2",
        @"hitokoto": @"为君沉醉又何妨，只怕酒醒时候断人肠。",
        @"type": @"i",
        @"from": @"虞美人",
        @"from_who": @"秦观",
        @"creator": @"主不在乎",
        @"creator_uid": @9074,
        @"reviewer": @4756,
        @"commit_from": @"web",
        @"created_at": @"1622290322",
        @"length": @18
        }];
    KKHitokoto *tk3 = [KKHitokoto hitokotoWithDict:@{
        @"id": @7415,
        @"uuid": @"d1761edd-bfa7-4335-95d7-7bb6e761ee29",
        @"hitokoto": @"这瓜多少钱一斤？",
        @"type": @"h",
        @"from": @"征服",
        @"from_who": @"刘华强",
        @"creator": @"jigeshuohua",
        @"creator_uid": @10371,
        @"reviewer": @1,
        @"commit_from": @"web",
        @"created_at": @"1632695247",
        @"length": @8
        }];
    KKHitokoto *tk4 = [KKHitokoto hitokotoWithDict:@{
        @"id": @7332,
        @"uuid": @"84070447-4997-46c8-8194-061d3440adb2",
        @"hitokoto": @"为君沉醉又何妨，只怕酒醒时候断人肠。",
        @"type": @"i",
        @"from": @"虞美人",
        @"from_who": @"秦观",
        @"creator": @"主不在乎",
        @"creator_uid": @9074,
        @"reviewer": @4756,
        @"commit_from": @"web",
        @"created_at": @"1622290322",
        @"length": @18
        }];
    [hitokotos addObjectsFromArray:@[tk1, tk2, tk3, tk4]];
    
    NSLog(@"===> %@", hitokotos);
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
