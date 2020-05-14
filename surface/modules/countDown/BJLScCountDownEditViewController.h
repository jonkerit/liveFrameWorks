//
//  BJLScCountDownEditViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/3/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

/** 老师编辑计时器页面 */
@interface BJLScCountDownEditViewController : UIViewController

@property (nonatomic, copy, nullable) void (^closeCallback)(void);

- (instancetype)initWithRoom:(BJLRoom *)room
                   totalTime:(NSInteger)time
        currentCountDownTime:(NSInteger)currentCountDownTime
                  isDecrease:(BOOL)isDecrease;

@end

NS_ASSUME_NONNULL_END
