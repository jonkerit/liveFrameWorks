//
//  BJLIcCountDownWindowViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/5/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

@class BJLRoom;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcCountDownWindowLayout) {
    BJLIcCountDownWindowLayout_normal,    // 学生端页面, 仅展示倒计时,无操作权限
    BJLIcCountDownWindowLayout_unpublish, // 未发布
    BJLIcCountDownWindowLayout_publish,   //已发布
};

@interface BJLIcCountDownWindowViewController : BJLIcWindowViewController

// publish 表示发布或者关闭
@property (nonatomic, nullable) BOOL (^publishCountDownTimerCallback)(NSTimeInterval time, BOOL publish, BOOL close);
// 撤回
@property (nonatomic, nullable) BOOL (^revokeCountDownTimerCallback)(void);
// 右上脚关闭回调
@property (nonatomic, nullable) void (^closeCountDownTimerCallback)(void);
// 提示回调
@property (nonatomic, nullable) void (^errorCallback)(NSString *message);
// 有输入时的回调
@property (nonatomic, nullable) void (^keyboardFrameChangeCallback)(CGRect keyboardFrame);

- (instancetype)initWithRoom:(BJLRoom *)room
               countDownTime:(NSTimeInterval)time
                      layout:(BJLIcCountDownWindowLayout)layout;

- (instancetype)init NS_UNAVAILABLE;

// 关闭
- (void)closeCountDown;

- (void)hideKeyboardView;

@end

NS_ASSUME_NONNULL_END
