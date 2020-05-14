//
//  BJLIcToolbarViewController+pad1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+pad1to1.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (pad1to1)

- (void)makePad1to1Subviews {
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    // 包含一般操作按钮，视图添加在 toolbox 上
    self.backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view.layer.cornerRadius = 10.0;
        view.layer.masksToBounds = YES;
        view;
    });
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
}

- (void)remakePad1to1ContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    UIView *referenceView;
    if (self.requestReferenceViewCallback) {
        referenceView = self.requestReferenceViewCallback();
    }
    if (!referenceView) {
        return;
    }
    [self.view addSubview:self.exitButton];
    [self.exitButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(15.0);
        make.centerY.equalTo(self.view);
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
    }];
    [self remakePad1to1ConstraintsWithMediaButtons:mediaButtons];
    
    [referenceView addSubview:self.backgroundView];
    [referenceView addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(referenceView).offset(-23.0);
        make.height.equalTo(@40.0);
        make.right.equalTo(referenceView.bjl_right).offset(-24.0);
        make.width.equalTo(@(optionButtons.count * 40.0 + (optionButtons.count - 1) * 8.0));
    }];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    [self remakePad1to1ConstraintsWithOptionButtons:optionButtons];
}

- (void)remakePad1to1ContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    UIView *referenceView;
    if (self.requestReferenceViewCallback) {
        referenceView = self.requestReferenceViewCallback();
    }
    if (!referenceView) {
        return;
    }
    [self.view addSubview:self.exitButton];
    [self.exitButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(15.0);
        make.centerY.equalTo(self.view);
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
    }];
    [self remakePad1to1ConstraintsWithMediaButtons:mediaButtons];
    
    self.speakRequestButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
    self.speakRequestButton.layer.cornerRadius = [BJLIcAppearance sharedAppearance].buttonSize / 2;
    self.speakRequestButton.layer.masksToBounds = YES;
    self.speakRequestButton.layer.borderWidth = 1.0;
    self.speakRequestButton.layer.borderColor = [UIColor bjl_colorWithHexString:@"#999999" alpha:0.3].CGColor;
    [referenceView addSubview:self.speakRequestButton];
    [self.speakRequestButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(referenceView).offset(-14.0);
        make.bottom.equalTo(referenceView).offset(-23.0);
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
    }];
    [self.speakRequestButton addSubview:self.speakRequestProgressView];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton).inset(2.0);
    }];
    
    self.chatListButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
    self.chatListButton.layer.cornerRadius = [BJLIcAppearance sharedAppearance].buttonSize / 2;
    self.chatListButton.layer.masksToBounds = YES;
    self.chatListButton.layer.borderWidth = 1.0;
    self.chatListButton.layer.borderColor = [UIColor bjl_colorWithHexString:@"#999999" alpha:0.3].CGColor;
    [referenceView addSubview:self.chatListButton];
    [self.chatListButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.speakRequestButton.bjl_left).offset(-17.0);
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
        make.bottom.equalTo(referenceView).offset(-23.0);
    }];
}

- (void)remakePad1to1ConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        [self.view addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.view);
            make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
            if (lastMediaButton) {
                make.right.equalTo(lastMediaButton.bjl_left);
            }
            else {
                make.right.equalTo(self.view.bjl_right).offset(-14.0);
            }
        }];
        lastMediaButton = button;
    }
}

- (void)remakePad1to1ConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        [self.containerView addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.containerView);
            if (lastButton) {
                make.width.height.equalTo(lastButton);
                make.right.equalTo(lastButton.bjl_left).offset(-8.0);
            }
            else {
                make.right.top.bottom.equalTo(self.containerView);
                make.width.equalTo(button.bjl_height);
            }
            if (lastButton == buttons.firstObject) {
                make.left.equalTo(self.containerView.bjl_left);
            }
        }];
        lastButton = button;
    }
}

@end
