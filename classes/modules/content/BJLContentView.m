//
//  BJLContentView.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-02-22.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import "BJLContentView.h"

#import "BJLViewImports.h"
#import "BJLPreviewsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLContentView ()

@property (nonatomic, readwrite) BJLPreviewItem *item;

@property (nonatomic, readwrite, nullable) UIView *content;
@property (nonatomic) UIButton *clearDrawingButton;
@property (nonatomic) UIImageView *nameShadowView;
@property (nonatomic) UIButton *nameView;
@property (nonatomic) UIButton *likeButton;

// 网络状态提示
@property (nonatomic, nullable) UIButton *networkMessageButton;

// 记录上一次取值，如果 update 时一样则不重新 layout
@property (nonatomic, readwrite) BJLContentMode contentMode;
@property (nonatomic, readwrite) CGFloat aspectRatio;

@end

@implementation BJLContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self makeSubviews];
        
        bjl_weakify(self);
        [self addGestureRecognizer:[UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (self.toggleTopBarCallback) self.toggleTopBarCallback(nil);
        }]];
        [self addGestureRecognizer:[UILongPressGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (self.showMenuCallback) self.showMenuCallback(nil);
        }]];
    }
    return self;
}

- (void)makeSubviews {
    bjl_weakify(self);
    
    self.clearDrawingButton = ({
        BJLButton *button = [BJLButton new];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_clearall"] forState:UIControlStateNormal];
        [button setTitle:@"清除" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:15.0];
        // !!!: should be same to `BJLRoomViewController.pageControlButton.backgroundColor`
        button.backgroundColor = [UIColor bjl_dimColor];
        button.layer.cornerRadius = BJLButtonSizeM / 2;
        button.layer.masksToBounds = YES;
        button.midSpace = BJLViewSpaceS;
        [self addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(self).with.offset(BJLViewSpaceM);
            make.width.equalTo(@(BJLButtonSizeM * 2 + BJLViewSpaceM));
            make.bottom.equalTo(self).with.offset(- BJLViewSpaceM);
            make.height.equalTo(@(BJLButtonSizeM));
        }];
        button;
    });
    [self bjl_kvo:BJLMakeProperty(self, showsClearDrawingButton)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.clearDrawingButton.hidden = !self.showsClearDrawingButton;
             return YES;
         }];
    [self.clearDrawingButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (self.clearDrawingCallback) self.clearDrawingCallback(self);
    }];
    
    self.nameShadowView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.image = [UIImage bjl_imageNamed:@"bjl_bg_name"];
        [self addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.height.equalTo(@24.0);
        }];
        imageView;
    });
    
    self.nameView = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        button.titleLabel.textAlignment = NSTextAlignmentLeft;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.top.left.equalTo(self.nameShadowView).offset(5.0);
            make.bottom.equalTo(self.nameShadowView).offset(-5.0);
        }];
        button;
    });
    
    self.likeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.layer.cornerRadius = 9.0;
        button.layer.masksToBounds = YES;
        button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 8.0, 0.0, 8.0);
        [button setTitle:@"" forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor bjl_dimColor]] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#F7E123"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_like_icon"] forState:UIControlStateNormal];
        [self addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.equalTo(self).offset(4.0);
            make.bottom.equalTo(self.nameView.bjl_top).offset(-4.0);
            make.height.equalTo(@(18.0));
        }];
        button;
    });
    
    self.networkMessageButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_network_quiteBad"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_network_extremelyBad"] forState:UIControlStateHighlighted];
        button.layer.masksToBounds = YES;
        [button setTitleColor:[UIColor bjl_quiteBadNetColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_extremeBadNetColor] forState:UIControlStateHighlighted];

        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        button.accessibilityLabel = BJLKeypath(self, networkMessageButton);
        [self addSubview:button];
        
        button;
    });
}

#pragma mark -

// KVO-setter
- (void)setContent:(nullable UIView *)content {
    if (content == self.content) {
        return;
    }
    
    if (self.content.superview == self) {
        [self.content removeFromSuperview];
    }
    
    self->_content = content;
    if (content) {
        [self insertSubview:content atIndex:0];
    }
}

- (void)updateWithPreviewItem:(BJLPreviewItem *)item {
    if ((item.view == self.content
         || item.viewController.view == self.content)
        && item.contentMode == self.contentMode
        && item.aspectRatio == self.aspectRatio) {
        return;
    }
    self.content = item.viewController.view ?: item.view;
    self.contentMode = item.contentMode;
    self.aspectRatio = item.aspectRatio;
    
    [self layoutContent:self.content contentMode:self.contentMode aspectRatio:self.aspectRatio];
    [self updateViewsWithItem:item];
}

- (void)updateViewsForHorizontal:(BOOL)isHorizontal {
    [self updateViewsWithItem:self.item];
}

- (void)removeContent {
    self.content = nil;
}

- (void)layoutContent:(UIView *)content
          contentMode:(BJLContentMode)contentMode
          aspectRatio:(CGFloat)aspectRatio {
    [content bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        if (contentMode == BJLContentMode_scaleToFill) {
            make.edges.equalTo(self);
        }
        else {
            make.center.equalTo(self);
            make.edges.equalTo(self).priorityHigh();
            make.width.equalTo(content.bjl_height).multipliedBy(aspectRatio);
            if (contentMode == BJLContentMode_scaleAspectFit) {
                make.width.height.lessThanOrEqualTo(self);
            }
            else { // contentMode == BJLContentMode_scaleAspectFill
                make.width.height.greaterThanOrEqualTo(self);
            }
        }
    }];
}

- (void)updateViewsWithItem:(BJLPreviewItem *)item {
    self.item = item;
    if (item.type == BJLPreviewsType_recording
        || item.type == BJLPreviewsType_playing) {
        BOOL hidden = BJLIsHorizontalUI(self);
        // 仅全屏的时候隐藏名字
        NSString *name = self.item.playingUser.displayName ?: item.loginUser.displayName;
        // 全屏播放的用户是当前主讲人, 采集视频不显示
        if ([item.currentPresent isSameUser:item.playingUser] || item.playingUser.isTeacherOrAssistant) {
            name = (item.playingUser.cameraType == BJLCameraType_main
                    ? [NSString stringWithFormat:@"%@(%@)",
                       self.item.playingUser.displayName,
                       (item.playingUserRoleName ?: (self.item.playingUser.isTeacher ? @"老师" : @"主讲"))]
                    : BJLVideoTitleWithMediaSource(self.item.playingUser.mediaSource));
        }
        [self.nameView setTitle:name forState:UIControlStateNormal];
        self.nameShadowView.hidden = hidden;
        self.nameView.hidden = hidden;
        
        // 更新点赞数, 横屏不显示, 登录用户是学生，用户点赞数为0不显示, 采集用户不是学生不显示, 播放用户不是学生不显示
        if ((!item.likeCount && item.loginUser.isStudent)
            || (item.type == BJLPreviewsType_recording && item.loginUser.isTeacherOrAssistant)
            || (item.type == BJLPreviewsType_playing && item.playingUser.isTeacherOrAssistant)) {
            hidden = YES;
        }
        [self.likeButton setTitle:[NSString stringWithFormat:@"%ld", (long)self.item.likeCount] forState:UIControlStateNormal];
        self.likeButton.hidden = hidden;
    }
    else {
        self.nameShadowView.hidden = YES;
        self.nameView.hidden = YES;
        self.likeButton.hidden = YES;
    }
}

- (void)updateViewWithNetWorkLossRateStatus:(BJLNetworkStatus)status {
    // level1, level2, level3, level4时需要提示
    BOOL show = BJLNetworkStatus_normal != status;
    [self.networkMessageButton setHidden:!show];
    if(!show)
        return;
    
    BOOL highlighted = BJLNetworkStatus_Bad_level3 == status || BJLNetworkStatus_Bad_level4 == status || BJLNetworkStatus_Bad_level5 == status;
    [self.networkMessageButton setHighlighted:highlighted];
    if(highlighted) {
        [self.networkMessageButton setTitle:@"网络极差" forState:UIControlStateHighlighted];
    }
    else {
        NSString *message = (BJLNetworkStatus_Bad_level1 == status) ? @"网络较差" : @"网络差";
        [self.networkMessageButton setTitle:message forState:UIControlStateNormal];
    }
    
    if(self.content && show) {
        //bottom约束 是为了保证网络提示不被页面底部的控制按钮遮挡
        [self.networkMessageButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.content).offset(- BJLViewSpaceM);
            make.left.greaterThanOrEqualTo(self.content).with.offset(BJLViewSpaceM);
            make.height.equalTo(@(15));
            make.bottom.equalTo(self.content).offset(-(BJLButtonSizeM + 2 * BJLViewSpaceM));
        }];
    }
}

@end

NS_ASSUME_NONNULL_END
