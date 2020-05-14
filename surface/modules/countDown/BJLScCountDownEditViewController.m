//
//  BJLScCountDownEditViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/3/26.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScCountDownEditViewController.h"
#import "BJLScAppearance.h"

@interface BJLScCountDownEditViewController ()<UITextFieldDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) BOOL isDecrease;
@property (nonatomic) NSInteger totalTime;
@property (nonatomic) NSInteger currentShowCountDownTime;// 当前显示的计数值
@property (nonatomic) NSTimer *countDownTimer;

@property (nonatomic) UIView *topContainerView;
@property (nonatomic) UIButton *decreaseButton, *increaseButton;
@property (nonatomic) UIButton *publishButton, *stopButton;
@property (nonatomic) UITextField *minuteTextField, *secondTextField;

@end

@implementation BJLScCountDownEditViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                   totalTime:(NSInteger)totalTime
        currentCountDownTime:(NSInteger)currentCountDownTime
                  isDecrease:(BOOL)isDecrease {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self->_room = room;
        self.isDecrease = isDecrease;
        self.totalTime = totalTime;
        self.currentShowCountDownTime = currentCountDownTime;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self makeSubviews];
    [self updateTimerCountDownTypeWithDecrease:self.isDecrease];
    if (self.currentShowCountDownTime > 0) {
        [self updateTimerDuration:self.totalTime];
        [self startCountDownTimer];
    }
    else {
        [self initialTimerDuration];
    }
    
    bjl_weakify(self);
    UITapGestureRecognizer *tap = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        [self hideKeyBoard];
    }];
    [self.view addGestureRecognizer:tap];
    [self makeObserving];
}

- (void)dealloc {
    [self stopTimer];
    self.minuteTextField.delegate = nil;
    self.secondTextField.delegate = nil;
}

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveTimerWithTotalTime:countDownTime:isDecrease:)
             observer:(BJLMethodObserver)^BOOL(NSInteger totalTime, NSInteger countDownTime, BOOL isDecrease) {
        bjl_strongify(self);
        self.currentShowCountDownTime = isDecrease ? countDownTime : MAX(0, (totalTime - countDownTime));
        self.totalTime = totalTime;
        self.isDecrease = isDecrease;
        
        [self startCountDownTimer];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceivePauseTimer) observer:^BOOL{
        bjl_strongify(self);
        [self pauseCountDownTimer];
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveStopTimer) observer:^BOOL{
        bjl_strongify(self);
        [self stopCountDownTimer];
        return YES;
    }];
}

#pragma mark - UI

- (void)makeSubviews {
    [self makeTopView];
    
    UILabel *timerTypeLabel = [self labelWithTitle:@"计时方式"];
    self.decreaseButton = [self buttonWithTitle:@"倒计时"];
    [self.decreaseButton addTarget:self action:@selector(decreaseTimer) forControlEvents:UIControlEventTouchUpInside];
    self.increaseButton = [self buttonWithTitle:@"正计时"];
    [self.increaseButton addTarget:self action:@selector(increaseTimer) forControlEvents:UIControlEventTouchUpInside];
    self.minuteTextField = [self makeTextField];
    self.secondTextField = [self makeTextField];
    
    UILabel *gapLabel = [self labelWithTitle:@":"];
    gapLabel.textAlignment = NSTextAlignmentCenter;
    
    UIView *line1 = [UIView new];
    line1.backgroundColor = [UIColor bjlsc_grayLineColor];
    
    UILabel *timeLabel = [self labelWithTitle:@"设置时间"];
    UIView *line2 = [UIView new];
    line2.backgroundColor = [UIColor bjlsc_grayLineColor];

    [self.view addSubview:timerTypeLabel];
    [self.view addSubview:self.decreaseButton];
    [self.view addSubview:self.increaseButton];
    [self.view addSubview:line1];
    [self.view addSubview:timeLabel];
    [self.view addSubview:self.minuteTextField];
    [self.view addSubview:gapLabel];
    [self.view addSubview:self.secondTextField];
    [self.view addSubview:line2];
    [self.view addSubview:self.stopButton];
    [self.view addSubview:self.publishButton];

    [line1 bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.topContainerView.bjl_bottom).offset(55);
        make.height.equalTo(@(BJLScOnePixel));
    }];
    [line2 bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(line1.bjl_bottom).offset(55);
        make.height.equalTo(@(BJLScOnePixel));
    }];

    [timerTypeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(15);
        make.right.lessThanOrEqualTo(self.decreaseButton.bjl_left);
        make.top.equalTo(self.topContainerView.bjl_bottom);
        make.bottom.equalTo(line1.bjl_top);
    }];
    [self.increaseButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(timerTypeLabel);
        make.right.equalTo(self.view).offset(-BJLScViewSpaceL);
        make.height.equalTo(@(40));
        make.width.equalTo(@(64));
    }];
    [self.decreaseButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(timerTypeLabel);
        make.right.equalTo(self.increaseButton.bjl_left).offset(-BJLScViewSpaceL);
        make.size.equalTo(self.increaseButton);
    }];

    [timeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(15);
        make.top.equalTo(line1.bjl_bottom);
        make.bottom.equalTo(line2.bjl_top);
    }];
    
    [self.secondTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.width.height.equalTo(self.increaseButton);
        make.centerY.equalTo(timeLabel);
    }];

    [self.minuteTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.width.height.equalTo(self.decreaseButton);
        make.centerY.equalTo(timeLabel);
    }];

    [gapLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.minuteTextField.bjl_right);
        make.right.equalTo(self.secondTextField.bjl_left);
        make.top.bottom.equalTo(self.secondTextField);
    }];
    
    [self.publishButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.stopButton.bjl_right).offset(20);
        make.right.equalTo(self.view.bjl_right).offset(-BJLScViewSpaceL);
        make.bottom.equalTo(self.view.bjl_bottom).offset(-10);
        make.height.equalTo(@(40));
    }];

    [self.stopButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view.bjl_left).offset(BJLScViewSpaceL);
        make.height.bottom.width.equalTo(self.publishButton);
    }];
}

- (void)makeTopView {
    self.topContainerView = [UIView new];
    UIImageView *imageView = [UIImageView new];
    [imageView setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_timer"]];
    [self.topContainerView addSubview:imageView];
    [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@(24));
        make.left.equalTo(self.topContainerView).offset(BJLScViewSpaceM);
        make.centerY.equalTo(self.topContainerView);
    }];
    
    UILabel *label = [UILabel new];
    label.text = @"计时器";
    label.textColor = [UIColor bjl_colorWithHex:0x4a4a4a];
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:16];
    [self.topContainerView addSubview:label];
    [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(imageView.bjl_right).offset(5);
        make.centerY.equalTo(imageView);
        make.right.lessThanOrEqualTo(self.topContainerView);
    }];
        
    UIView *line = [UIView new];
    line.backgroundColor = [UIColor bjlsc_grayLineColor];
    [self.topContainerView addSubview:line];
    [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.topContainerView);
        make.height.equalTo(@(BJLScOnePixel));
    }];
    
    [self.view addSubview:self.topContainerView];
    [self.topContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@(40));
    }];
}

#pragma mark - timer

- (void)stopTimer {
    if (self.countDownTimer || [self.countDownTimer isValid]) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

- (void)startTimer {
    [self stopTimer];
    
    bjl_weakify(self);
    self.countDownTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        
        // 计时结束
        if ((self.currentShowCountDownTime <= 0 && self.isDecrease)
            || (self.currentShowCountDownTime >= self.totalTime && !self.isDecrease)) {
            [timer invalidate];
            [self stopCountDownTimer];
            return;
        }
        
        if (self.isDecrease) {
            self.currentShowCountDownTime --;
        }
        else {
            self.currentShowCountDownTime ++;
        }
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - action

- (void)updateUserInteractive:(BOOL)enable {
    self.decreaseButton.userInteractionEnabled = enable;
    self.increaseButton.userInteractionEnabled = enable;
    self.minuteTextField.userInteractionEnabled = enable;
    self.secondTextField.userInteractionEnabled = enable;
}

- (void)startCountDownTimer {
    self.publishButton.selected = YES;
    [self updateUserInteractive:NO];
    [self startTimer];
}

- (void)pauseCountDownTimer {
    self.publishButton.selected = NO;
    [self.publishButton setTitle:@"继续" forState:UIControlStateNormal];
    [self.publishButton setTitle:@"继续" forState:UIControlStateNormal | UIControlStateHighlighted];

    [self stopTimer];
    [self updateUserInteractive:NO];
}

- (void)stopCountDownTimer {
    self.publishButton.selected = NO;
    [self.publishButton setTitle:@"开始计时" forState:UIControlStateNormal];
    [self.publishButton setTitle:@"开始计时" forState:UIControlStateNormal | UIControlStateHighlighted];
    
    [self stopTimer];
    [self updateUserInteractive:YES];
    [self initialTimerDuration];
}

- (void)decreaseTimer {
    [self updateTimerCountDownTypeWithDecrease:YES];
    [self initialTimerDuration];
}

- (void)increaseTimer {
    [self updateTimerCountDownTypeWithDecrease:NO];
    [self initialTimerDuration];
}

- (void)updateTimerCountDownTypeWithDecrease:(BOOL)isDecrease {
    self.isDecrease = isDecrease;
    self.decreaseButton.selected = isDecrease;
    self.increaseButton.selected = !isDecrease;
    [self hideKeyBoard];
}

- (void)initialTimerDuration {
    self.currentShowCountDownTime = self.isDecrease ? self.totalTime : 0;
    [self updateTimerDuration:self.totalTime];
}

- (void)updateTimerDuration:(NSInteger)time {
    NSInteger minus = time / 60;
    NSInteger second = time % 60;
    NSString *minuteString = (minus < 10) ? [NSString stringWithFormat:@"%02td", minus] : [NSString stringWithFormat:@"%td", minus];
    NSString *secondString = (second < 10) ? [NSString stringWithFormat:@"%02td", second] : [NSString stringWithFormat:@"%td", second];
    self.minuteTextField.text = minuteString;
    self.secondTextField.text = secondString;
}

- (void)hideKeyBoard {
    if ([self.minuteTextField isFirstResponder]) {
        [self.minuteTextField resignFirstResponder];
    }
    if ([self.secondTextField isFirstResponder]) {
        [self.secondTextField resignFirstResponder];
    }
}

- (void)requestStopTimer {
    bjl_returnIfRobot(1);
    [self hideKeyBoard];
    BJLError *error = [self.room.roomVM requestStopTimer];
    if (error) {
        [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
    }
}

- (void)requestStartOrPauseTimer {
    bjl_returnIfRobot(1);
    [self hideKeyBoard];

    if (self.publishButton.selected) {
        BJLError *error = [self.room.roomVM requestPauseTimer];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
    else {
        if (self.totalTime <= 0) {
            if (self.isDecrease) {
                [self showProgressHUDWithText:@"请先设置倒计时时间"];
            }
            else {
                [self showProgressHUDWithText:@"请先设置正计时时间"];
            }
            return;
        }
        NSInteger leftCountDownTime = self.isDecrease ? self.currentShowCountDownTime : (self.totalTime - self.currentShowCountDownTime);
        BJLError *error = [self.room.roomVM requestPublishTimerWithTotalTime:self.totalTime
                                                               countDownTime:leftCountDownTime
                                                                  isDecrease:self.isDecrease];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
}

#pragma mark - wheel

- (UILabel *)labelWithTitle:(NSString *)string {
    UILabel *label = [UILabel new];
    label.textColor = [UIColor bjl_colorWithHex:0x333333];
    label.font = [UIFont systemFontOfSize:16];
    label.textAlignment = NSTextAlignmentLeft;
    label.text = string;
    return label;
}

- (UIButton *)buttonWithTitle:(NSString *)string {
    UIButton *button = [UIButton new];
    [button setTitle:string forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    button.layer.cornerRadius = 8;
    button.layer.masksToBounds = YES;
    button.layer.borderWidth = BJLScOnePixel;
    button.layer.borderColor = [UIColor bjl_colorWithHex:0xBDC6CF].CGColor;

    [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor bjl_colorWithHex:0x333333] forState:UIControlStateNormal];
    
    UIColor *selectedBackgroundColor = (string.length) ? [UIColor bjl_colorWithHex:0x1795FF] : [UIColor whiteColor];
    UIColor *selectedTitleColor = (string.length) ? [UIColor whiteColor] : [UIColor bjl_colorWithHex:0x333333];

    [button setBackgroundImage:[UIImage bjl_imageWithColor:selectedBackgroundColor] forState:UIControlStateSelected];
    [button setBackgroundImage:[UIImage bjl_imageWithColor:selectedBackgroundColor] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[UIImage bjl_imageWithColor:selectedBackgroundColor] forState:UIControlStateHighlighted | UIControlStateSelected];
    [button setTitleColor:selectedTitleColor forState:UIControlStateSelected];
    [button setTitleColor:selectedTitleColor forState:UIControlStateHighlighted];
    [button setTitleColor:selectedTitleColor forState:UIControlStateHighlighted | UIControlStateSelected];
    return button;
}

- (UIButton *)publishButton {
    if (!_publishButton) {
        UIButton *button = [UIButton new];
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        button.backgroundColor = [UIColor bjl_colorWithHex:0x1795FF];
        button.layer.cornerRadius = 16.0;
        // if self.doneButton.selected then save
        // otherwise show valid error
        [button setTitle:@"开始计时" forState:UIControlStateNormal];
        [button setTitle:@"开始计时" forState:UIControlStateNormal | UIControlStateHighlighted];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [button setTitle:@"暂停" forState:UIControlStateSelected];
        [button setTitle:@"暂停" forState:UIControlStateSelected | UIControlStateHighlighted];
        _publishButton = button;
        [_publishButton addTarget:self action:@selector(requestStartOrPauseTimer) forControlEvents:UIControlEventTouchUpInside];
    }
    return _publishButton;
}

- (UIButton *)stopButton {
    if (!_stopButton) {
        UIButton *button = [UIButton new];
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        button.backgroundColor = [UIColor whiteColor];
        button.layer.cornerRadius = 16.0;
        button.layer.borderWidth = BJLScOnePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0xBDC6CF].CGColor;
        // if self.doneButton.selected then save
        // otherwise show valid error
        [button setTitle:@"结束计时" forState:UIControlStateNormal];
        [button setTitle:@"结束计时" forState:UIControlStateNormal | UIControlStateHighlighted];
        [button setTitleColor:[UIColor bjl_colorWithHex:0x999999] forState:UIControlStateNormal];
        _stopButton = button;
        [_stopButton addTarget:self action:@selector(requestStopTimer) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopButton;
}

- (UITextField *)makeTextField {
    UITextField *textField = [UITextField new];
    textField.font = [UIFont systemFontOfSize:16];
    textField.textColor = [UIColor bjl_colorWithHex:0x333333];
    textField.textAlignment = NSTextAlignmentCenter;
    textField.layer.cornerRadius = 8;
    textField.layer.masksToBounds = YES;
    textField.layer.borderWidth = BJLScOnePixel;
    textField.layer.borderColor = [UIColor bjl_colorWithHex:0xBDC6CF].CGColor;
    textField.delegate = self;
    textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.returnKeyType = UIReturnKeyDone;
    return textField;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *minuteString = self.minuteTextField.text;
    NSString *secondString = self.secondTextField.text;
    NSInteger minut = MIN(MAX(minuteString.bjl_integerValue, 0), 60);
    NSInteger second = MIN(MAX(secondString.bjl_integerValue, 0), 60);
    self.totalTime = minut * 60 + second;
    [self initialTimerDuration];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (![self isValidDuration:newString]) {
        return NO;
    }

    NSInteger number = newString.bjl_integerValue;
    if (number >= 0 && number < 60) {
        return YES;
    }
    return NO;
}

// 判断是否为数字
- (BOOL)isValidDuration:(NSString *)durationString {
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:durationString]) {
        return YES;
    }
    return NO;
}

@end
