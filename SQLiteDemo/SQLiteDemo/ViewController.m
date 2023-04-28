//
//  ViewController.m
//  SQLiteDemo
//
//  Created by Sands on 2023/4/18.
//

#import "ViewController.h"
#import <FMDB/FMDB.h>
#import "KKDatabase.h"

@interface ViewController ()
@property (nonatomic, strong) KKDatabase *kkdb;
@property (nonatomic, strong) FMDatabase *fmdb;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//    NSString *kkTestDBPath = [documentDir stringByAppendingPathComponent:@"kkdb_test.db"];
//    NSLog(@">>>>>> %@", kkTestDBPath);
//    self.kkdb = [KKDatabase databaseWithPath:kkTestDBPath];
//    self.kkdb.shouldCacheStatements = YES;
//    [self.kkdb open];
//    
//    [self createTable];
}

- (void)createTable {
    // create table
    NSString *createSql = @"create table if not exists t_test (name text, age integer)";
    BOOL result = [self.kkdb executeUpdate:createSql];
    NSLog(@"%@ 创建表: %@", self.kkdb, result ? @"成功！" : @"失败！");
}

- (void)insertData {
    // insert
    BOOL result = [self.kkdb executeUpdate:@"insert into t_test values (?, ?)", @"Sands", @28];
    NSLog(@"%@ 插入数据: %@", self.kkdb, result ? @"成功！" : @"失败！");
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self insertData];
}

@end
