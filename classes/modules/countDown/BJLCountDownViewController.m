//
//  BJLCountDownViewController.m
//  BJLiveUI
//
//  Created by fanyi on 2019/9/11.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLCountDownViewController.h"
#import "BJLAppearance.h"

#define hightCountDownTime 60
#define defaultCountDownTime 300

@interface BJLCountDownViewController ()<UITextFieldDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic, readonly) BOOL isTeacher;
@property (nonatomic) BOOL isDecrease;

@property (nonatomic) NSTimer *countDownTimer;

@property (nonatomic) NSInteger originCountDownTime;// 初始计时值
@property (nonatomic) NSInteger currentCountDownTime;// 正、到计时的数值

// 初始倒计时时间为1分钟及以上时, 倒计时从1分钟开始要变色, 否则不变色.
@property (nonatomic) BOOL isStartTimeShouldHighlight;

@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *topBar;
@property (nonatomic) UILabel *titleLabel;

@property (nonatomic) UIView *containerView, *overlayView;
@property (nonatomic) UITextField *minusInTensDigitTextField;// 分钟的十位数字
@property (nonatomic) UITextField *minusInUnitsDigitTextField;// 分钟的个位数字
@property (nonatomic) UITextField *secondsInTensDigitTextField;// 秒的十位数字
@property (nonatomic) UITextField *secondsInUnitsDigitTextField;// 秒的个位数字
@property (nonatomic) UILabel *gapView;

@property (nonatomic) UIButton *publishButton, *increaseButton, *decreaseButton;

@end

@implementation BJLCountDownViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                   totalTime:(NSInteger)time
        currentCountDownTime:(NSInteger)currentCountDownTime
                  isDecrease:(BOOL)isDecrease {
    self = [super init];
    if (self) {
        self->_room = room;
        self->_isTeacher = room.loginUser.isTeacher;
        self.isDecrease = isDecrease;
        self.originCountDownTime = time;
        self.currentCountDownTime = isDecrease ? currentCountDownTime : MAX(0, (time - currentCountDownTime));
        self.isStartTimeShouldHighlight = (self.isTeacher) ? NO : (time >= hightCountDownTime);
    }
    return self;
}

- (void)dealloc {
    [self stopCountDownTimer];

    self.minusInTensDigitTextField.delegate = nil;
    self.minusInUnitsDigitTextField.delegate = nil;
    self.secondsInTensDigitTextField.delegate = nil;
    self.secondsInUnitsDigitTextField.delegate = nil;
}

- (void)loadView {
    bjl_weakify(self);
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        if ([hitView isKindOfClass:[UIButton class]]) {
            return hitView;
        }
        
        NSArray *containerViews = @[self.topBar, self.minusInUnitsDigitTextField, self.minusInTensDigitTextField, self.secondsInTensDigitTextField, self.secondsInUnitsDigitTextField];
        
        if (self.room.loginUser.isTeacher) {
            containerViews = @[self.topBar, self.overlayView, self.minusInUnitsDigitTextField, self.minusInTensDigitTextField, self.secondsInTensDigitTextField, self.secondsInUnitsDigitTextField];
        }
        
        // container-view 才响应点击事件
        if ([containerViews containsObject:hitView]) {
            return hitView;
        }
        
        // 避免按钮禁用状态下点击穿透到 contentView，导致 view 被隐藏
        // @see https://stackoverflow.com/a/40786920/456536
        for (UIView *superview in containerViews) {
            for (UIView *subview in superview.subviews) {
                UIControl *control = bjl_as(subview, UIControl);
                CGPoint pointInControl = [self.view convertPoint:point toView:control];
                if (control && !control.enabled && [control pointInside:pointInControl withEvent:event]) {
                    return self.view; // requires `self.view.userInteractionEnabled = YES;` 👇🏿
                }
            }
        }
        return nil;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self makeSubviews];
    [self makeObeserving];
}

- (void)makeSubviews {
    self.contentView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, contentView);
        view.backgroundColor = [UIColor whiteColor];
        view.clipsToBounds = YES;
        view.layer.cornerRadius = 8.0;
        bjl_return view;
    });
    [self.view addSubview:self.contentView];
    [self.contentView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.view).priorityHigh(); // to update
        make.centerY.equalTo(self.view).multipliedBy(1).priorityHigh(); // to update
        make.width.equalTo(@(240.0)); // 指定宽度，高度自动计算
        // 边界限制
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
    }];
    
    self.topBar = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, topBar);
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#1694FF"];
        bjl_return view;
    });
    [self.contentView addSubview:self.topBar];
    [self.topBar bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.equalTo(@(30.0));
    }];
    [self setupTopBar];
    
    if (!self.isTeacher) {
        [self setupStudentView];
        [self startCountDownTimer];
    }
    else {
        [self setupTeacherView];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self hideKeyboardView];
}

- (void)makeObeserving {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveTimerWithTotalTime:countDownTime:isDecrease:) observer:(BJLMethodObserver)^BOOL(NSInteger totalTime, NSInteger countDownTime, BOOL isDecrease) {
        bjl_strongify(self);
        if (!self.isTeacher) {
            self.currentCountDownTime = isDecrease ? countDownTime : MAX(0, (totalTime - countDownTime));
            self.originCountDownTime = totalTime;
            self.isDecrease = isDecrease;
            
            [self startCountDownTimer];
            self.titleLabel.text = @"计时器";
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceivePauseTimer) observer:^BOOL{
        bjl_strongify(self);
        [self pauseCountDownTimer];
        self.titleLabel.text = @"计时器(已暂停)";

        if (self.isTeacher) {
            self.publishButton.selected = NO;
            [self.publishButton setTitle:@"继续" forState:UIControlStateNormal];
        }
        return YES;
    }];
}

- (void)setupTopBar {
    // title label
    self.titleLabel = [self labelWithTitle:@"计时器" color:[UIColor whiteColor]];
    [self.topBar addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.topBar).offset(10.0);
        make.centerY.equalTo(self.topBar);
    }];
    
    if (self.room.loginUser.isTeacher) {
        // close button
        UIButton *closeButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_close"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(closeButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.topBar addSubview:closeButton];
        [closeButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.right.equalTo(self.topBar).offset(-10.0);
            make.top.bottom.equalTo(self.topBar);
        }];
    }
    
}

- (void)setupStudentView {
    self.containerView =({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view.backgroundColor = [UIColor clearColor];
        bjl_return view;
    });
    [self.contentView addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView.bjl_bottom).offset(-15);
        make.top.equalTo(self.topBar.bjl_bottom).offset(15);
        make.left.equalTo(self.contentView.bjl_left).offset(5);
        make.right.equalTo(self.contentView.bjl_right).offset(-5);
    }];
    [self makeTextViewConstraints];
    [self udateTextFieldUserInteractionEnabled:NO];
    [self initialCountDownTime];
}

- (void)setupTeacherView {
    self.containerView =({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        bjl_return view;
    });
    [self.contentView addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.topBar.bjl_bottom).offset(15);
        make.left.equalTo(self.contentView).offset(15);
        make.right.equalTo(self.contentView).offset(-15);
    }];
    
    [self makeTextViewConstraints];
    [self initialCountDownTime];
    
    UITapGestureRecognizer *tapGesture = ({
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardView)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture;
    });
    // overlay
    self.overlayView = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = YES;
        view.backgroundColor = [UIColor clearColor];
        [view addGestureRecognizer:tapGesture];
        view.accessibilityLabel = BJLKeypath(self, overlayView);
        view;
    });

    self.decreaseButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, decreaseButton);
        [button setTitle:@"倒计时" forState:UIControlStateNormal];
        [button setTitle:@"倒计时" forState:UIControlStateNormal | UIControlStateSelected];
        [button setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button setTitleColor:[UIColor bjl_colorWithHex:0x1795FF] forState:UIControlStateNormal];
        button.layer.cornerRadius = 1;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x1795FF].CGColor;
        button.layer.borderWidth = BJL1Pixel();
        [button addTarget:self action:@selector(decreaseTimer:) forControlEvents:UIControlEventTouchUpInside];
        button.selected = YES;
        bjl_return button;
    });
    
    self.increaseButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, increaseButton);
        [button setTitle:@"正计时" forState:UIControlStateNormal];
        [button setTitle:@"正计时" forState:UIControlStateNormal | UIControlStateSelected];
        [button setBackgroundColor:[UIColor whiteColor]];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button setTitleColor:[UIColor bjl_colorWithHex:0x1795FF] forState:UIControlStateNormal];
        button.layer.cornerRadius = 1;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x1795FF].CGColor;
        button.layer.borderWidth = BJL1Pixel();
        [button addTarget:self action:@selector(increaseTimer:) forControlEvents:UIControlEventTouchUpInside];
        button.selected = NO;
        bjl_return button;
    });

    self.publishButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, publishButton);
        [button setTitle:@"开始" forState:UIControlStateNormal];
        [button setTitle:@"暂停" forState:UIControlStateSelected];
        [button setBackgroundColor:[UIColor whiteColor]];
        [button setTitleColor:[UIColor bjl_colorWithHex:0x4A4A4A] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHex:0x4A4A4A] forState:UIControlStateNormal | UIControlStateSelected];
        button.layer.cornerRadius = 1;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0XD4D4D4].CGColor;
        button.layer.borderWidth = BJL1Pixel();
        [button addTarget:self action:@selector(publishTimer:) forControlEvents:UIControlEventTouchUpInside];
        bjl_return button;
    });

    [self.contentView addSubview:self.increaseButton];
    [self.contentView addSubview:self.decreaseButton];
    [self.contentView addSubview:self.publishButton];
    [self.decreaseButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.containerView);
        make.height.equalTo(@(40));
        make.right.equalTo(self.contentView.bjl_centerX).offset(-10);
        make.top.equalTo(self.containerView.bjl_bottom).offset(10);
    }];
    [self.increaseButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.centerY.top.equalTo(self.decreaseButton);
        make.left.equalTo(self.contentView.bjl_centerX).offset(10);
    }];
    
    [self.publishButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.decreaseButton.bjl_bottom).offset(10);
        make.left.right.equalTo(self.containerView);
        make.height.equalTo(@(45));
        make.bottom.equalTo(self.contentView.bjl_bottom).offset(-10);
    }];
    
    self.decreaseButton.selected = self.isDecrease;
    self.increaseButton.selected = !self.isDecrease;
    
    [self.increaseButton setBackgroundColor: self.increaseButton.selected ? [UIColor bjl_colorWithHex:0x1795FF] : [UIColor whiteColor]];
    [self.decreaseButton setBackgroundColor: self.decreaseButton.selected ? [UIColor bjl_colorWithHex:0x1795FF] : [UIColor whiteColor]];

    if ((self.currentCountDownTime > 0 && self.isDecrease) || (self.currentCountDownTime < self.originCountDownTime && !self.isDecrease)) {
        [self startCountDownTimer];
        [self updateTeacherViewWhenTimerStart];
    }
}

- (void)makeTextViewConstraints {
    self.gapView = ({
        UILabel *view = [UILabel new];
        view.accessibilityLabel = BJLKeypath(self, gapView);
        view.text = @":";
        view.font = [UIFont systemFontOfSize:40];
        view.textColor = [UIColor bjl_colorWithHex:0X333333];
        view.backgroundColor = [UIColor clearColor];
        bjl_return view;
    });
    [self.containerView addSubview:self.gapView];
    
    self.minusInTensDigitTextField = [self textField];
    self.minusInTensDigitTextField.accessibilityLabel = BJLKeypath(self, minusInTensDigitTextField);
    [self.containerView addSubview:self.minusInTensDigitTextField];
    
    self.minusInUnitsDigitTextField = [self textField];
    self.minusInUnitsDigitTextField.accessibilityLabel = BJLKeypath(self, minusInUnitsDigitTextField);
    [self.containerView addSubview:self.minusInUnitsDigitTextField];
    
    self.secondsInTensDigitTextField = [self textField];
    self.secondsInTensDigitTextField.accessibilityLabel = BJLKeypath(self, secondsInTensDigitTextField);
    [self.containerView addSubview:self.secondsInTensDigitTextField];
    
    self.secondsInUnitsDigitTextField = [self textField];
    self.secondsInUnitsDigitTextField.accessibilityLabel = BJLKeypath(self, secondsInUnitsDigitTextField);
    [self.containerView addSubview:self.secondsInUnitsDigitTextField];
    
    CGFloat digitHeight = 55.0f;
    [self.gapView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containerView);
        make.width.equalTo(@(10));
        make.height.equalTo(@(digitHeight));
        make.top.equalTo(self.containerView).offset(10);
    }];
    [self.secondsInTensDigitTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containerView);
        make.left.equalTo(self.gapView.bjl_right).offset(10);
        make.height.equalTo(self.gapView);
    }];
    [self.secondsInUnitsDigitTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.height.width.equalTo(self.secondsInTensDigitTextField);
        make.left.equalTo(self.secondsInTensDigitTextField.bjl_right).offset(10);
        make.right.equalTo(self.containerView);
    }];
    [self.minusInUnitsDigitTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.height.width.equalTo(self.secondsInTensDigitTextField);
        make.right.equalTo(self.gapView.bjl_left).offset(-10);
    }];
    
    [self.minusInTensDigitTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.height.width.equalTo(self.secondsInTensDigitTextField);
        make.left.equalTo(self.containerView);
        make.right.equalTo(self.minusInUnitsDigitTextField.bjl_left).offset(-10);
    }];
}

- (void)initialCountDownTime {
    [self updateShowTime];
}

- (void)udateTextFieldUserInteractionEnabled:(BOOL)userInteractionEnabled {
    self.minusInTensDigitTextField.userInteractionEnabled = userInteractionEnabled;
    self.minusInUnitsDigitTextField.userInteractionEnabled = userInteractionEnabled;
    self.secondsInTensDigitTextField.userInteractionEnabled = userInteractionEnabled;
    self.secondsInUnitsDigitTextField.userInteractionEnabled = userInteractionEnabled;
}

- (void)updateTeacherViewWhenTimerStart {
    self.publishButton.selected = YES;
    self.decreaseButton.userInteractionEnabled = NO;
    self.increaseButton.userInteractionEnabled = NO;
    [self udateTextFieldUserInteractionEnabled:NO];
}

- (void)resetTeacherViewWhenTimerEnd {
    self.publishButton.selected = NO;
    [self.publishButton setTitle:@"开始" forState:UIControlStateNormal];
    self.decreaseButton.userInteractionEnabled = YES;
    self.increaseButton.userInteractionEnabled = YES;
    [self udateTextFieldUserInteractionEnabled:YES];
    
    self.originCountDownTime = 0;
    self.currentCountDownTime = 0;
}

#pragma mark - action
- (void)closeButtonOnClick:(id)sender {
    [self stopCountDownTimer];
    
    if (self.closeCallback) {
        self.closeCallback();
    }
}

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
            
            if (self.isTeacher) {
                [self resetTeacherViewWhenTimerEnd];
            }
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
    BOOL shouldHight = (((self.currentCountDownTime <= hightCountDownTime && self.isDecrease) || (self.originCountDownTime - self.currentCountDownTime <= hightCountDownTime && !self.isDecrease))
                        && ((self.publishButton.isSelected && self.isTeacher) || !self.isTeacher)
                        && self.isStartTimeShouldHighlight);

    UIColor *color = shouldHight ? [UIColor bjl_colorWithHex:0xFF1F49] : [UIColor bjl_colorWithHex:0X333333];
    self.gapView.textColor = color;
    self.minusInUnitsDigitTextField.textColor = color;
    self.minusInTensDigitTextField.textColor = color;
    self.secondsInTensDigitTextField.textColor = color;
    self.secondsInUnitsDigitTextField.textColor = color;
}

- (void)updateShowTime {
    int minutes = ((int)self.currentCountDownTime) / 60;
    int second = ((int)self.currentCountDownTime) % 60;
    
    int minusInTensDigit = minutes / 10;
    int minusInUnitsDigit = minutes % 10;
    
    int secondsInTensDigit = second / 10;
    int secondsInUnitsDigit = second % 10;
    
    self.minusInUnitsDigitTextField.text = [NSString stringWithFormat:@"%i", minusInUnitsDigit];
    self.minusInTensDigitTextField.text = [NSString stringWithFormat:@"%i", minusInTensDigit];
    self.secondsInTensDigitTextField.text = [NSString stringWithFormat:@"%i", secondsInTensDigit];
    self.secondsInUnitsDigitTextField.text = [NSString stringWithFormat:@"%i", secondsInUnitsDigit];
}

- (void)publishTimer:(id)sender {
    bjl_returnIfRobot(1);
    
    NSInteger minusInTensDigit = self.minusInTensDigitTextField.text.integerValue;
    NSInteger minusInUnitsDigit = self.minusInUnitsDigitTextField.text.integerValue;
    
    NSInteger secondsInTensDigit = self.secondsInTensDigitTextField.text.integerValue;
    NSInteger secondsInUnitsDigit = self.secondsInUnitsDigitTextField.text.integerValue;
    
    NSInteger time = (minusInTensDigit * 10 + minusInUnitsDigit) * 60 + (secondsInTensDigit * 10 + secondsInUnitsDigit);
    BOOL isPublish = !self.publishButton.isSelected;
    BOOL isDecrease = self.decreaseButton.isSelected;
    self.isDecrease = isDecrease;
    NSInteger totalTime = (self.originCountDownTime == 0) ? time : self.originCountDownTime;
    NSInteger currentLeftDownTime = isDecrease ? time : ((self.originCountDownTime == 0) ? time : MAX(0, (totalTime - time)));

    if (currentLeftDownTime <= 0 && isPublish) {
        if (isDecrease) {
            self.errorCallback(@"请先设置倒计时时间");
        }
        else {
            self.errorCallback(@"请先设置正计时时间");
        }
        return;
    }

    if (isPublish) {
        if (self.publishCountDownTimerCallback) {
            BOOL success = self.publishCountDownTimerCallback(totalTime , currentLeftDownTime, isDecrease);
            if (success) {
                self.originCountDownTime = totalTime;
                self.currentCountDownTime = isDecrease ? currentLeftDownTime : MAX(0, (totalTime - currentLeftDownTime));
                [self initialCountDownTime];
                [self startCountDownTimer];
                [self updateTeacherViewWhenTimerStart];
            }
        }
    }
    else {
        // 暂停
        if (self.pauseCountDownTimerCallback) {
            BOOL success = self.pauseCountDownTimerCallback();
            if (success) {
                [self stopCountDownTimer];
                self.titleLabel.text = @"计时器(已暂停)";
                self.publishButton.selected = NO;
                [self.publishButton setTitle:@"继续" forState:UIControlStateNormal];
            }
        }
    }
}

- (void)increaseTimer:(id)sender {
    self.decreaseButton.selected = self.increaseButton.selected;
    self.increaseButton.selected = !self.increaseButton.selected;
    
    [self.increaseButton setBackgroundColor: self.increaseButton.selected ? [UIColor bjl_colorWithHex:0x1795FF] : [UIColor whiteColor]];
    [self.decreaseButton setBackgroundColor: self.decreaseButton.selected ? [UIColor bjl_colorWithHex:0x1795FF] : [UIColor whiteColor]];

}

- (void)decreaseTimer:(id)sender {
    self.increaseButton.selected = self.decreaseButton.selected;
    self.decreaseButton.selected = !self.decreaseButton.selected;
    
    [self.decreaseButton setBackgroundColor: self.decreaseButton.selected ? [UIColor bjl_colorWithHex:0x1795FF] : [UIColor whiteColor]];
    [self.increaseButton setBackgroundColor: self.increaseButton.selected ? [UIColor bjl_colorWithHex:0x1795FF] : [UIColor whiteColor]];

}

- (void)hideKeyboardView {
    [self.minusInTensDigitTextField resignFirstResponder];
    [self.minusInUnitsDigitTextField resignFirstResponder];
    [self.secondsInUnitsDigitTextField resignFirstResponder];
    [self.secondsInTensDigitTextField resignFirstResponder];
    
    if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
        [self.overlayView removeFromSuperview];
    }
}

#pragma mark -

- (UILabel *)labelWithTitle:(NSString *)title color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textColor = color;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = title;
    return label;
}

- (UITextField *)textField {
    UITextField *textField = [UITextField new];
    textField.textColor = [UIColor bjl_colorWithHex:0X333333];
    textField.layer.cornerRadius = 8;
    textField.backgroundColor = [UIColor bjl_colorWithHex:0XEBEBEB];
    textField.font = [UIFont systemFontOfSize:36];
    textField.textAlignment = NSTextAlignmentCenter;
    textField.delegate = self;
//    textField.text = @"0";
    return textField;
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.minusInTensDigitTextField
        || textField == self.minusInUnitsDigitTextField
        || textField == self.secondsInTensDigitTextField
        || textField == self.secondsInUnitsDigitTextField) {
        [self.view insertSubview:self.overlayView aboveSubview:self.containerView];
        [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.view);
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.minusInTensDigitTextField) {
        [self.minusInUnitsDigitTextField becomeFirstResponder];
    }
    else if (textField == self.minusInUnitsDigitTextField) {
        [self.secondsInTensDigitTextField becomeFirstResponder];
    }
    else if (textField == self.secondsInTensDigitTextField) {
        [self.secondsInUnitsDigitTextField becomeFirstResponder];
    }
    else if (textField == self.secondsInUnitsDigitTextField) {
        [self.secondsInUnitsDigitTextField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *text = textField.text;
    int number = text.intValue;
    if (number >= 0 && number < 10) {
        textField.text = [NSString stringWithFormat:@"%i", number];
    }
    else {
        textField.text = @"0";
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (![self isValidDuration:newString]) {
        return NO;
    }
    int number = newString.intValue;
    if (number >= 0 && number < 10) {
        return YES;
    }
    return NO;
}

- (BOOL)isValidDuration:(NSString *)durationString {
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:durationString]) {
        return YES;
    }
    return NO;
}

#pragma mark - touch & move

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.view != self.topBar) {
        return;
    }
    
    // 当前触摸点
    CGPoint currentPoint = [touch locationInView:self.view];
    // 上一个触摸点
    CGPoint previousPoint = [touch previousLocationInView:self.view];
    
    // 更新偏移量: 需要注意的是 self.contentView 的 centerY 默认是 self.view 的 contentY 的 1.2 倍
    CGFloat offsetX = (self.contentView.center.x - self.view.center.x) + (currentPoint.x - previousPoint.x);
    CGFloat offsetY = (self.contentView.center.y - self.view.center.y) + (currentPoint.y - previousPoint.y);
    
    // 修改当前 contentView 的中点
    [self.contentView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(offsetX).priorityHigh();
        make.centerY.equalTo(self.view).offset(offsetY).priorityHigh();
    }];
}

@end
