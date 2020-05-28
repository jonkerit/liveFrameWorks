//
//  BJLScCountDownViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>
#import "BJLScWindowViewController+protected.h"

#import "BJLScCountDownViewController.h"
#import "BJLScAppearance.h"

#define hightCountDownTime 60
#define defaultCountDownTime 300


@interface BJLScCountDownViewController () <UITextFieldDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic, readwrite) BOOL isDecrease;

@property (nonatomic) NSTimer *countDownTimer;

@property (nonatomic, readwrite) NSInteger originCountDownTime;// 初始计时值
@property (nonatomic, readwrite) NSInteger currentCountDownTime;// 正、到计时的数值

// 初始倒计时时间为1分钟及以上时, 倒计时从1分钟开始要变色, 否则不变色.
@property (nonatomic) BOOL isStartTimeShouldHighlight;

@property (nonatomic) UIView *middleView;
@property (nonatomic) UIImageView *timerIcon;
@property (nonatomic) UILabel *timeLabel;

@end

@implementation BJLScCountDownViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                   totalTime:(NSInteger)time
        currentCountDownTime:(NSInteger)currentCountDownTime
                  isDecrease:(BOOL)isDecrease {
    self = [super init];
    if (self) {
        self->_room = room;
        self.isDecrease = isDecrease;
        self.originCountDownTime = time;
        self.currentCountDownTime = isDecrease ? currentCountDownTime : MAX(0, (time - currentCountDownTime));
        self.isStartTimeShouldHighlight = (time >= hightCountDownTime);
        [self prepareToOpen];
    }
    return self;
}

- (void)prepareToOpen {
    self.fixedAspectRatio = 2/1;
    self.minWindowHeight = 45.0f;
    self.minWindowWidth = 135.0f;

    CGFloat relativeWidth = 0.01f ;
    CGFloat relativeHeight = 0.01f;
    self.relativeRect = [self rectInBounds:CGRectMake(0, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
}

- (void)dealloc {
    [self stopCountDownTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.cornerRadius = 8.0;
    self.view.layer.masksToBounds = YES;

    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.doubleTapToMaximize = NO;
    self.closeButtonHidden = YES;
    self.bottomBar.hidden = YES;
    self.topBar.hidden = YES;
    self.panToResize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.topBarBackgroundViewHidden = YES;

    [self makeSubviews];
    [self makeObeserving];
}

- (void)makeSubviews {
    self.middleView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, middleView);
        view.backgroundColor = [UIColor bjl_colorWithHex:0x1795FF];
        bjl_return view;
    });
    
    self.timerIcon =({
        UIImageView *view = [UIImageView new];
        view.accessibilityLabel = BJLKeypath(self, timerIcon);
        [view setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_timer_icon"]];
        bjl_return view;
    });
    
    self.timeLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, timeLabel);
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:26];
        label.textAlignment = NSTextAlignmentCenter;
        bjl_return label;
    });

    [self.middleView addSubview:self.timerIcon];
    [self.middleView addSubview:self.timeLabel];
    [self.timerIcon bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.middleView);
        make.left.equalTo(self.middleView).offset(13);
        make.width.height.equalTo(@(32.0));
    }];
    [self.timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.middleView);
        make.left.equalTo(self.timerIcon.bjl_right).offset(8);
        make.right.lessThanOrEqualTo(self.middleView);
    }];

    [self initialCountDownTime];
    [self startCountDownTimer];
    [self setContentViewController:nil contentView:self.middleView];
}

- (void)makeObeserving {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveTimerWithTotalTime:countDownTime:isDecrease:) observer:(BJLMethodObserver)^BOOL(NSInteger totalTime, NSInteger countDownTime, BOOL isDecrease) {
        bjl_strongify(self);
        self.currentCountDownTime = isDecrease ? countDownTime : MAX(0, (totalTime - countDownTime));
        self.originCountDownTime = totalTime;
        self.isDecrease = isDecrease;
        
        [self startCountDownTimer];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceivePauseTimer) observer:^BOOL{
        bjl_strongify(self);
        [self pauseCountDownTimer];
        return YES;
    }];
}

- (void)initialCountDownTime {
    [self updateShowTimeColor];
    [self updateShowTime];
}

#pragma mark - override

- (void)close {
    if (self.closeCallback) {
        self.closeCallback();
    }
}

- (void)closeWithoutRequest {
    [self stopCountDownTimer];
    [super closeWithoutRequest];
}

#pragma mark - timer

- (void)stopCountDownTimer {
    if (self.countDownTimer || [self.countDownTimer isValid]) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

- (void)pauseCountDownTimer {
    [self stopCountDownTimer];
}

- (void)startCountDownTimer {
    [self stopCountDownTimer];
    
    bjl_weakify(self);
    self.countDownTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }

        // 倒计时结束
        if ((self.currentCountDownTime <= 0 && self.isDecrease) || (self.currentCountDownTime >= self.originCountDownTime && !self.isDecrease)) {
            [timer invalidate];
            self.isStartTimeShouldHighlight = NO;
            [self initialCountDownTime];
            // 计时结束时,更新到高亮状态
            self.middleView.backgroundColor = [UIColor bjl_colorWithHex:0xFF1F49 alpha:0.8];
            return;
        }
        
        if (self.isDecrease) {
            self.currentCountDownTime --;
        }
        else {
            self.currentCountDownTime ++;
        }

        [self updateShowTimeColor];
        [self updateShowTime];

    }];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
}

- (void)updateShowTimeColor {
    BOOL shouldHight = (((self.currentCountDownTime <= hightCountDownTime && self.isDecrease)
                         || (self.originCountDownTime - self.currentCountDownTime <= hightCountDownTime && !self.isDecrease))
                        && self.isStartTimeShouldHighlight);

    UIColor *backgroundColor = shouldHight ? [UIColor bjl_colorWithHex:0xFF1F49 alpha:0.8] : [UIColor bjl_colorWithHex:0x1795FF];
    self.middleView.backgroundColor = backgroundColor;
}

- (void)updateShowTime {
    NSInteger minute = self.currentCountDownTime / 60;
    NSInteger second = self.currentCountDownTime % 60;
    NSString *minuteString = (minute < 10) ? [NSString stringWithFormat:@"%02td", minute] : [NSString stringWithFormat:@"%td", minute];
    NSString *secondString = (second < 10) ? [NSString stringWithFormat:@"%02td", second] : [NSString stringWithFormat:@"%td", second];

    self.timeLabel.text = [NSString stringWithFormat:@"%@:%@", minuteString, secondString];
}

@end
