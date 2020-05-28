//
//  BJLScCountDownViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>
#import "BJLScWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

/** 三分屏悬浮组直播间的倒计时 */
@interface BJLScCountDownViewController : BJLScWindowViewController

@property (nonatomic, readonly) BOOL isDecrease;
@property (nonatomic, readonly) NSInteger originCountDownTime;
@property (nonatomic, readonly) NSInteger currentCountDownTime;

@property (nonatomic, copy, nullable) void (^closeCallback)(void);
@property (nonatomic, copy, nullable) BOOL (^publishCountDownTimerCallback)(NSInteger totalTime, NSInteger currentCountDownTime, BOOL isDecrease);
@property (nonatomic, copy, nullable) BOOL (^pauseCountDownTimerCallback)(void);

- (instancetype)initWithRoom:(BJLRoom *)room
                   totalTime:(NSInteger)time
        currentCountDownTime:(NSInteger)currentCountDownTime
                  isDecrease:(BOOL)isDecrease;


@end

NS_ASSUME_NONNULL_END
