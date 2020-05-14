//
//  BJLScUserViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScUserViewController : BJLTableViewController

@property (nonatomic, copy, nullable) void (^userCountChangeCallback)(NSInteger totalCount);

@property (nonatomic, copy, nullable) void (^userSelectCallback)(__kindof BJLUser *user, CGPoint point);

- (instancetype)initWithRoom:(BJLRoom *)room;

@end

NS_ASSUME_NONNULL_END
