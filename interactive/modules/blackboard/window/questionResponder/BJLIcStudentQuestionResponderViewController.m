//
//  BJLIcStudentQuestionResponderViewController.m
//  BJLiveUI
//
//  Created by fanyi on 2019/5/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcStudentQuestionResponderViewController.h"
#import "BJLIcAppearance.h"

static const CGFloat BJLIcStudentQuestionRespondeButtonIpadWidth = 100.0f;

@interface BJLIcStudentQuestionResponderViewController ()
@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic) NSInteger countDownTime;
@property (nonatomic) NSTimer *countDowntimer;
@property (nonatomic) NSTimer *respoderTimer;

@property (nonatomic) UIView *countDownContainerView;
@property (nonatomic) UILabel *countDownLabel;
@property (nonatomic) UILabel *tipLabel;

@property (nonatomic) UIButton *responderButton;

@end

@implementation BJLIcStudentQuestionResponderViewController

- (instancetype)initWithRoom:(BJLRoom *)room
               countDownTime:(NSInteger)time {
    self = [super init];
    if (self) {
        self->_room = room;
        self.countDownTime = time;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    [self makeSubviews];
    [self makeObserving];
    [self updateCountDownView];
}

- (void)loadView {
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        if ([hitView isKindOfClass:[UIButton class]]) {
            return hitView;
        }
        return nil;
    }];
}

#pragma mark - private
- (void)makeSubviews {
    // countDownView
    self.countDownContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, countDownContainerView);
        [self.view addSubview:view];
        view.hidden = YES;
        bjl_return view;
    });
    
    self.countDownLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:140];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.accessibilityLabel = BJLKeypath(self, countDownLabel);
        [self.countDownContainerView addSubview:label];
        bjl_return label;
    });
    
    self.tipLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:20];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"倒计时结束开始抢答";
        label.accessibilityLabel = BJLKeypath(self, tipLabel);
        [self.countDownContainerView addSubview:label];
        bjl_return label;
    });
    [self.countDownContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    [self.countDownLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.countDownContainerView);
    }];
    [self.tipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.countDownContainerView);
        make.top.equalTo(self.countDownLabel.bjl_bottom).offset(10);
        make.left.greaterThanOrEqualTo(self.countDownContainerView).offset(10);
        make.right.lessThanOrEqualTo(self.countDownContainerView).offset(-10);
    }];

    /// reaponderButton
    self.responderButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, responderButton);
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionResponder_normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_questionResponder_highlight"] forState:UIControlStateHighlighted];
        button.hidden = YES;
        [button addTarget:self action:@selector(responderAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        bjl_return button;
    });
}

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeQuestionResponder) observer:^BOOL{
        bjl_strongify(self);
        [self stopCountDownTimer];
        [self stopResponderTimer];
        
        self.countDownContainerView.hidden = YES;
        self.responderButton.hidden = YES;
        
        if (self.errorCallback) {
            self.errorCallback(@"抢答已取消");
        }
        
        [self hide];
        return NO;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveEndQuestionResponderWithWinner:) observer:^BOOL(BJLUser *user){
        bjl_strongify(self);
        [self stopCountDownTimer];
        [self stopResponderTimer];
        
        self.countDownContainerView.hidden = YES;
        self.responderButton.userInteractionEnabled = NO;

        if (!user) {
            if (self.errorCallback) {
                self.errorCallback(@"无人抢中");
            }
            [self hide];
            return NO;
        }
        
        if (!self.responderButton.isHidden && [self.room.loginUser.ID isEqualToString:user.ID]) {
            if (user) {
                self.responderSuccessCallback(user, self.responderButton);
            }

            [self.responderButton setImage:[UIImage bjlic_imageNamed:@"bjl_questionResponder_success"] forState:UIControlStateNormal];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self hide];
            });
        }
        else if (!self.responderButton.isHidden && ![self.room.loginUser.ID isEqualToString:user.ID]){
            if (user) {
                self.responderSuccessCallback(user, self.responderButton);
            }

            [self.responderButton setImage:[UIImage bjlic_imageNamed:@"bjl_questionResponder_failed"] forState:UIControlStateNormal];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self hide];
            });
        }
        return NO;
    }];
}

- (void)updateCountDownView {
    self.countDownContainerView.hidden = (self.countDownTime <= 0);
    self.responderButton.hidden = (self.countDownTime > 0);
    
    if (self.countDownTime > 0) {
        [self startCountTimer];
    }
    else {
        [self startResponderTimer];
    }
}

- (void)startCountTimer {
    [self stopCountDownTimer];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 20;
    shadow.shadowColor = [UIColor bjl_colorWithHex:0XF8E71C];
    shadow.shadowOffset = CGSizeMake(0, 0);
    self.countDownLabel.attributedText = [[NSAttributedString alloc]
                                          initWithString:[NSString stringWithFormat:@"%td",self.countDownTime]
                                          attributes:@{ NSFontAttributeName:
                                                            [UIFont systemFontOfSize:140],
                                                        NSForegroundColorAttributeName:
                                                            [UIColor whiteColor], NSShadowAttributeName:shadow}];
    self.countDownTime --;

    bjl_weakify(self);
    self.countDowntimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self || ![self.countDowntimer isValid] || !self.countDowntimer) {
            [timer invalidate];
            return;
        }
        
        // 倒计时结束
        if (self.countDownTime <= 0) {
            [timer invalidate];
            // 出现按钮
            [self updateCountDownView];
            return;
        }
        
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 20;
        shadow.shadowColor = [UIColor bjl_colorWithHex:0XF8E71C];
        shadow.shadowOffset = CGSizeMake(0, 0);
         self.countDownLabel.attributedText = [[NSAttributedString alloc]
                                           initWithString:[NSString stringWithFormat:@"%td",self.countDownTime]
                                           attributes:@{ NSFontAttributeName:
                                                             [UIFont systemFontOfSize:140],
                                                         NSForegroundColorAttributeName:
                                                             [UIColor whiteColor], NSShadowAttributeName:shadow}];
        self.countDownTime --;
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.countDowntimer forMode:NSRunLoopCommonModes];
}

// 销毁倒计时
- (void)stopCountDownTimer {
    if (self.countDowntimer || [self.countDowntimer isValid]) {
        [self.countDowntimer invalidate];
        self.countDowntimer = nil;
    }
}

- (void)startResponderTimer {
    [self stopResponderTimer];
    [self updateResponderFrame];

    bjl_weakify(self);
    self.respoderTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self || ![self.respoderTimer isValid] || !self.respoderTimer) {
            [timer invalidate];
            return;
        }
        
        [self updateResponderFrame];
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.respoderTimer forMode:NSRunLoopCommonModes];
}

// 销毁倒计时
- (void)stopResponderTimer {
    if (self.respoderTimer || [self.respoderTimer isValid]) {
        [self.respoderTimer invalidate];
        self.respoderTimer = nil;
    }
}

- (void)updateResponderFrame {
    CGFloat width = BJLIcStudentQuestionRespondeButtonIpadWidth;
    
    int x = MIN(arc4random() % (int)self.view.frame.size.width, MAX((self.view.frame.size.width - width), 0));
    int y = MIN(arc4random() % (int)self.view.frame.size.height, MAX((self.view.frame.size.height - width), 0));
    CGRect labelFrame= CGRectMake(x, y, width, width);
    self.responderButton.frame = labelFrame;
}

- (void)responderAction {
    if (self.responderCallback) {
        if (self.responderCallback()) {
//            表示提交request成功
            [self stopCountDownTimer];
            [self stopResponderTimer];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self hide];
            });
        }
    }
}

- (void)hide {
    [self stopCountDownTimer];
    [self stopResponderTimer];
    
    [self bjl_removeFromParentViewControllerAndSuperiew];
    
    if (self.hiddenCallback) {
        self.hiddenCallback();
    }
}

@end
