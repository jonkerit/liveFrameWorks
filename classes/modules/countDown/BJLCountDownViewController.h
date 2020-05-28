//
//  BJLCountDownViewController.h
//  BJLiveUI
//
//  Created by fanyi on 2019/9/11.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJLViewControllerImports.h"

@class BJLRoom;

NS_ASSUME_NONNULL_BEGIN

@interface BJLCountDownViewController : UIViewController

@property (nonatomic, copy, nullable) void (^closeCallback)(void);
@property (nonatomic, copy, nullable) void (^errorCallback)(NSString *);
@property (nonatomic, copy, nullable) BOOL (^publishCountDownTimerCallback)(NSInteger totalTime, NSInteger currentCountDownTime, BOOL isDecrease);
@property (nonatomic, copy, nullable) BOOL (^pauseCountDownTimerCallback)(void);

- (instancetype)initWithRoom:(BJLRoom *)room
                   totalTime:(NSInteger)time
        currentCountDownTime:(NSInteger)currentCountDownTime
                  isDecrease:(BOOL)isDecrease;

@end

NS_ASSUME_NONNULL_END
