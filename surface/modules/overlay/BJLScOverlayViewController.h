//
//  BJLScOverlayViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScOverlayViewController : UIViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

// equal to bjl_addChildViewController:superview:, 具体布局需要在外部处理
- (void)showWithContentViewController:(nullable UIViewController *)viewController contentView:(nullable UIView *)view;

- (void)hide;

@property (nonatomic, nullable) void (^showCallback)(void);

@end

NS_ASSUME_NONNULL_END
