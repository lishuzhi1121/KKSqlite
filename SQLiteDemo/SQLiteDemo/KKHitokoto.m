//
//  KKHitokoto.m
//  SQLiteDemo
//
//  Created by Sands on 2023/4/27.
//

#import "KKHitokoto.h"

@implementation KKHitokoto

+ (instancetype)hitokotoWithDict:(NSDictionary *)dict {
    KKHitokoto *instance = [[KKHitokoto alloc] init];
    [instance setValuesForKeysWithDictionary:dict];
    return instance;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.ID = [value integerValue];
    } else if ([key isEqualToString:@"from_who"]) {
        self.fromWho = value;
    } else if ([key isEqualToString:@"creator_uid"]) {
        self.creatorUid = [value integerValue];
    } else if ([key isEqualToString:@"commit_from"]) {
        self.commitFrom = value;
    } else if ([key isEqualToString:@"created_at"]) {
        self.createdAt = value;
    } else {
        NSLog(@"==== UndefinedKey: %@ Value: %@", key, value);
    }
}

#pragma mark - 用于集合去重

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else {
        return [[(KKHitokoto *)other uuid] isEqualToString:self.uuid];
    }
}

- (NSUInteger)hash
{
    return self.ID ^ self.uuid.hash;
}


@end
