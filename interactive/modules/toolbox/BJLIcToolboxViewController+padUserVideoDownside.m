//
//  BJLIcToolboxViewController+padUserVideoDownside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController+padUserVideoDownside.h"
#import "BJLIcToolboxViewController+private.h"

@implementation BJLIcToolboxViewController (padUserVideoDownside)

- (void)remakePadUserVideoDownsideContainerViewForTeacherOrAssistant {
    UIView *referenceView = nil;
    if (self.requestReferenceViewCallback) {
        referenceView = self.requestReferenceViewCallback();
    }
    if (!referenceView) {
        return;
    }

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
    if (BJLIcTeacheVideoPosition_downside == self.room.roomInfo.interactiveClassTeacherVideoPosition) {
        [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(referenceView);
            make.width.lessThanOrEqualTo(referenceView).multipliedBy(0.6);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolboxWidth));
            make.top.equalTo(referenceView).offset([BJLIcAppearance sharedAppearance].toolboxButtonSpace);
        }];
    }
    else {
        [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(referenceView);
            make.bottom.lessThanOrEqualTo(referenceView);
            make.width.lessThanOrEqualTo(referenceView).multipliedBy(0.6);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolboxWidth)).priorityHigh();
            make.bottom.equalTo(referenceView).offset(-[BJLIcAppearance sharedAppearance].toolboxButtonSpace).priorityHigh();
            make.top.greaterThanOrEqualTo(referenceView.bjl_centerY);
        }];
    }
    
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 10.0;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
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
    [self remakePadUserVideoDownsideConstraintsWithButtons:buttons];
    [self.view addSubview:self.singleLine];
    [self.singleLine bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.paletteButton.bjl_right).offset(5.0);
        make.centerY.equalTo(self.containerView);
        make.width.equalTo(@1.0);
        make.height.equalTo(self.containerView).multipliedBy(0.6);
    }];
}

- (void)remakePadUserVideoDownsideContainerViewForStudent {
    UIView *referenceView = nil;
    if (self.requestReferenceViewCallback) {
        referenceView = self.requestReferenceViewCallback();
    }
    if (!referenceView) {
        return;
    }
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
    if (BJLIcTeacheVideoPosition_downside == self.room.roomInfo.interactiveClassTeacherVideoPosition) {
        [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(referenceView);
            make.width.lessThanOrEqualTo(referenceView).multipliedBy(0.6);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolboxWidth));
            make.top.equalTo(referenceView).offset([BJLIcAppearance sharedAppearance].toolboxButtonSpace);
        }];
    }
    else {
        [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(referenceView);
            make.bottom.lessThanOrEqualTo(referenceView);
            make.width.lessThanOrEqualTo(referenceView).multipliedBy(0.6);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolboxWidth)).priorityHigh();
            make.bottom.equalTo(referenceView).offset(-[BJLIcAppearance sharedAppearance].toolboxButtonSpace).priorityHigh();
            make.top.greaterThanOrEqualTo(referenceView.bjl_centerY);
        }];
    }
    
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
    [self remakePadUserVideoDownsideConstraintsWithButtons:buttons];
}

- (void)remakePadUserVideoDownsideConstraintsWithButtons:(NSArray *)buttons {
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
