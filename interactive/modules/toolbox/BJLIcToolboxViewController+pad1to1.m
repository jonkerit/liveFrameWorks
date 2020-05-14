//
//  BJLIcToolboxViewController+pad1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController+pad1to1.h"
#import "BJLIcToolboxViewController+private.h"

@implementation BJLIcToolboxViewController (pad1to1)

- (void)remakePad1to1ContainerViewForTeacherOrAssistant {
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
        make.bottom.equalTo(self.view).offset(-23.0);
        make.left.equalTo(self.view.bjl_left).offset(24.0);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolboxWidth));
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
    
    NSArray *buttons = self.room.loginUser.isTeacher ? [self teacherButtons] : [self assistantButtons];
    [self remakePad1to1ConstraintsWithButtons:buttons];
    [self.view addSubview:self.singleLine];
    [self.singleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.paletteButton.bjl_right).offset(5.0);
        make.centerY.equalTo(self.containerView);
        make.width.equalTo(@1.0);
        make.height.equalTo(self.containerView).multipliedBy(0.6);
    }];
}

- (void)remakePad1to1ContainerViewForStudent {
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
        make.bottom.equalTo(self.view).offset(-23.0);
        make.centerX.equalTo(self.view);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolboxWidth));
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
    
    NSArray *buttons = [self studentButtons];
    [self remakePad1to1ConstraintsWithButtons:buttons];
}

- (void)remakePad1to1ConstraintsWithButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.bottom.equalTo(self.containerView);
            // 上一个按钮为空, 则按钮大小可以为图片大小, 后续的按钮与第一个按钮大小保持一致
            if (lastButton) {
                make.width.height.equalTo(lastButton);
            }
            else {
                make.width.height.lessThanOrEqualTo(@([BJLIcAppearance sharedAppearance].buttonSize));
                make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize)).priorityHigh();
            }
            make.left.equalTo(lastButton.bjl_right ?: self.containerView.bjl_left).offset([BJLIcAppearance sharedAppearance].toolboxButtonSpace);
            if (button == buttons.lastObject) {
                // 最后一个 button 右边约束
                make.right.equalTo(self.containerView).offset(-[BJLIcAppearance sharedAppearance].toolboxButtonSpace);
            }
        }];
        lastButton = button;
    }
}

@end
