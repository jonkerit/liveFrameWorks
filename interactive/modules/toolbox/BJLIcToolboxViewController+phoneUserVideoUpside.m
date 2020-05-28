//
//  BJLIcToolboxViewController+phoneUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController+phoneUserVideoUpside.h"
#import "BJLIcToolboxViewController+private.h"

@implementation BJLIcToolboxViewController (phoneUserVideoUpside)

- (void)remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistant {
    self.containerView = ({
        UIView *view = [UIView new];
        // shadow
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.2;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
        view.layer.shadowRadius = 10.0;
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    [self.view addSubview:self.containerView];
    // iphone 为 toolbar 留出空间，老师留出菜单按钮的空间
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.view);
        make.right.equalTo(self.view);
        make.width.equalTo(@(32.0));
        make.bottom.lessThanOrEqualTo(self.view).offset(- [BJLIcAppearance sharedAppearance].toolbarLargeSpace);
    }];
    
    self.backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.layer.masksToBounds = YES;
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view;
    });
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    
    NSArray *buttons = nil;
    if(self.room.loginUser.isTeacher) {
        buttons = [self teacherButtons];
    }
    else {
        buttons = [self assistantButtons];
    }
    
    [self remakePhoneUserVideoUpsideConstraintsWithButtons:buttons];
    [self.view addSubview:self.singleLine];
    [self.singleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.paletteButton.bjl_bottom).offset(1.0);
        make.centerX.equalTo(self.containerView);
        make.height.equalTo(@1.0);
        make.width.equalTo(@16.0);
    }];
    self.gestureView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, gestureView);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.gestureView];
    [self.gestureView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self setupGesture];
}

- (void)remakePhoneUserVideoUpsideContainerViewForStudent {
    NSArray *buttons = [self studentButtons];

    self.referenceViewForPhone = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = NO;
        view.accessibilityLabel = BJLKeypath(self, referenceViewForPhone);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    // iphone 为 toolbar 留出空间，学生留出举手按钮和菜单按钮的空间
    CGFloat offset = self.room.loginUser.isStudent ? - ([BJLIcAppearance sharedAppearance].toolbarLargeSpace * 2 + [BJLIcAppearance sharedAppearance].toolboxButtonSpace) : - [BJLIcAppearance sharedAppearance].toolbarLargeSpace;
    [self.view addSubview:self.referenceViewForPhone];
    [self.referenceViewForPhone bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight);
        make.right.equalTo(self.view);
        make.width.equalTo(@(32.0));
        make.bottom.lessThanOrEqualTo(self.view).offset(offset);
    }];
    
    self.containerView = ({
        UIView *view = [UIView new];
        // shadow
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.2;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
        view.layer.shadowRadius = 10.0;
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    [self.view addSubview:self.containerView];
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.left.right.equalTo(self.referenceViewForPhone);
        make.top.greaterThanOrEqualTo(self.referenceViewForPhone);
        make.bottom.lessThanOrEqualTo(self.referenceViewForPhone);
    }];
    
    self.backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.layer.masksToBounds = YES;
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view;
    });
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    
    [self remakePhoneUserVideoUpsideConstraintsWithButtons:buttons];
    self.gestureView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, gestureView);
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.gestureView];
    [self.gestureView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self setupGesture];
}

- (void)remakePhoneUserVideoUpsideConstraintsWithButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.centerX.equalTo(self.containerView);
            // 上一个按钮为空, 则按钮大小可以为图片大小, 后续的按钮与第一个按钮大小保持一致
            if (lastButton) {
                make.width.height.equalTo(lastButton);
                make.top.equalTo(lastButton.bjl_bottom).offset(2.0);
            }
            else {
                make.top.equalTo(self.containerView.bjl_top).offset([BJLIcAppearance sharedAppearance].toolboxButtonSpace);
                make.width.height.lessThanOrEqualTo(@(24.0));
                make.width.height.equalTo(@(24.0)).priorityHigh();
            }
            if (button == buttons.lastObject) {
                // 最后一个 button 底部约束
                make.bottom.equalTo(self.containerView).offset(-[BJLIcAppearance sharedAppearance].toolboxButtonSpace);
            }
        }];
        lastButton = button;
    }
}

@end
