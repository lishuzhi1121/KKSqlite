//
//  KKHitokoto.h
//  SQLiteDemo
//
//  Created by Sands on 2023/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKHitokoto : NSObject

@property (nonatomic, assign) NSInteger ID;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *hitokoto;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *from;
@property (nonatomic, copy) NSString *fromWho;
@property (nonatomic, copy) NSString *creator;
@property (nonatomic, assign) NSInteger creatorUid;
@property (nonatomic, assign) NSInteger reviewer;
@property (nonatomic, copy) NSString *commitFrom;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, assign) NSInteger length;

+ (instancetype)hitokotoWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
