//
//  BJLIcUserSeatCell.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcUserSeatCell.h"
#import "BJLIcAppearance.h"
#import "BJLUser+BJLInteractiveClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserSeatCell ()

// placehoder
@property (nonatomic) UIView *placeholderView;
@property (nonatomic) UILabel *placeholderLabel;

// media info
@property (nonatomic, readwrite) UIView *mediaInfoContainerView;

@end

@implementation BJLIcUserSeatCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        bjl_weakify(self);
        [self bjl_kvo:BJLMakeProperty(self, reuseIdentifier)
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (self.reuseIdentifier) {
                     [self setupSubviews];
                     [self prepareForReuse];
                     return NO;
                 }
                 return YES;
             }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *subView in self.mediaInfoContainerView.subviews) {
        [subView removeFromSuperview];
    }
}

#pragma mark - subviews

- (void)setupSubviews {    
    BOOL enlargeVideo = [self.reuseIdentifier isEqualToString:cellReuseIdentifierFor1to1];
    CGFloat videoRatio = 3.0 / 4.0;
    // 占位视图
    self.placeholderView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
        view.userInteractionEnabled = NO;
        view.accessibilityLabel = BJLKeypath(self, placeholderView);
        bjl_return view;
    });
    [self.contentView addSubview:self.placeholderView];
    [self.placeholderView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        if (enlargeVideo) {
            make.left.right.top.equalTo(self.contentView);
            make.height.equalTo(self.placeholderView.bjl_width).multipliedBy(videoRatio);
        }
        else {
            make.edges.equalTo(self.contentView);
        }
    }];
    
    // 毛玻璃背景
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.userInteractionEnabled = NO;
    [self.placeholderView addSubview:effectView];
    [effectView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.placeholderView);
    }];
    
    UIImageView *placeholderImageView = ({
        UIImage *image = [UIImage bjlic_imageNamed:@"bjl_ic_user_placeholder"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.accessibilityLabel = @"placeholderImageView";
        bjl_return imageView;
    });
    [self.placeholderView addSubview:placeholderImageView];
    [placeholderImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.placeholderView);
    }];
    
    UIView *placeholderGroupView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor blackColor];
        view.alpha = 0.6;
        view.accessibilityLabel = @"placeholderGroupView";
        bjl_return view;
    });
    [self.placeholderView addSubview:placeholderGroupView];
    [placeholderGroupView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        if (enlargeVideo) {
            make.left.right.equalTo(self.placeholderView);
            make.top.equalTo(self.placeholderView.bjl_bottom);
            make.height.equalTo(@40.0);
        }
        else {
            make.left.bottom.right.equalTo(self.placeholderView);
            make.height.equalTo(@20.0);
        }
    }];
    
    self.placeholderLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12.0];
        label.numberOfLines = 1;
        label.accessibilityLabel = BJLKeypath(self, placeholderLabel);
        bjl_return label;
    });
    [placeholderGroupView addSubview:self.placeholderLabel];
    [self.placeholderLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.greaterThanOrEqualTo(placeholderGroupView);
        make.right.lessThanOrEqualTo(placeholderGroupView);
        make.center.equalTo(placeholderGroupView);
        make.height.equalTo(@14.0);
    }];
    
    self.mediaInfoContainerView = ({
        UIView *view = [[UIView alloc] init];
        // 单击 离开/回到 座位
        bjl_weakify(self);
        UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (self.singleTapCallback) {
                self.singleTapCallback();
            }
        }];
        [self.contentView addGestureRecognizer:tapGesture];
        view;
    });
    [self.contentView addSubview:self.mediaInfoContainerView];
    [self.mediaInfoContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        if (enlargeVideo) {
            make.top.left.right.equalTo(self.contentView);
            make.bottom.equalTo(self.contentView).offset(-40.0);
        }
        else {
            make.edges.equalTo(self.contentView);
        }
    }];
}

#pragma mark - public

- (void)updateContentWithUser:(BJLUser *)user leavSeat:(BOOL)leaveSeat {
    // 占位视图
    self.placeholderView.hidden = !leaveSeat;
    self.placeholderLabel.text = (user && ![self.reuseIdentifier isEqualToString:cellReuseIdentifierFor1to1]) ? [NSString stringWithFormat:@"%@的座位", user.displayName] : nil;
}

@end

NS_ASSUME_NONNULL_END
