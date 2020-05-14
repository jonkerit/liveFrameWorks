//
//  BJLIcLoadingBaseView.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/6.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcLoadingBaseView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLoadingBaseView ()

@property (nonatomic, readwrite) BJLIcLoadingState progressState;
@property (nonatomic, readwrite) CGFloat currentProgress;
@property (nonatomic) CGFloat increment;
@property (nonatomic, nullable) NSTimer *timer;
@property (nonatomic) BOOL isFailed;

@end

@implementation BJLIcLoadingBaseView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.currentProgress = 0.0;
        self.progressState = BJLIcLoadingStateInitial;
        [self makeObservingForState];
    }
    return self;
}

- (void)dealloc {
    [self stopTimer];
}

- (void)updateProgress:(CGFloat)progress {
    if (fabs(progress - 0.0) < 0.01 ) {
        // 重新加载
        [self resume];
    }
    else if (progress < 0.0) {
        // 失败, 等待动画结束再改变状态
        self.isFailed = YES;
    }
    else {
        // 成功或者加载中, 不立即改变状态
        [self stopTimer];
        CGFloat maximum = MIN(progress, 1.0);
        CGFloat increment = (maximum - self.currentProgress) / 200;
        [self startTimerWithIncrement:increment maximum:maximum];
    }
}

- (void)resume {
    [self stopTimer];
    self.isFailed = NO;
    self.currentProgress = 0.0;
    self.increment = 0.0;
    self.progressState = BJLIcLoadingStateInitial;
}

// 更新状态
- (void)makeObservingForState {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self, currentProgress)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.currentProgress > 0.0 && self.currentProgress < 1.0) {
                 self.progressState = BJLIcLoadingStateRunning;
             }
             else if (self.currentProgress >= 1.0) {
                 [self stopTimer];
                 self.progressState = BJLIcLoadingStateSuccess;
             }
             else if (self.currentProgress < 0.0) {
                 [self stopTimer];
                 self.progressState = BJLIcLoadingStateFailed;
             }
             return YES;
         }];
}

#pragma mark - timer

- (void)startTimerWithIncrement:(CGFloat)increment maximum:(CGFloat)maximum {
    [self stopTimer];
    bjl_weakify(self);
    self.timer = [NSTimer bjl_scheduledTimerWithTimeInterval:0.005 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        self.increment += increment;
        CGFloat progress = self.currentProgress + self.increment;
        if (self.increment >= 0.01 || progress >= maximum) {
            self.increment = 0.0;
            self.currentProgress = MIN(progress, maximum);
            if (self.isFailed && (progress >= maximum)) {
                [self stopTimer];
                self.progressState = BJLIcLoadingStateFailed;
            }
        }
    }];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

@end

NS_ASSUME_NONNULL_END
