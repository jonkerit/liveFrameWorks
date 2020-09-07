//
//  BJLScRoomViewController+constraints.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController+constraints.h"
#import "BJLScRoomViewController+private.h"

@implementation BJLScRoomViewController (constraints)

#pragma mark - layout

- (void)makeConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    #pragma mark -- 移除VC
    for (UIView *tempView in self.view.subviews) {
        [tempView removeFromSuperview];
    }
    [self removeFromParentViewController];
    
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0XF7F7F7];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        bjl_return view;
    });
    self.topBarView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, topBarView);
        bjl_return view;
    });
    self.seperatorView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, seperatorView);
        view.backgroundColor = [UIColor bjl_colorWithHex:0XF7F7F7];
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.1;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(-2.0, 0.0);
        view.layer.shadowRadius = 2.0;
        bjl_return view;
    });
    self.minorContentView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, minorContentView);
        view.backgroundColor = [UIColor blackColor];
        if (!self.is1V1Class || !iPhone) {
            view.layer.masksToBounds = NO;
            view.layer.shadowOpacity = 0.1;
            view.layer.shadowColor = [UIColor blackColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(-2.0, 0.0);
            view.layer.shadowRadius = 2.0;
        }
        bjl_return view;
    });
    self.secondMinorContentView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, secondMinorContentView);
        view.backgroundColor = [UIColor blackColor];
        if (!self.is1V1Class || !iPhone) {
            view.layer.masksToBounds = NO;
            view.layer.shadowOpacity = 0.1;
            view.layer.shadowColor = [UIColor blackColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(-2.0, 0.0);
            view.layer.shadowRadius = 2.0;
        }
        bjl_return view;
    });
    
    self.teacherVideoPlaceholderView = ({
        BJLScVideoPlaceholderView *view = [[BJLScVideoPlaceholderView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_leaveClass"] tip:@"老师不在教室"];
        view.accessibilityLabel = BJLKeypath(self, teacherVideoPlaceholderView);
        view.hidden = YES;
        bjl_return view;
    });
    self.secondMinorVideoPlaceholderView = ({
        BJLScVideoPlaceholderView *view =[[BJLScVideoPlaceholderView alloc] initWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_leaveClass"] tip:@"当前没有学生发言"];
        view.accessibilityLabel = BJLKeypath(self, secondMinorVideoPlaceholderView);
        view.hidden = YES;
        bjl_return view;
    });
    
    self.segmentView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, segmentView);
        bjl_return view;
    });
    self.videosView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, videosView);
        bjl_return view;
    });
    self.majorContentView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, majorContentView);
        bjl_return view;
    });
    self.toolView = ({
        BJLHitTestView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, toolView);
        bjl_return view;
    });
    self.lampView = ({
        BJLHitTestView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, lampView);
        view.clipsToBounds = YES;
        bjl_return view;
    });
    self.imageViewLayer = ({
        BJLHitTestView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, imageViewLayer);
        bjl_return view;
    });
    self.timerLayer = ({
        BJLHitTestView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, timerLayer);
        bjl_return view;
    });
    self.teachAidLayer = ({
        BJLHitTestView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, teachAidLayer);
        bjl_return view;
    });
    self.overlayView = ({
        BJLHitTestView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, overlayView);
        bjl_return view;
    });

    [self.view insertSubview:self.containerView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.majorContentView belowSubview:self.loadingLayer];
    if (self.is1V1Class) {
        [self.view insertSubview:self.seperatorView belowSubview:self.loadingLayer];
    }
    [self.view insertSubview:self.minorContentView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.secondMinorContentView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.teacherVideoPlaceholderView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.secondMinorVideoPlaceholderView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.videosView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.segmentView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.toolView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.topBarView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.lampView belowSubview:self.loadingLayer];
    [self.view insertSubview:self.imageViewLayer belowSubview:self.loadingLayer];
    [self.view insertSubview:self.timerLayer belowSubview:self.loadingLayer];
    [self.view insertSubview:self.teachAidLayer belowSubview:self.loadingLayer];
    [self.view insertSubview:self.overlayView belowSubview:self.loadingLayer];
    
    [self updateConstraints];
}
- (void)updateConstraints{
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (iPhone) {
        [self makePhoneConstraints];
    }
    else {
        [self makePadConstraints];
    }
    
    [self makeCommonConstraints];
}
/**   pad 结构 基于 4:3 布局，视频基于 16:9 布局，1V1 使用 4:3，课件基于 4:3 显示最优
                     状态栏
            包含标题等自定义的topbar，固定高度
            视频列表，固定高度       老师主摄像头，固定宽度
            课件                  聊天等内容，固定宽度
                常显示操作按钮，可点击隐藏
 */
- (void)makePadConstraints {
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.center.bottom.equalTo(self.view);
        make.width.equalTo(self.view.bjl_height).multipliedBy(4.0 / 3.0);
    }];
    
    [self.topBarView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        // 仅处理状态栏，此处也可以都直接替换成状态栏高度
        make.top.equalTo(self.containerView.bjl_safeAreaLayoutGuide ?: self.bjl_topLayoutGuide);
        make.left.right.equalTo(self.containerView);
        make.height.equalTo(@(BJLScTopBarHeight));
    }];
    
    if (self.is1V1Class) {
        [self.seperatorView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.bottom.equalTo(self.containerView);
            make.top.equalTo(self.topBarView.bjl_bottom);
            make.width.equalTo(@(BJLScSegmentWidth));
        }];
        
        [self.minorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.containerView);
            make.top.equalTo(self.topBarView.bjl_bottom).offset(16.0);
            make.width.equalTo(@(BJLScSegmentWidth));
            make.height.equalTo(self.minorContentView.bjl_width).multipliedBy(3.0 / 4.0);
        }];
        
        [self.secondMinorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.containerView);
            make.top.equalTo(self.minorContentView.bjl_bottom).offset(16.0);
            make.width.equalTo(@(BJLScSegmentWidth));
            make.height.equalTo(self.secondMinorContentView.bjl_width).multipliedBy(3.0 / 4.0);
        }];
        
        [self.segmentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.bottom.equalTo(self.containerView);
            make.top.equalTo(self.secondMinorContentView.bjl_bottom).offset(16.0);
            make.width.equalTo(@(BJLScSegmentWidth));
        }];
        
        [self.majorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.bottom.equalTo(self.containerView);
            make.top.equalTo(self.topBarView.bjl_bottom);
            make.right.equalTo(self.segmentView.bjl_left);
        }];
    }
    else {
        [self.minorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.containerView);
            make.top.equalTo(self.topBarView.bjl_bottom);
            make.width.equalTo(@(BJLScSegmentWidth));
            make.height.equalTo(self.minorContentView.bjl_width).multipliedBy(9.0 / 16.0);
        }];
        
        [self.segmentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.bottom.equalTo(self.containerView);
            make.top.equalTo(self.minorContentView.bjl_bottom);
            make.width.equalTo(@(BJLScSegmentWidth));
        }];
        
        [self.videosView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.topBarView.bjl_bottom);
            make.left.equalTo(self.containerView);
            make.right.equalTo(self.segmentView.bjl_left);
            make.height.equalTo(@0.0);
        }];
        
        [self.majorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.bottom.equalTo(self.containerView);
            make.top.equalTo(self.videosView.bjl_bottom);
            make.right.equalTo(self.segmentView.bjl_left);
        }];
    }
}

/**   phone 结构 基于 16:9 布局，视频基于 16:9 布局，1V1 使用 4:3，课件基于 4:3 显示最优
                    状态栏隐藏
           包含标题等自定义的topbar，固定高度，但不占据布局高度，可点击隐藏
           视频列表，固定高度                 老师主摄像头，宽度为设备宽度的 4/16
           课件，宽度为设备宽度的 12/16        聊天等内容，宽度为设备宽度的 4/16
               常显示操作按钮，可点击隐藏
*/
- (void)makePhoneConstraints {
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.center.bottom.equalTo(self.view);
        make.width.equalTo(self.view.bjl_width);
    }];
    
    [self.topBarView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        // 仅处理状态栏，此处也可以都直接替换成状态栏高度
        make.top.equalTo(self.containerView.bjl_safeAreaLayoutGuide ?: self.bjl_topLayoutGuide);
        make.left.right.equalTo(self.containerView);
        make.height.equalTo(@(BJLScTopBarHeight));
    }];
    
    if (self.is1V1Class) {
        [self.majorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.bottom.equalTo(self.containerView);
            make.top.equalTo(self.topBarView.bjl_bottom);
            make.width.equalTo(self.majorContentView.bjl_height).multipliedBy(4.0 / 3.0);
        }];
        
        [self.seperatorView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.bottom.equalTo(self.containerView);
            make.top.equalTo(self.topBarView.bjl_bottom);
            make.left.equalTo(self.majorContentView.bjl_right);
        }];
        
        [self.minorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.left.equalTo(self.seperatorView);
            make.height.equalTo(self.minorContentView.bjl_width).multipliedBy(3.0 / 4.0);
        }];
        
        [self.secondMinorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.minorContentView.bjl_bottom).offset(1.0);
            make.left.right.equalTo(self.seperatorView);
            make.height.equalTo(self.secondMinorContentView.bjl_width).multipliedBy(3.0 / 4.0);
        }];
        
        [self.segmentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.seperatorView);
        }];
    }
    else {
        [self.minorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.equalTo(self.containerView);
            make.width.equalTo(self.containerView).multipliedBy(4.0 / 16.0);
            make.height.equalTo(self.minorContentView.bjl_width).multipliedBy(9.0 / 16.0);
        }];
        
        [self.segmentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.bottom.equalTo(self.containerView);
            make.top.equalTo(self.minorContentView.bjl_bottom);
            make.width.equalTo(self.containerView).multipliedBy(4.0 / 16.0);
        }];
        
        [self.videosView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.left.equalTo(self.containerView);
            make.right.equalTo(self.segmentView.bjl_left);
            make.height.equalTo(@0.0);
        }];
        
        [self.majorContentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.bottom.equalTo(self.containerView);
            make.top.equalTo(self.videosView.bjl_bottom);
            make.right.equalTo(self.segmentView.bjl_left);
        }];
    }
}

/** 不是一直显示的视图 一般铺满整个设备，不局限于布局的比例 */
- (void)makeCommonConstraints {
    [self.teacherVideoPlaceholderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.minorContentView);
    }];
    
    [self.secondMinorVideoPlaceholderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.secondMinorVideoPlaceholderView);
    }];
    
    [self.toolView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
    
    [self.lampView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.majorContentView);
    }];
    
    [self.imageViewLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.timerLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.teachAidLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - controllers

- (void)makeViewControllers {
    bjl_weakify(self);
    // top bar
    self.topBarViewController = [[BJLScTopBarViewController alloc] initWithRoom:self.room];
    // 需要在布局前设置block，否则无法判断是否显示分享
    if (self.delegate && [self.delegate respondsToSelector:@selector(roomViewControllerToShare:)]) {
        [self.topBarViewController setShareCallback:^{
            bjl_strongify(self);
            if (!self.enableShare) {
                return ;
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(roomViewControllerToShare:)]) {
                UIViewController *content = [self.delegate roomViewControllerToShare:self];
                if (content) {
                    [self.overlayViewController showWithContentViewController:content contentView:nil];
                    [content.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                        make.top.right.bottom.equalTo(self.overlayViewController.view);
                        make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
                    }];
                }
            }
        }];
    }
    [self bjl_addChildViewController:self.topBarViewController superview:self.topBarView];
    [self.topBarViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.topBarView);
    }];
    
    if (!self.is1V1Class) {
        // videos
        self.videosViewController = [[BJLScVideosViewController alloc] initWithRoom:self.room];
    }
    
    // sildeshow
    [self bjl_addChildViewController:self.room.slideshowViewController superview:self.majorContentView];
    self.room.slideshowViewController.shouldSwitchNativePPTBlock = ^(NSString * _Nullable documentID, void (^ _Nonnull callback)(BOOL)) {
        callback(YES);
    };
    self.room.slideshowViewController.imageSize = 1080;
    self.room.slideshowViewController.view.backgroundColor = [UIColor bjl_colorWithHexString:@"#F7F7F7" alpha:1.0];
    self.room.slideshowViewController.placeholderImage = [UIImage bjl_imageWithColor:[UIColor bjlsc_grayImagePlaceholderColor]];
    self.room.slideshowViewController.prevPageIndicatorImage = [UIImage bjlsc_imageNamed:@"bjl_sc_ppt_prev"];
    self.room.slideshowViewController.nextPageIndicatorImage = [UIImage bjlsc_imageNamed:@"bjl_sc_ppt_next"];
    self.room.slideshowViewController.pageControlButton = ({
        const CGFloat buttonWidth = 72.0, buttonHeight = 32.0;
        UIButton *button = [UIButton new];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        // !!!: should be same to `BJLContentView.clearDrawingButton.backgroundColor`
        [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor bjlsc_dimColor]]
                          forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage bjl_imageWithColor:[UIColor bjl_colorWithHexString:@"#89899C" alpha:0.5]]
                          forState:UIControlStateDisabled];
        button.layer.cornerRadius = buttonHeight / 2;
        button.layer.masksToBounds = YES;
        [button addTarget:self action:@selector(showQuickSlideViewController) forControlEvents:UIControlEventTouchUpInside];
        [self.room.slideshowViewController.view addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.centerX.equalTo(self.room.slideshowViewController.view);
            make.bottom.equalTo(self.room.slideshowViewController.view).offset(- 8.0);
            make.size.equal.sizeOffset(CGSizeMake(buttonWidth, buttonHeight));
        }];
        button;
    });
    [self.room.slideshowViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.majorContentView);
    }];
    
    if (self.is1V1Class) {
        self.chatViewController = [[BJLScChatViewController alloc] initWithRoom:self.room];
        // only chat
        BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
        if (iPad) {
            [self bjl_addChildViewController:self.chatViewController superview:self.segmentView];
            [self.chatViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.segmentView);
            }];
        }
        else {
            self.chatButton = ({
                UIButton *button = [UIButton new];
                button.backgroundColor = [UIColor clearColor];
                button.layer.borderWidth = 1.0;
                button.layer.borderColor = [UIColor bjl_colorWithHexString:@"#D0D0D0"].CGColor;
                button.layer.masksToBounds = YES;
                button.layer.cornerRadius = 2.0;
                button.imageView.contentMode = UIViewContentModeScaleAspectFit;
                button.titleLabel.font = [UIFont systemFontOfSize:12.0];
                [button setTitle:@"聊天" forState:UIControlStateNormal];
                [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_chat"] forState:UIControlStateNormal];
                button;
            });
            [self.segmentView addSubview:self.chatButton];
            [self.chatButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.right.bottom.equalTo(self.segmentView);
                make.top.equalTo(self.secondMinorContentView.bjl_bottom);
            }];
            self.chatRedDot = ({
                UILabel *redDot = [UILabel new];
                redDot.hidden = YES;
                redDot.layer.masksToBounds = YES;
                redDot.layer.cornerRadius = 4.0;
                redDot.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
                redDot.textColor = [UIColor whiteColor];
                redDot.textAlignment = NSTextAlignmentCenter;
                redDot.adjustsFontSizeToFitWidth = YES;
                redDot.font = [UIFont systemFontOfSize:10.0];
                redDot;
            });
            [self.chatButton addSubview:self.chatRedDot];
            [self.chatRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.chatButton.bjl_centerX);
                make.width.height.equalTo(@8.0);
                make.bottom.equalTo(self.chatButton.bjl_centerY);
            }];
        }
    }
    else {
        // segment
        self.segmentViewController = [[BJLScSegmentViewController alloc] initWithRoom:self.room];
        [self bjl_addChildViewController:self.segmentViewController superview:self.segmentView];
        [self.segmentViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.segmentView);
        }];
    }
    
    // tool
    [self makeToolView];
    
    // overlay
    self.overlayViewController = [[BJLScOverlayViewController alloc] initWithRoom:self.room];
}

- (void)makeToolView {
    bjl_weakify(self);
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    self.liveStartButton = ({
        UIButton *button = [UIButton new];
        button.hidden = YES;
        button.layer.cornerRadius = 8.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, liveStartButton);
        button.backgroundColor = [UIColor clearColor];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = CGRectMake(0.0, 0.0, 220.0, 56.0);
        gradientLayer.colors = @[(__bridge id)[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0].CGColor, (__bridge id)[UIColor bjl_colorWithHexString:@"#33C7FF" alpha:1.0].CGColor];
        gradientLayer.startPoint = CGPointMake(0.0, 0.0);
        gradientLayer.endPoint = CGPointMake(0.0, 1.0);
        gradientLayer.locations = @[@(0), @(1)];
        [button.layer insertSublayer:gradientLayer atIndex:0];
        button.titleLabel.font = [UIFont systemFontOfSize:24.0];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [button setTitle:@"开始上课" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button bjl_addHandler:^(UIButton * _Nonnull button) {
            bjl_strongify(self);
            BJLError *error = [self.room.roomVM sendLiveStarted:YES];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
        }];
        button;
    });
    [self.toolView addSubview:self.liveStartButton];
    [self.liveStartButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.majorContentView);
        make.width.equalTo(@220.0);
        make.height.equalTo(@56.0);
    }];
    
    if (!self.is1V1Class) {
        self.handUpButton.hidden = YES;
        self.videoButton.hidden = YES;
        self.audioButton.hidden = YES;
        self.handUpButton = ({
            UIButton *button = [UIButton new];
            button.accessibilityLabel = BJLKeypath(self, handUpButton);
            button.backgroundColor = [UIColor clearColor];
            [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_handup"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_handup_selected"] forState:UIControlStateSelected];
            [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_handup_selected"] forState:UIControlStateSelected | UIControlStateHighlighted];
            button;
        });
//        self.handUpButton.hidden = YES;
//        [self.toolView addSubview:self.handUpButton];
//
//        [self.handUpButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//            make.bottom.equalTo(self.majorContentView).offset(-BJLScViewSpaceM);
//            make.right.equalTo(self.majorContentView.bjl_right).offset(-6.0);
//            make.width.height.equalTo(@(BJLScControlSize));
//        }];
        
        self.opertionScreenBtn = ({
            UIButton *button = [UIButton new];
            button.accessibilityLabel = BJLKeypath(self, opertionScreenBtn);
            [button setImage:[UIImage bjlsc_imageNamed:@"bjlAllScreen"] forState:UIControlStateNormal];
            button;
        });
        [self.toolView addSubview:self.opertionScreenBtn];
        [self.opertionScreenBtn bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.majorContentView).offset(-BJLScViewSpaceS);
            make.right.equalTo(self.majorContentView.bjl_right).offset(-BJLScViewSpaceL);
            make.width.height.equalTo(@(36.0));
        }];
        self.changeScreenButton = ({
            UIButton *button = [UIButton new];
            button.accessibilityLabel = BJLKeypath(self, changeScreenButton);
            [button setImage:[UIImage bjlsc_imageNamed:@"bjlchange"] forState:UIControlStateNormal];
            button;
        });
        [self.toolView addSubview:self.changeScreenButton];
        [self.changeScreenButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.majorContentView).offset(-BJLScViewSpaceS);
            make.right.equalTo(self.opertionScreenBtn.bjl_left).offset(-25.0);
            make.width.height.equalTo(@(36.0));
        }];
        
//        self.handProgressView = ({
//            BJLAnnularProgressView *progressView = [BJLAnnularProgressView new];
//            progressView.size = BJLScButtonSizeS;
//            progressView.annularWidth = 2.0;
//            progressView.color = [UIColor whiteColor];
//            progressView.userInteractionEnabled = NO;
//            [self.handUpButton addSubview:progressView];
//            [progressView bjl_makeConstraints:^(BJLConstraintMaker *make) {
//                make.edges.equalTo(self.handUpButton);
//            }];
//            bjl_return progressView;
//        });
//
//        self.userSpeakRequestRedDot = ({
//            UILabel *view = [UILabel new];
//            view.accessibilityLabel = BJLKeypath(self, userSpeakRequestRedDot);
//            view.hidden = YES;
//            view.layer.masksToBounds = YES;
//            view.layer.cornerRadius = BJLScRedDotWidth / 2;
//            view.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
//            view.textColor = [UIColor whiteColor];
//            view.textAlignment = NSTextAlignmentCenter;
//            view.adjustsFontSizeToFitWidth = YES;
//            view.font = [UIFont systemFontOfSize:8.0];
//            bjl_return view;
//        });
//        [self.toolView addSubview:self.userSpeakRequestRedDot];
//        [self.userSpeakRequestRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//            make.top.equalTo(self.handUpButton).offset(10.0);
//            make.left.equalTo(self.handUpButton.bjl_centerX).offset(10.0);
//            make.height.width.equalTo(@(BJLScRedDotWidth));
//        }];
//
        self.noticeButton = ({
            UIButton *button = [UIButton new];
            button.accessibilityLabel = BJLKeypath(self, noticeButton);
            [button setImage:[UIImage bjlsc_imageNamed:@"bjlNotice"] forState:UIControlStateNormal];
            bjl_return button;
        });
        [self.toolView addSubview:self.noticeButton];
        [self.noticeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.toolView).offset(-BJLScViewSpaceS);
            make.left.equalTo(self.toolView).offset(BJLScViewSpaceL);
            make.width.height.equalTo(@(36.0));
        }];

        NSString *liveTabs = self.room.loginUser.isStudent ? self.room.featureConfig.liveTabsOfStudent : self.room.featureConfig.liveTabs;
        BOOL enableQuestion = [liveTabs containsString:@"answer"] && self.room.featureConfig.enableQuestion;
        if (enableQuestion) {
                self.questionButton = ({
                    UIButton *button = [UIButton new];
                    button.accessibilityLabel = BJLKeypath(self, questionButton);
                    [button setImage:[UIImage bjlsc_imageNamed:@"bjlAsk"] forState:UIControlStateNormal];
                    bjl_return button;
                });
            // to do
                self.questionRedDotHidden = NO;
                self.questionRedDot = ({
                    UILabel *view = [UILabel new];
                    view.accessibilityLabel = BJLKeypath(self, questionRedDot);
                    view.hidden = self.questionRedDotHidden;
                    view.layer.masksToBounds = YES;
                    view.layer.cornerRadius = 4;
                    view.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
                    view.textColor = [UIColor whiteColor];
                    view.textAlignment = NSTextAlignmentCenter;
                    view.adjustsFontSizeToFitWidth = YES;
                    view.font = [UIFont systemFontOfSize:8.0];
                    bjl_return view;
                });
            [self.toolView addSubview:self.questionButton];
            [self.toolView addSubview:self.questionRedDot];
            [self.questionButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.noticeButton.bjl_right).offset(25.0);
                make.top.bottom.width.equalTo(self.noticeButton);
            }];
            
            [self.questionRedDot bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.equalTo(self.questionButton).offset(10.0);
                make.left.equalTo(self.questionButton.bjl_centerX).offset(10.0);
                make.height.width.equalTo(@(8));
            }];
        }
    }
    
    self.documentToolView = ({
        BJLScToolView *view = [[BJLScToolView alloc] initWithRoom:self.room];
        view.hidden = self.documentToolHidden;
        view;
    });
    [self.toolView addSubview:self.documentToolView];
    [self.documentToolView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.majorContentView.bjl_right).offset(iPhone ? -8.0 : -16.0);
        make.top.equalTo(self.majorContentView.bjl_top).offset(16.0);
        make.height.equalTo(@(self.documentToolView.expectedSize.height)).priorityHigh();
        make.width.equalTo(@(self.documentToolView.expectedSize.width));
    }];

    self.videoButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, videoButton);
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_videoOff"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_videoOn"] forState:UIControlStateSelected];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_videoOn"] forState:UIControlStateSelected | UIControlStateHighlighted];
        button.hidden = YES;
        bjl_return button;
    });
    
    self.audioButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, videoButton);
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_audioOff"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_audioOn"] forState:UIControlStateSelected];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_audioOn"] forState:UIControlStateSelected | UIControlStateHighlighted];
        button.hidden = YES;
        bjl_return button;
    });
        
//    [self.toolView addSubview:self.videoButton];
//    [self.toolView addSubview:self.audioButton];
//
//    [self.videoButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//        make.bottom.equalTo(self.toolView).offset(-BJLScViewSpaceM);
//        if (self.handUpButton) {
//            make.right.equalTo(self.handUpButton.bjl_left);
//        }
//        else {
//            make.right.equalTo(self.majorContentView).offset(-8.0);
//        }
//        make.width.height.equalTo(@(BJLScControlSize));
//    }];
//    
//    [self.audioButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//        make.right.equalTo(self.videoButton.bjl_left);
//        make.bottom.equalTo(self.toolView).offset(-BJLScViewSpaceM);
//        make.width.height.equalTo(@(BJLScControlSize));
//    }];
}

#pragma mark - update

- (void)showQuickSlideViewController {
    self.pptQuickSlideViewController = [[BJLScPPTQuickSlideViewController alloc] initWithRoom:self.room];
    [self.overlayViewController showWithContentViewController:self.pptQuickSlideViewController contentView:nil];
    [self.pptQuickSlideViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.overlayViewController.view);
        make.height.equalTo(@100.0);
    }];
}

- (void)showQuestionInputView {
    // 输入控制器约束了高度，不需要在外部控制
    [self.questionInputViewController updateWithQuestion:nil];
    [self.overlayViewController showWithContentViewController:self.questionInputViewController contentView:nil];
    [self.questionInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.overlayViewController.view);
    }];
}

- (void)updateVideosViewHidden:(BOOL)hidden {
    if (hidden == self.videosView.hidden) {
        return;
    }
    if (hidden) {
        [self.videosViewController bjl_removeFromParentViewControllerAndSuperiew];
        [self.videosView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@0.0);
        }];
        self.videosView.hidden = YES;
        [self.videosViewController resetVideo];
        
        if (self.majorWindowType != BJLScWindowType_ppt
            && self.minorWindowType != BJLScWindowType_ppt) {
            [self replaceMajorContentViewWithPPTView];
        }
    }
    else {
        BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        [self.videosView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@(iPhone ? 72.0 : 135.0)); // 240 * 9.0 / 16.0 = 135.0
        }];
        [self bjl_addChildViewController:self.videosViewController superview:self.videosView];
        [self.videosViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.videosView);
        }];
        self.videosView.hidden = NO;
    }
}

- (void)updateTeacherVideoView {
    // 老师窗口保证主摄像头的user数据来初始化即可，除此之外只有在老师ID变更时才需要更新
    if (!self.teacherMediaInfoView
        || ![self.teacherMediaInfoView.user.ID isEqualToString:self.room.onlineUsersVM.onlineTeacher.ID]) {
        // 切换老师用户时需要移除
        if (self.teacherMediaInfoView) {
            [self.teacherMediaInfoView removeFromSuperview];
            [self.teacherMediaInfoView destroy];
            self.teacherMediaInfoView = nil;
        }

        if (self.room.loginUser.isTeacher) {
            self.teacherMediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:self.room.loginUser];
        }
        else {
            self.teacherMediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:self.room.onlineUsersVM.onlineTeacher];
        }
    }
    
    if (self.minorWindowType == BJLScWindowType_teacherVideo
        && self.teacherMediaInfoView.superview != self.minorContentView) {
        [self.teacherMediaInfoView removeFromSuperview];
        [self.minorContentView addSubview:self.teacherMediaInfoView];
        if (self.teacherVideoPlaceholderView.superview == self.minorContentView) {
            [self.minorContentView bringSubviewToFront:self.teacherVideoPlaceholderView];
        }
        [self.teacherMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.minorContentView);
        }];
    }
    
    if (self.majorWindowType == BJLScWindowType_teacherVideo
        && self.teacherMediaInfoView != self.majorContentView) {
        [self.teacherMediaInfoView removeFromSuperview];
        [self.majorContentView addSubview:self.teacherMediaInfoView];
        if (self.teacherVideoPlaceholderView.superview == self.majorContentView) {
            [self.majorContentView bringSubviewToFront:self.teacherVideoPlaceholderView];
        }
        [self.teacherMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.majorContentView);
        }];
    }
}

- (void)updateTeacherExtraVideoViewWithMediaUser:(nullable BJLMediaUser *)user {
    // 没有改变用户ID的情况不需要处理，其他的变化在 mediaInfoView 内部处理
    if ((!self.teacherExtraMediaInfoView && !user)
        || (self.teacherExtraMediaInfoView && [self.teacherExtraMediaInfoView.user.ID isEqualToString:user.ID])) {
        return;
    }
    
    // 辅助摄像头关闭，清理视图
    if (self.teacherExtraMediaInfoView && !user) {
        [self.teacherExtraMediaInfoView removeFromSuperview];
        [self.teacherExtraMediaInfoView destroy];
        self.teacherExtraMediaInfoView = nil;
        return;
    }
    
    if (self.teacherExtraMediaInfoView) {
        [self.teacherExtraMediaInfoView removeFromSuperview];
        [self.teacherMediaInfoView destroy];
        self.teacherMediaInfoView = nil;
    }
    self.teacherExtraMediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:user];
    self.teacherExtraMediaInfoView.accessibilityLabel = BJLKeypath(self, teacherExtraMediaInfoView);
    // 触发覆盖白板逻辑
    if (self.minorWindowType == BJLScWindowType_ppt) {
        [self replaceMinorContentViewWithPPTView];
    }
    else if (self.majorWindowType == BJLScWindowType_ppt) {
        [self replaceMajorContentViewWithPPTView];
    }
    else {
        // unsupported
    }
}

- (void)updateMinorViewRatio:(CGFloat)ratio {
    if (ratio <= 0 || !self.room.onlineUsersVM.onlineTeacher || self.minorWindowType != BJLScWindowType_teacherVideo) {
        return;
    }
    
    [self.minorContentView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.view);
        make.top.equalTo(self.topBarView.bjl_bottom);
        make.width.equalTo(@(BJLScSegmentWidth));
        make.height.equalTo(self.minorContentView.bjl_width).multipliedBy(1.0/ratio);
    }];
}

- (void)updateOverlayImageContainerView {
    self.teacherMediaInfoView.isFullScreen = (self.minorWindowType != BJLScWindowType_teacherVideo);
    
    BOOL largeSize = self.majorWindowType == BJLScWindowType_teacherVideo;
    UIView *targetView = largeSize ? self.majorContentView : self.minorContentView;
    [self.teacherVideoPlaceholderView updateTip:nil font:[UIFont systemFontOfSize:largeSize ? 24 : 12]];
    [self.teacherVideoPlaceholderView removeFromSuperview];
    [self.teacherVideoPlaceholderView updateImage:largeSize ? [UIImage bjlsc_imageNamed:@"bjl_sc_leaveClass_large"] : [UIImage bjlsc_imageNamed:@"bjl_sc_leaveClass"] size:largeSize ? BJLScLargeOverlayImageSize : BJLScSmallOverlayImageSizeIPad];
    [targetView addSubview:self.teacherVideoPlaceholderView];
    [self.teacherVideoPlaceholderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(targetView);
    }];
    self.teacherVideoPlaceholderView.hidden = !!self.room.onlineUsersVM.onlineTeacher;
}

- (void)updateSecondMinorContentViewWithUser:(nullable BJLMediaUser *)user recording:(BOOL)recording {
    self.secondMinorVideoPlaceholderView.hidden = user || recording;
    if (self.secondMinorMediaInfoView) {
        [self.secondMinorMediaInfoView removeFromSuperview];
        [self.secondMinorMediaInfoView destroy];
        self.secondMinorMediaInfoView = nil;
    }
    if (recording) {
        // 添加媒体信息视图
        self.secondMinorMediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:self.room.loginUser];
        [self.secondMinorContentView addSubview:self.secondMinorMediaInfoView];
        [self.secondMinorMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.secondMinorContentView);
        }];
    }
    else {
        if (!user) {
            // 添加占位图
            if (self.secondMinorVideoPlaceholderView.superview != self.secondMinorContentView) {
                [self.secondMinorVideoPlaceholderView removeFromSuperview];
                [self.secondMinorContentView addSubview:self.secondMinorVideoPlaceholderView];
                [self.secondMinorVideoPlaceholderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                    make.edges.equalTo(self.secondMinorContentView);
                }];
            }
        }
        else {
            // 添加媒体信息视图
            [self.secondMinorVideoPlaceholderView removeFromSuperview];
            self.secondMinorMediaInfoView = [[BJLScMediaInfoView alloc] initWithRoom:self.room user:user];
            [self.secondMinorContentView addSubview:self.secondMinorMediaInfoView];
            [self.secondMinorMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.secondMinorContentView);
            }];
        }
    }
}

// 错误页UI
- (void)makeErrorView{
    // top bar
    if ([[self.loadingViewController.view subviews] containsObject:self.topBarViewController.view]) {
        return;
    }
    self.topBarViewController = [[BJLScTopBarViewController alloc] initWithRoom:self.room];
    [self.loadingViewController addChildViewController:self.topBarViewController];
    [self.loadingViewController.view addSubview:self.topBarViewController.view];
    [self.topBarViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.loadingViewController.view.bjl_safeAreaLayoutGuide ?: self.loadingViewController.bjl_topLayoutGuide);
         make.left.right.equalTo(self.loadingViewController.view);
         make.height.equalTo(@(BJLScTopBarHeight));
    }];
    bjl_weakify(self);
    [self.topBarViewController setExitCallback:^{
         bjl_strongify(self);
         [self exit];
     }];
}
@end
