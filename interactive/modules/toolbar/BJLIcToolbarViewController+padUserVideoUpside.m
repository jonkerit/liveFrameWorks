//
//  BJLIcToolbarViewController+padUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+padUserVideoUpside.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (padUserVideoUpside)

- (void)makePadUserVideoUpsideSubviews {
    self.view.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
    // ipad 整个背景是模糊效果
    self.backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view;
    });
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
}

- (void)remakePadUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    // 优先布局媒体控制按钮
    [self remakePadUserVideoUpsideConstraintsWithMediaButtons:mediaButtons];
    // ipad 的 containerView 仅包括一般操作按钮
    [self.view addSubview:self.containerView];
    [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolbarButtonWidth));
        make.left.greaterThanOrEqualTo(self.cameraButton.bjl_right);
        make.right.centerY.equalTo(self.view);
        make.width.equalTo(@(([BJLIcAppearance sharedAppearance].toolbarButtonWidth + [BJLIcAppearance sharedAppearance].toolbarLargeSpace)  * optionButtons.count)).priorityHigh();
    }];
    // 布局一般操作按钮
    [self remakePadUserVideoUpsideConstraintsWithOptionButtons:optionButtons];
}

- (void)remakePadUserVideoUpsideContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self remakePadUserVideoUpsideConstraintsWithMediaButtons:mediaButtons];
    // 举手按钮
    [self.view addSubview:self.speakRequestButton];
    [self.speakRequestButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarButtonWidth));
        make.centerY.equalTo(self.view);
        make.right.equalTo(self.view).offset(-30.0);
    }];
    [self.speakRequestButton addSubview:self.speakRequestProgressView];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton).inset(2.0);
    }];
    // 学生的聊天按钮没有标题
    [self.chatListButton setTitle:nil forState:UIControlStateNormal];
    [self.chatListButton setTitle:nil forState:UIControlStateHighlighted];
    [self.chatListButton setTitle:nil forState:UIControlStateSelected];
    [self.chatListButton setTitle:nil forState:UIControlStateHighlighted | UIControlStateSelected];
    [self.view addSubview:self.chatListButton];
    [self.chatListButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
        make.right.equalTo(self.speakRequestButton.bjl_left).offset(-[BJLIcAppearance sharedAppearance].toolbarMediumSpace);
        make.centerY.equalTo(self.view);
    }];
}

- (void)remakePadUserVideoUpsideConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            // ipad 布局基于整个 view
            make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
            make.left.greaterThanOrEqualTo(lastMediaButton.bjl_right?:self.view.bjl_left);
            if (lastMediaButton) {
                make.left.equalTo(lastMediaButton.bjl_right).offset([BJLIcAppearance sharedAppearance].toolbarMediumSpace / 2.0).priorityHigh();
            }
            else {
                make.left.equalTo(self.view.bjl_left).offset([BJLIcAppearance sharedAppearance].toolbarMediumSpace).priorityHigh();
            }
            make.centerY.equalTo(self.view);
        }];
        lastMediaButton = button;
    }
}

- (void)remakePadUserVideoUpsideConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        [self.containerView addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.bottom.equalTo(self.containerView);
            // ipad 按钮相对 containerView
            if (lastButton) {
                make.width.equalTo(lastButton);
                make.right.lessThanOrEqualTo(lastButton.bjl_left);
            }
            else {
                make.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarButtonWidth)).priorityHigh();
                make.right.lessThanOrEqualTo(self.containerView);
            }
        }];
        lastButton = button;
    }
}

@end
