//
//  BJLIcStatusBarViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcStatusBarViewController : UIViewController

/**
 退出教室
 */
@property (nonatomic, readonly) UIButton *exitButton;

@property (nonatomic, nullable) void (^showWeakNetworkTipCallback)(NSInteger duration);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
