//
//  BJLIcToolbarViewController+phone1to1.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+phone1to1.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (phone1to1)

- (void)makePhone1to1Subviews {
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view.userInteractionEnabled = NO;
        view;
    });
    // 包含媒体按钮
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
}

- (void)remakePhone1to1ContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    [self remakePhone1to1ConstraintsWithOptionButtons:optionButtons];
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.view.bjl_bottom).multipliedBy(3.0/4.0);
        make.left.width.equalTo(self.backgroundView);
    }];
    [self remakePhone1to1ConstraintsWithMediaButtons:mediaButtons];
}

- (void)remakePhone1to1ContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    [self remakePhone1to1ConstraintsWithOptionButtons:optionButtons];
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.backgroundView.bjl_bottom).multipliedBy(3.0/4.0);
        make.left.width.equalTo(self.backgroundView);
    }];
    [self remakePhone1to1ConstraintsWithMediaButtons:mediaButtons];
    
    self.speakRequestButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    self.speakRequestButton.layer.cornerRadius = [BJLIcAppearance sharedAppearance].toolbarLargeSpace / 2;
    self.speakRequestButton.layer.masksToBounds = YES;
    self.speakRequestButton.layer.borderWidth = 1.0;
    self.speakRequestButton.layer.borderColor = [UIColor bjl_colorWithHexString:@"#999999" alpha:0.3].CGColor;
    [self.view addSubview:self.speakRequestButton];
    [self.speakRequestButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view).offset(4.0);
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
        make.bottom.equalTo(self.view).offset(-11.0);
    }];
    [self.view addSubview:self.speakRequestProgressView];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.speakRequestButton).inset(2.0);
    }];
}

- (void)remakePhone1to1ConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in buttons) {
        [self.containerView addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.containerView);
            make.width.equalTo(@24.0);
            make.height.equalTo(button.bjl_width);
            if (lastMediaButton) {
                make.top.equalTo(lastMediaButton.bjl_bottom).offset(8.0);
            }
            else {
                make.top.equalTo(self.containerView);
            }
            if (button == buttons.lastObject) {
                make.bottom.equalTo(self.containerView);
            }
        }];
        lastMediaButton = button;
    }
}

- (void)remakePhone1to1ConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.backgroundView);
            if (lastButton) {
                make.width.height.equalTo(lastButton);
                make.top.equalTo(lastButton.bjl_bottom).offset(8.0);
            }
            else {
                make.width.height.equalTo(@(24.0));
                make.top.equalTo(self.view.bjl_top).offset(16.0);
            }
        }];
        lastButton = button;
    }
}

@end
