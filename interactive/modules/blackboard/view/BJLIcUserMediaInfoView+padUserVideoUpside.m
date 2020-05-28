//
//  BJLIcUserMediaInfoView+padUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcUserMediaInfoView+padUserVideoUpside.h"
#import "BJLIcUserMediaInfoView+private.h"

@implementation BJLIcUserMediaInfoView (padUserVideoUpside)

- (void)makePadUserVideoUpsideSubviews {
    // 信息组合视图
    self.infoGroupView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.image = [UIImage bjlic_imageNamed:@"window_bottombar"];
        imageView.accessibilityLabel = @"infoGroupView";
        imageView;
    });
    [self addSubview:self.infoGroupView];
    [self.infoGroupView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.bottom.right.equalTo(self);
        make.height.equalTo(@20.0);
    }];
    
    // audio level
    self.audioLevelView = [self imageViewWithName:@"bjl_ic_audio_level_off"];
    self.audioLevelView.accessibilityLabel = BJLKeypath(self, audioLevelView);
    [self.infoGroupView addSubview:self.audioLevelView];
    [self.audioLevelView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.centerY.equalTo(self.infoGroupView);
        make.size.equal.sizeOffset(CGSizeMake(16.0, 20.0));
    }];
    
    // signal level
    self.signalLevelView = [self imageViewWithName:@"bjl_ic_signal_level_3"];
    self.signalLevelView.accessibilityLabel = BJLKeypath(self, signalLevelView);
    [self.infoGroupView addSubview:self.signalLevelView];
    [self.signalLevelView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.centerY.equalTo(self.infoGroupView);
        make.size.equal.sizeOffset(CGSizeMake(16.0, 20.0));
    }];
    
    // user name
    self.userNameLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.numberOfLines = 1;
        bjl_return label;
    });
    self.userNameLabel.accessibilityLabel = BJLKeypath(self, userNameLabel);
    [self.infoGroupView addSubview:self.userNameLabel];
    [self.userNameLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.audioLevelView.bjl_right);
        make.right.lessThanOrEqualTo(self.signalLevelView.bjl_left);
        make.centerY.equalTo(self.infoGroupView);
    }];
        
    self.groupColorView = ({
        UIView *colorView = [BJLHitTestView new];
        colorView.backgroundColor = [UIColor clearColor];
        colorView.accessibilityLabel = @"groupColorView";
        bjl_return colorView;
    });
    [self.infoGroupView addSubview:self.groupColorView];
    [self.groupColorView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.infoGroupView);
        make.height.equalTo(@(2));
    }];

    self.networkMessageLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.numberOfLines = 1;
        label.lineBreakMode = NSLineBreakByTruncatingMiddle;
        label.accessibilityLabel = BJLKeypath(self, networkMessageLabel);
        [self addSubview:label];
        label;
    });
    
    self.lossRateLable = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor bjl_ic_quiteBadNetColor];
        label.backgroundColor = [UIColor clearColor];
        label.numberOfLines = 1;
        label.lineBreakMode = NSLineBreakByTruncatingMiddle;
        label.accessibilityLabel = BJLKeypath(self, lossRateLable);
        [self addSubview:label];
        label;
    });
    
    self.likeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.font = [UIFont systemFontOfSize:10.0];
        button.layer.cornerRadius = 6.0;
        button.layer.masksToBounds = YES;
        button.enabled = self.room.loginUser.isTeacherOrAssistant;
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 4.0, 0.0, 4.0);
        button.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#F7E123"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_ic_like"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(sendLikeForCurrentUser) forControlEvents:UIControlEventTouchUpInside];
        button.hidden = YES;
        button;
    });
    self.likeButton.accessibilityLabel = BJLKeypath(self, likeButton);
    [self addSubview:self.likeButton];
    [self.likeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self).offset(4.0);
        make.bottom.equalTo(self.infoGroupView.bjl_top).offset(-2.0);
        make.height.equalTo(@16.0);
    }];

    self.webPPTAuthorizedView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.hidden = YES;
        imageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_webPPTAuthorized"];
        imageView;
    });
    self.webPPTAuthorizedView.accessibilityLabel = BJLKeypath(self, webPPTAuthorizedView);
    [self addSubview:self.webPPTAuthorizedView];
    [self.webPPTAuthorizedView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.likeButton.bjl_right).offset(4.0);
        make.bottom.equalTo(self.infoGroupView.bjl_top).offset(-2.0);
        make.width.height.equalTo(@0.0); // to update
    }];
    
    self.drawingGrantedView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.hidden = YES;
        imageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_drawingGranted"];
        imageView;
    });
    self.drawingGrantedView.accessibilityLabel = BJLKeypath(self, drawingGrantedView);
    [self addSubview:self.drawingGrantedView];
    [self.drawingGrantedView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.webPPTAuthorizedView.bjl_right).offset(0.0); // to update
        make.bottom.equalTo(self.infoGroupView.bjl_top).offset(-2.0);
        make.width.height.equalTo(@0.0); // to update
    }];
    
    self.speakRequestControlView = ({
        UIView *view = [UIView new];
        view.hidden = YES;
        view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        view;
    });
    self.speakRequestControlView.accessibilityLabel = BJLKeypath(self, speakRequestControlView);
    [self addSubview:self.speakRequestControlView];
    [self.speakRequestControlView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    // 举手
    self.speakRequestButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        button.hidden = YES;
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_ic_handup"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showSpeakRequestControlView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    self.speakRequestButton.accessibilityLabel = BJLKeypath(self, speakRequestButton);
    [self addSubview:self.speakRequestButton];
    [self.speakRequestButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(-15.0).priorityHigh();
        make.top.greaterThanOrEqualTo(self);
        make.bottom.lessThanOrEqualTo(self.infoGroupView.bjl_top);
        make.height.equalTo(@54.0).priorityHigh();
        make.width.equalTo(self.speakRequestButton.bjl_height);
    }];
    
    self.allowSpeakRequestButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 4.0;
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle:@"同意" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(allowSpeakRequest) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    self.allowSpeakRequestButton.accessibilityLabel = BJLKeypath(self, allowSpeakRequestButton);
    [self.speakRequestControlView addSubview:self.allowSpeakRequestButton];
    [self.allowSpeakRequestButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.lessThanOrEqualTo(self.speakRequestControlView.bjl_centerX);
        make.right.equalTo(self.speakRequestControlView.bjl_centerX).offset(-12.0).priorityHigh();
        make.left.greaterThanOrEqualTo(self.speakRequestControlView);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize)).priorityHigh();
        make.top.greaterThanOrEqualTo(self.speakRequestControlView);
        make.bottom.lessThanOrEqualTo(self.speakRequestControlView);
        make.height.equalTo(@24.0).priorityHigh();
        make.centerY.equalTo(self.speakRequestControlView);
    }];
    
    self.refuseSpeakRequestButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 4.0;
        button.backgroundColor = [UIColor whiteColor];
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle:@"拒绝" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(refuseSpeakRequest) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    self.refuseSpeakRequestButton.accessibilityLabel = BJLKeypath(self, refuseSpeakRequestButton);
    [self.speakRequestControlView addSubview:self.refuseSpeakRequestButton];
    [self.refuseSpeakRequestButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.greaterThanOrEqualTo(self.speakRequestControlView.bjl_centerX);
        make.left.equalTo(self.speakRequestControlView.bjl_centerX).offset(12.0).priorityHigh();
        make.right.lessThanOrEqualTo(self.speakRequestControlView);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize)).priorityHigh();
        make.top.greaterThanOrEqualTo(self.speakRequestControlView);
        make.bottom.lessThanOrEqualTo(self.speakRequestControlView);
        make.height.equalTo(@24.0).priorityHigh();
        make.centerY.equalTo(self.speakRequestControlView);
    }];
}

@end
