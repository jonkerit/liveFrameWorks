//
//  BJLScGroupUserViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/11/11.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLTableViewController.h"
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScGroupUserViewController : BJLTableViewController

@property (nonatomic, copy, nullable) void (^userCountChangeCallback)(NSInteger totalCount);

@property (nonatomic, copy, nullable) void (^userSelectCallback)(__kindof BJLUser *user, CGPoint point);

- (instancetype)initWithRoom:(BJLRoom *)room;

@end

NS_ASSUME_NONNULL_END
