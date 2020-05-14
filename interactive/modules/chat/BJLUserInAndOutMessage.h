//
//  BJLUserInAndOutMessage.h
//  BJLiveUI
//
//  Created by fanyi on 2019/9/11.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLUserInAndOutMessage : NSObject <BJLYYModel>

@property (nonatomic, readonly) NSTimeInterval timeInterval; // seconds since 1970
@property (nonatomic, readonly) BJLUser *fromUser;

@property (nonatomic, readonly) BOOL isUserIn;

- (instancetype)initWithUserIn:(nullable BJLUser *)user;
- (instancetype)initWithUserOut:(nullable BJLUser *)user;

@end

NS_ASSUME_NONNULL_END
