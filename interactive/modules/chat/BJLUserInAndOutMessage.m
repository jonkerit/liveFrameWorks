//
//  BJLUserInAndOutMessage.m
//  BJLiveUI
//
//  Created by fanyi on 2019/9/11.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLUserInAndOutMessage.h"

@interface BJLUserInAndOutMessage ()

@property (nonatomic, readwrite) NSTimeInterval timeInterval;
@property (nonatomic, readwrite) BJLUser *fromUser;
@property (nonatomic, readwrite) BOOL isUserIn;

@end

@implementation BJLUserInAndOutMessage

- (instancetype)initWithUserIn:(nullable BJLUser *)user {
    if (!user) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.isUserIn = YES;
        self.fromUser = user;
        self.timeInterval = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (instancetype)initWithUserOut:(nullable BJLUser *)user {
    if (!user) {
        return nil;
    }

    self = [super init];
    if (self) {
        self.isUserIn = NO;
        self.fromUser = user;
        self.timeInterval = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

#pragma mark - <YYModel>

- (void)encodeWithCoder:(NSCoder *)aCoder { [self bjlyy_modelEncodeWithCoder:aCoder]; }
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder { self = [super init]; return [self bjlyy_modelInitWithCoder:aDecoder]; }
- (id)copyWithZone:(nullable NSZone *)zone { return [self bjlyy_modelCopy]; }
- (NSUInteger)hash { return [self bjlyy_modelHash]; }
- (BOOL)isEqual:(id)object { return [self bjlyy_modelIsEqual:object]; }


@end
