//
//  BJLIcToolbarViewController+phoneUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+phoneUserVideoUpside.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (phoneUserVideoUpside)

- (void)makePhoneUserVideoUpsideSubviews {
    self.view.backgroundColor = [UIColor clearColor];
    // iphone 只有 containerView 是模糊效果
    self.backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view.layer.cornerRadius = [BJLIcAppearance sharedAppearance].toolbarMediumSpace;
        view.layer.masksToBounds = YES;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        view.layer.borderWidth = 1.0;
        view.userInteractionEnabled = NO;
        view;
    });
    // iphone 的 containerView 包括全部按钮
    self.containerView = ({
        UIView *view = [UIView new];
        view.layer.masksToBounds = YES;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    // 菜单使用单独的模糊效果
    self.menuBackgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.accessibilityLabel = BJLKeypath(self, menuBackgroundView);
        view.layer.cornerRadius = [BJLIcAppearance sharedAppearance].toolbarMediumSpace;
        view.layer.masksToBounds = YES;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        view.layer.borderWidth = 1.0;
        view.userInteractionEnabled = NO;
        view;
    });
    self.menuButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, menuButton);
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].toolbarMediumSpace;
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_menu_normal"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_menu_selected"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(updatePhoneUserVideoUpsideContainerViewHidden) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
}

- (void)remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    // 先添加背景
    [self.view addSubview:self.backgroundView];
    // 添加 containerView
    [self.view addSubview:self.containerView];
    // 添加菜单背景
    [self.view addSubview:self.menuBackgroundView];
    // 最后添加菜单
    [self.menuButton addSubview:self.menuRedDot];
    [self.view addSubview:self.menuButton];
    // 先布局 containerView 和背景
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace - 2.0)); // 留出 2px 的边框
        make.right.equalTo(self.view).offset(-[BJLIcAppearance sharedAppearance].toolbarSmallSpace);
        make.centerY.equalTo(self.view);
        make.width.lessThanOrEqualTo(self.view);
        make.width.equalTo(@(([BJLIcAppearance sharedAppearance].toolbarLargeSpace + [BJLIcAppearance sharedAppearance].toolbarSmallSpace)  * (optionButtons.count + mediaButtons.count + 1) + [BJLIcAppearance sharedAppearance].toolbarLargeSpace));
    }];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    // 添加并且布局按钮
    [self remakePhoneUserVideoUpsideConstraintsWithMediaButtons:mediaButtons];
    [self remakePhoneUserVideoUpsideConstraintsWithOptionButtons:optionButtons];
    // 最后布局菜单和菜单背景
    [self.menuButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.containerView);
        make.top.bottom.equalTo(self.containerView);
        make.width.equalTo(self.menuButton.bjl_height);
    }];
    [self.menuRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.menuButton).offset(10.0);
        make.right.equalTo(self.menuButton);
        make.height.width.equalTo(@12.0);
    }];
    [self.menuBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.menuButton);
    }];
    if (!self.isPhoneToolboxInitialized) {
        // 初始化时显示操作菜单
        self.isPhoneToolboxInitialized = YES;
        [self updatePhoneUserVideoUpsideContainerViewHidden];
    }
}

- (void)remakePhoneUserVideoUpsideContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    // 举手按钮超过toolbar的界限，放到父视图层级
    UIView *view = nil;
    if (self.requestReferenceViewCallback) {
        view = self.requestReferenceViewCallback();
    }
    if (!view) {
        return;
    }
    UIView *speakRequestBackgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.accessibilityLabel = @"speakRequestBackgroundView";
        view.layer.cornerRadius = [BJLIcAppearance sharedAppearance].toolbarMediumSpace;
        view.layer.masksToBounds = YES;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        view.layer.borderWidth = 1.0;
        view.userInteractionEnabled = NO;
        view;
    });
    // 先添加背景
    [self.view addSubview:self.backgroundView];
    // 添加 containerView
    [self.view addSubview:self.containerView];
    // 添加菜单背景
    [self.view addSubview:self.menuBackgroundView];
    // 添加菜单
    [self.view addSubview:self.menuButton];
    // 添加举手背景
    [view addSubview:speakRequestBackgroundView];
    // 举手按钮
    [view addSubview:self.speakRequestButton];
    [self.speakRequestButton addSubview:self.speakRequestProgressView];
    
    // 先布局 containerView 和背景
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace - 2.0)); // 留出 2px 的边框
        make.right.equalTo(self.view).offset(-[BJLIcAppearance sharedAppearance].toolbarSmallSpace);
        make.centerY.equalTo(self.view);
        make.width.lessThanOrEqualTo(self.view);
        make.width.equalTo(@(([BJLIcAppearance sharedAppearance].toolbarLargeSpace + [BJLIcAppearance sharedAppearance].toolbarSmallSpace)  * (optionButtons.count + mediaButtons.count + 1) + [BJLIcAppearance sharedAppearance].toolbarLargeSpace));
    }];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
    // 添加并且布局按钮
    [self remakePhoneUserVideoUpsideConstraintsWithMediaButtons:mediaButtons];
    [self remakePhoneUserVideoUpsideConstraintsWithOptionButtons:optionButtons];
    // 最后布局菜单和菜单背景
    [self.menuButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.containerView);
        make.top.bottom.equalTo(self.containerView);
        make.width.equalTo(self.menuButton.bjl_height);
    }];
    [self.menuBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.menuButton);
    }];
    if (!self.isPhoneToolboxInitialized) {
        // 初始化时显示操作菜单
        self.isPhoneToolboxInitialized = YES;
        [self updatePhoneUserVideoUpsideContainerViewHidden];
    }
    // 举手和举手背景
    [self.speakRequestButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.menuButton);
        make.width.height.equalTo(self.menuButton);
        make.bottom.equalTo(self.menuButton.bjl_top).offset(-[BJLIcAppearance sharedAppearance].toolbarSmallSpace);
    }];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton).inset(2.0);
    }];
    [speakRequestBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton);
    }];
}

- (void)updatePhoneUserVideoUpsideContainerViewHidden {
    NSMutableArray<UIButton *> *buttons = [@[/*self.speakerButton,*/
                                                 self.microphoneButton,
                                                 self.cameraButton,
                                                 self.blackboardLayoutButton,
                                                 self.cloudRecordingButton,
                                                 self.unmuteAllMicrophoneButton,
                                                 self.muteAllMicrophoneButton,
                                                 self.forbidSpeakRequestButton,
                                                 self.userListButton,
                                                 self.chatListButton] mutableCopy];
    switch (self.room.loginUser.role) {
        case BJLUserRole_teacher:
            break;
            
        case BJLUserRole_assistant:
            [buttons removeObject:self.blackboardLayoutButton];
            break;
            
        case BJLUserRole_student:
            [buttons removeObjectsInArray:@[self.blackboardLayoutButton, self.cloudRecordingButton, self.unmuteAllMicrophoneButton,self.muteAllMicrophoneButton, self.forbidSpeakRequestButton, self.userListButton]];
            break;
            
        default:
            buttons = nil;
            break;
    }
    self.menuButton.selected = !self.menuButton.isSelected;
    if (self.menuButton.isSelected) {
        // 显示菜单项时，显示模糊效果
        self.backgroundView.hidden = NO;
        self.menuBackgroundView.hidden = YES;
        self.containerView.hidden = NO;
        self.menuRedDot.hidden = YES;
        [self.containerView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.equalTo(@(([BJLIcAppearance sharedAppearance].toolbarLargeSpace + [BJLIcAppearance sharedAppearance].toolbarSmallSpace)  * (buttons.count + 1) + [BJLIcAppearance sharedAppearance].toolbarLargeSpace));
        }];
    }
    else {
        // 隐藏菜单项时，显示菜单按钮单独的模糊效果
        self.backgroundView.hidden = YES;
        self.menuBackgroundView.hidden = NO;
        self.containerView.hidden = YES;
        [self.containerView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
        }];
    }
}

- (void)remakePhoneUserVideoUpsideConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in buttons) {
        [self.containerView addSubview:button];
        // iphone 布局基于 containerview
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.equalTo(self.containerView);
            make.width.equalTo(button.bjl_height);
            make.left.equalTo(lastMediaButton.bjl_right ?: self.containerView.bjl_left).offset([BJLIcAppearance sharedAppearance].toolbarSmallSpace);
        }];
        lastMediaButton = button;
    }
}

- (void)remakePhoneUserVideoUpsideConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        [self.containerView addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            // iphone 按钮没有标题，宽高相等
            make.top.bottom.equalTo(self.containerView);
            if (lastButton) {
                make.right.equalTo(lastButton.bjl_left).offset(-[BJLIcAppearance sharedAppearance].toolbarSmallSpace);
            }
            else {
                make.right.equalTo(self.containerView.bjl_right).offset(-([BJLIcAppearance sharedAppearance].toolbarLargeSpace + [BJLIcAppearance sharedAppearance].toolbarMediumSpace));
            }
            make.width.equalTo(button.bjl_height);
        }];
        lastButton = button;
    }
}

@end
