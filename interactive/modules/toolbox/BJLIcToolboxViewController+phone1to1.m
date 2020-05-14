//
//  BJLIcToolboxViewController+phone1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController+phone1to1.h"
#import "BJLIcToolboxViewController+private.h"

@implementation BJLIcToolboxViewController (phone1to1)

- (void)remakePhone1to1ContainerViewForTeacherOrAssistant {
    [self remakePhone1to1ContainerViewForStudent];
}

- (void)remakePhone1to1ContainerViewForStudent {
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
        make.right.equalTo(self.view).offset(-4.0);
        make.centerY.equalTo(self.view);
        make.height.lessThanOrEqualTo(self.view);
        make.width.equalTo(@(32.0));
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
    [self remakePhone1to1ConstraintsWithButtons:buttons];
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

- (void)remakePhone1to1ConstraintsWithButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.centerX.equalTo(self.containerView);
            // 上一个按钮为空, 则按钮大小可以为图片大小, 后续的按钮与第一个按钮大小保持一致
            if (lastButton) {
                make.top.equalTo(lastButton.bjl_bottom).offset(2.0);
                make.width.height.equalTo(lastButton);
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
