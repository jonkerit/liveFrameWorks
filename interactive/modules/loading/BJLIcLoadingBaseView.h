//
//  BJLIcLoadingBaseView.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/6.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BJLIcLoadingState) {
    // 初始
    BJLIcLoadingStateInitial = 0,
    // 执行
    BJLIcLoadingStateRunning,
    // 完成
    BJLIcLoadingStateSuccess,
    // 失败
    BJLIcLoadingStateFailed,
};

static const CGFloat loadingBarHeight = 4.0;

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLoadingBaseView : UIView

/**
 当前进度条状态
 */
@property (nonatomic, readonly) BJLIcLoadingState progressState;

/**
 当前进度
 */
@property (nonatomic, readonly) CGFloat currentProgress;

/**
 更新进度

 @param progress [0.0 - 1.0) -> 加载中, >= 1.0 -> 成功, < 0.0 --> 失败
 */
- (void)updateProgress:(CGFloat)progress;

/**
 恢复
 */
- (void)resume;

@end

NS_ASSUME_NONNULL_END
