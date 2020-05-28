//
//  BJLIcUserOperateView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/30.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/UIKit+BJLHandler.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcUserOperateView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserOperateView ()

@property (nonatomic) BJLIcUserOperateViewType type;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) NSArray<UIButton *> *definitionButtons;
@property (nonatomic) UIButton *updateVideoButton;
@property (nonatomic) UIButton *switchCameraButton;
@property (nonatomic) UIButton *updateCameraButton;
@property (nonatomic) UIButton *updateMicrophoneButton;
@property (nonatomic) UIButton *grantDrawingButton;
@property (nonatomic) UIButton *authorizeWebPPTButton;
@property (nonatomic) UIButton *likeButton;
@property (nonatomic) UIButton *blockUserButton;
@property (nonatomic) UIButton *authorizeExtraCameraButton;
@property (nonatomic) UIButton *authorizeScreenShareButton;
@property (nonatomic) NSMutableArray<UIButton *> *buttonArray;

@end

@implementation BJLIcUserOperateView

- (instancetype)initWithType:(BJLIcUserOperateViewType)type {
    if (self = [super init]) {
        self.type = type;
    }
    return self;
}

#pragma mark - actions

- (void)updateButtonConstraints {
    self.backgroundColor = [UIColor clearColor];
    // shadow
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    self.layer.shadowRadius = 10.0;
    // 毛玻璃效果
    self.backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 8.0;
        view;
    });
    [self addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    self.updateVideoButton = [self createButtonWithTitle:self.videoOn ? @"关闭画面" : @"打开画面"];
    [self.updateVideoButton addTarget:self action:@selector(updateVideo:) forControlEvents:UIControlEventTouchUpInside];
    self.switchCameraButton = [self createButtonWithTitle:@"切换摄像头"];
    [self.switchCameraButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    self.updateCameraButton = [self createButtonWithTitle:self.cameraOn ? @"关闭摄像头": @"打开摄像头"];
    [self.updateCameraButton addTarget:self action:@selector(updateCamera:) forControlEvents:UIControlEventTouchUpInside];
    self.updateMicrophoneButton = [self createButtonWithTitle:self.microphoneOn ? @"关闭麦克风" : @"打开麦克风"];
    [self.updateMicrophoneButton addTarget:self action:@selector(updateMicrophone:) forControlEvents:UIControlEventTouchUpInside];
    self.grantDrawingButton = [self createButtonWithTitle:self.drawingGranted ? @"收回画笔" : @"授权画笔"];
    [self.grantDrawingButton addTarget:self action:@selector(updateGrantDrawing:) forControlEvents:UIControlEventTouchUpInside];
    self.authorizeWebPPTButton = [self createButtonWithTitle:self.webPPTAuthorized ? @"取消PPT" : @"授权PPT"];
    [self.authorizeWebPPTButton addTarget:self action:@selector(authorizeWebPPT:) forControlEvents:UIControlEventTouchUpInside];
    self.authorizeExtraCameraButton = [self createButtonWithTitle:self.extraCameraAuthorized ? @"取消辅助摄像头" : @"辅助摄像头"];
    [self.authorizeExtraCameraButton addTarget:self action:@selector(authorizeExtraCamera:) forControlEvents:UIControlEventTouchUpInside];
    self.authorizeScreenShareButton = [self createButtonWithTitle:self.ScreenShareAuthorized ? @"取消屏幕共享" : @"屏幕共享"];
    [self.authorizeScreenShareButton addTarget:self action:@selector(authorizeScreenShare:) forControlEvents:UIControlEventTouchUpInside];
    self.likeButton = [self createButtonWithTitle:@"奖励"];
    [self.likeButton addTarget:self action:@selector(sendLike:) forControlEvents:UIControlEventTouchUpInside];
    self.blockUserButton = [self createButtonWithTitle:@"踢出教室"];
    [self.blockUserButton addTarget:self action:@selector(blockUser:) forControlEvents:UIControlEventTouchUpInside];
    
    self.buttonArray = [@[self.updateVideoButton,
                          self.updateCameraButton,
                          self.updateMicrophoneButton,
                          self.grantDrawingButton,
                          self.authorizeWebPPTButton,
                          self.authorizeScreenShareButton,
                          self.authorizeExtraCameraButton,
                          self.likeButton,
                          self.blockUserButton] mutableCopy];
    if (self.type == BJLIcUserOperateViewTeacher) {
        if (!self.cameraOn) {
            [self.buttonArray removeObject:self.updateVideoButton];
        }
        if (self.isTeacher || self.isAssistant) {
            [self.buttonArray removeObject:self.grantDrawingButton];
            [self.buttonArray removeObject:self.likeButton];
            [self.buttonArray removeObject:self.authorizeWebPPTButton];
        }
        if (self.isTeacher) {
            [self.buttonArray removeObject:self.updateCameraButton];
            [self.buttonArray removeObject:self.updateMicrophoneButton];
            [self.buttonArray removeObject:self.blockUserButton];
        }
        if (!self.enableStudentExtraCameraAndScreenShare) {
            [self.buttonArray removeObject:self.authorizeScreenShareButton];
            [self.buttonArray removeObject:self.authorizeExtraCameraButton];
        }
    }
    else if (self.type == BJLIcUserOperateViewStudent) {
        self.buttonArray = [@[self.updateVideoButton] mutableCopy] ;
    }
    else if (self.type == BJLIcUserOperateViewSelf) {
        [self.buttonArray removeAllObjects];
        if (self.cameraOn) {
            [self.buttonArray addObject:self.switchCameraButton];
            NSArray<UIButton *> *definitionButtons = [self createDefinitionButtons];
            [self.buttonArray addObjectsFromArray:definitionButtons];
        }
    }
    
    [self makeConstraintsWithButtons:self.buttonArray];
}

- (void)updateDefinition:(BJLVideoDefinition)definition {
    if (self.updateDefinitionCallback) {
        self.updateDefinitionCallback(definition);
    }
}

- (void)updateVideo:(UIButton *)button {
    if (self.updateVideoCallback) {
        self.updateVideoCallback(!self.videoOn);
    }
}

- (void)switchCamera:(UIButton *)button {
    if (self.switchCameraCallback) {
        self.switchCameraCallback();
    }
}

- (void)updateCamera:(UIButton *)button {
    if (self.updateCameraCallback) {
        self.updateCameraCallback(!self.cameraOn);
    }
}

- (void)updateMicrophone:(UIButton *)button {
    if (self.updateMicrophoneCallback) {
        self.updateMicrophoneCallback(!self.microphoneOn);
    }
}

- (void)updateGrantDrawing:(UIButton *)button {
    if (self.grantDrawingCallback) {
        self.grantDrawingCallback(!self.drawingGranted);
    }
}

- (void)authorizeWebPPT:(UIButton *)button {
    if (self.authorizeWebPPTCallback) {
        self.authorizeWebPPTCallback(!self.webPPTAuthorized);
    }
}

- (void)authorizeExtraCamera:(UIButton *)button {
    if (self.authorizeExtraCameraCallback) {
        self.authorizeExtraCameraCallback(!self.extraCameraAuthorized);
    }
}

- (void)authorizeScreenShare:(UIButton *)button {
    if (self.authorizeScreenShareCallback) {
        self.authorizeScreenShareCallback(!self.ScreenShareAuthorized);
    }
}

- (void)sendLike:(UIButton *)button {
    if (self.sendLikeCallback) {
        self.sendLikeCallback();
    }
}

- (void)blockUser:(UIButton *)button {
    if (self.blockUserCallback) {
        self.blockUserCallback();
    }
}

#pragma mark - touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    for (UIButton *button in [self.buttonArray copy]) {
        if (CGRectContainsPoint(button.frame, point)) {
            [self switchToHighlightedColor:button];
            break;
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    for (UIButton *button in [self.buttonArray copy]) {
        if (CGRectContainsPoint(button.frame, point)) {
            [self switchToHighlightedColor:button];
        }
        else {
            [self switchToNormalColor:button];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    for (UIButton *button in [self.buttonArray copy]) {
        [self switchToNormalColor:button];
        if (CGRectContainsPoint(button.frame, point)) {
            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    for (UIButton *button in [self.buttonArray copy]) {
        [self switchToNormalColor:button];
    }
}

- (void)switchToHighlightedColor:(UIButton *)button {
    button.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
}

- (void)switchToNormalColor:(UIButton *)button {
    button.backgroundColor = [UIColor clearColor];
}

#pragma mark - wheel

- (UIButton *)createButtonWithTitle:(NSString *)title {
    UIButton *button = [[UIButton alloc] init];
    button.userInteractionEnabled = NO;
    button.clipsToBounds = NO;
    button.accessibilityLabel = title;
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    return button;
}

- (void)makeConstraintsWithButtons:(nullable NSArray *)buttonArray {
    if (buttonArray.count <= 0) {
        return;
    }
    UIButton *lastButton = nil;
    for (UIButton *button in buttonArray) {
        [self addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.right.equalTo(self);
            if (lastButton) {
                make.height.equalTo(lastButton.bjl_height);
                make.top.equalTo(lastButton.bjl_bottom);
            }
            else {
                make.height.equalTo(@([BJLIcAppearance sharedAppearance].userOptionViewHeight)).priorityHigh();
                make.top.equalTo(self.bjl_top).offset(8.0);
            }
        }];
        lastButton = button;
    }
    [lastButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(self.bjl_bottom).offset(-8.0);
    }];
}

- (NSArray<UIButton *> *)createDefinitionButtons {
    NSMutableArray *definitionButtons = [NSMutableArray array];
    for (BJLVideoDefinition definition = BJLVideoDefinition_std; definition <= self.maxVideoDefinition; definition++) {
        UIButton *button = [self createButtonWithTitle:[self definitionKeyWithType:definition]];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF"] forState:UIControlStateDisabled];
        button.enabled = (definition != self.currentVideoDefinition);
        bjl_weakify(self);
        [button bjl_addHandler:^(UIButton * _Nonnull button) {
            bjl_strongify(self);
            [self updateDefinition:definition];
            button.enabled = NO;
        }];
        [definitionButtons addObject:button];
    }
    return definitionButtons;
}

- (NSString *)definitionKeyWithType:(BJLVideoDefinition)definition {
    switch (definition) {
        case BJLVideoDefinition_std:
            return @"标清";
            
        case BJLVideoDefinition_360p:
            return @"360p";
        
        case BJLVideoDefinition_high:
            return @"高清";
        
        case BJLVideoDefinition_720p:
            return @"720p";
            
        case BJLVideoDefinition_1080p:
            return @"1080p";
            
        default:
            return @"标清";
    }
}

@end

NS_ASSUME_NONNULL_END
