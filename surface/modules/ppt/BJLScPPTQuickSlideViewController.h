//
//  BJLScPPTQuickSlideViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScPPTQuickSlideViewController : UIViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

@property (nonatomic, nullable) void (^selectPPTCallback)(void);

@end

NS_ASSUME_NONNULL_END
