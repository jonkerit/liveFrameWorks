//
//  BJLIcToolbarViewController+padUserVideoDownside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController+padUserVideoDownside.h"
#import "BJLIcToolbarViewController+private.h"

@implementation BJLIcToolbarViewController (padUserVideoDownside)

- (void)makePadUserVideoDownsideSubviews {
    // 第二套模板的背景视图不包括 statusbar 区域，可以用于布局确定位置
    self.backgroundView = ({
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.userInteractionEnabled = NO;
        effectView.accessibilityLabel = @"effectView";
        effectView;
    });
    // 设置媒体控制背景和一般操作按钮背景
    self.mediaBackgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        view.accessibilityLabel = BJLKeypath(self, mediaBackgroundView);
        view.layer.cornerRadius = 5.0;
        view.layer.masksToBounds = YES;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        view.layer.borderWidth = 1.0;
        view.userInteractionEnabled = NO;
        view;
    });
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    self.teacherMediaInfoContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, teacherMediaInfoContainerView);
        view;
    });
    UIView *teacherEffectView = ({
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.userInteractionEnabled = NO;
        effectView.accessibilityLabel = @"teacherEffectView";
        effectView;
    });
    [self.teacherMediaInfoContainerView addSubview:teacherEffectView];
    [teacherEffectView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.teacherMediaInfoContainerView);
    }];
    self.teacherPlaceholderImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.image = [UIImage bjlic_imageNamed:@"bjl_ic_user_placeholder"];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.accessibilityLabel = BJLKeypath(self, teacherPlaceholderImageView);
        imageView;
    });
    [self.teacherMediaInfoContainerView addSubview:self.teacherPlaceholderImageView];
    [self.teacherPlaceholderImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.teacherMediaInfoContainerView);
    }];
    self.teacherNamelabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.accessibilityLabel = BJLKeypath(self, teacherNamelabel);
        label;
    });
    [self.teacherMediaInfoContainerView addSubview:self.teacherNamelabel];
    [self.teacherNamelabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.teacherMediaInfoContainerView);
        make.height.equalTo(@20.0);
    }];
}

- (void)makePadUserVideoDownsideObserving {
    bjl_weakify(self);
    self.teacherLeaveSeat = NO;
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.onlineUsersVM, onlineTeacher),
                         BJLMakeProperty(self.room.playingVM, playingUsers)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  BOOL teacher = NO;
                  for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                      if (user.isTeacher
                          && user.mediaSource == BJLMediaSource_mainCamera) {
                          teacher = YES;
                          if (!self.teacherLeaveSeat) {
                              [self sendTeacherMediaInfoViewBackToSeat];
                          }
                          break;
                      }
                  }
                  // 如果音视频用户不存在老师，清空老师视频视图，重置老师的位置
                  if (!teacher) {
                      self.teacherMediaInfoView = nil;
                      [self updatePadUserVideoDownsideTeacherMediaInfoViewLeaveSeat:NO];
                  }
              }];
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidUpdate:old:)
             observer:^BOOL(BJLMediaUser *user, BJLMediaUser *old){
                 bjl_strongify(self);
                 if ([user.ID isEqualToString:self.room.onlineUsersVM.onlineTeacher.ID]
                     && user.mediaSource == BJLCameraType_main
                     && !self.teacherLeaveSeat) {
                     [self.teacherMediaInfoView updateContentWithUser:user combineVideoView:self.teacherLeaveSeat];
                 }
                 return YES;
             }];
}

- (void)makeTouchMoveGesture {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        return;
    }
    bjl_weakify(self);
    // 点击回到座位的手势
    self.tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        BJLUser *teacher = [self.room.playingVM playingUserWithID:self.room.onlineUsersVM.onlineTeacher.ID number:self.room.onlineUsersVM.onlineTeacher.number mediaSource:BJLMediaSource_mainCamera];
        if (self.sendBackVideoViewCallback) {
            self.sendBackVideoViewCallback(teacher);
        }
        [self sendTeacherMediaInfoViewBackToSeat];
    }];

    // 根据老师视频位置在上面还是在下面处理
    BOOL upside = (BJLIcTeacheVideoPosition_upside == self.room.roomInfo.interactiveClassTeacherVideoPosition);
    __block BJLIcUserMediaInfoView *touchMovingVideoView;
    __block CGRect transformOriginFrame = CGRectZero;
    // 拖动老师视频的手势
    self.touchMoveGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        UIView *referenceView;
        if (self.requestReferenceViewCallback) {
            referenceView = self.requestReferenceViewCallback();
        }
        if (!referenceView) {
            return;
        }
        if (self.teacherLeaveSeat) {
            return;
        }
        if (gesture.state == UIGestureRecognizerStateBegan) {
            BJLIcUserMediaInfoView *videoView = self.teacherMediaInfoView;
            if (videoView) {
                [self updatePadUserVideoDownsideTeacherMediaInfoContainerView:YES];
                CGRect originFrame = [self.view convertRect:videoView.frame fromView:videoView.superview];
                [videoView removeFromSuperview];
                
                [referenceView addSubview:videoView];
                // 视图放大为 1.1 倍，同时保持不超出边界
                CGFloat sizeScale = 1.1;
                transformOriginFrame = bjl_set(originFrame, {
                    set.origin.x -= set.size.width * (sizeScale - 1.0) / 2.0;
                    set.origin.y -= set.size.height * (sizeScale - 1.0) / 2.0;
                    set.size.width *= sizeScale;
                    set.size.height *= sizeScale;
                    
                    set.origin.x = MIN(MAX(0.0, set.origin.x), CGRectGetMaxX(self.view.bounds));
                    set.origin.y = MIN(MAX(0.0, set.origin.y), CGRectGetMaxY(self.view.bounds));
                });
                // !!!: 这里设置初始 frame 再添加自动布局，防止 UIGestureRecognizerStateChanged 触发过快（使用 Apple Pencil 点击）时，自动布局没有完成
                videoView.frame = transformOriginFrame;
                
                [videoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                    make.left.equalTo(referenceView).offset(videoView.frame.origin.x).priorityHigh();
                    if (upside) {
                        make.top.equalTo(referenceView).offset(videoView.frame.origin.y).priorityHigh();
                    }
                    else {
                        make.bottom.equalTo(referenceView).offset(videoView.frame.origin.y).priorityHigh();
                    }
                    make.size.equal.sizeOffset(videoView.frame.size);
                    // 边界限制
                    make.top.left.greaterThanOrEqualTo(referenceView);
                    make.bottom.right.lessThanOrEqualTo(referenceView);
                }];
                
                touchMovingVideoView = videoView;
            }
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [gesture translationInView:gesture.view];
            
            // 更新偏移量
            CGFloat offsetX = transformOriginFrame.origin.x  + translation.x;
            CGFloat offsetY = transformOriginFrame.origin.y  + translation.y;
            
            // 修改当前 contentView 的位置
            [touchMovingVideoView bjl_updateConstraints:^(BJLConstraintMaker *make) {
                make.left.equalTo(referenceView).offset(offsetX).priorityHigh();
                if (upside) {
                    make.top.equalTo(referenceView).offset(offsetY).priorityHigh();
                }
                else {
                    make.bottom.equalTo(referenceView).offset(offsetY).priorityHigh();
                }
            }];
        }
        else if (gesture.state == UIGestureRecognizerStateEnded) {
            if (touchMovingVideoView) {
                BOOL inside = NO;
                CGPoint point = [referenceView convertPoint:touchMovingVideoView.center toView:self.view];
                if (upside) {
                    inside = [self.view pointInside:point withEvent:nil];
                }
                else {
                    inside = [self.view pointInside:point withEvent:nil];
                }
                if (inside) {
                    // 拖动后视图中心点仍未超出列表范围，将视图放回原位置
                    [touchMovingVideoView removeFromSuperview];
                    [self sendTeacherMediaInfoViewBackToSeat];
                }
                else {
                    BOOL success = NO;
                    BJLUser *teacher = [self.room.playingVM playingUserWithID:self.room.onlineUsersVM.onlineTeacher.ID number:self.room.onlineUsersVM.onlineTeacher.number mediaSource:BJLMediaSource_mainCamera];
                    if (self.videoWindowDisplayCallback && teacher) {
                        success = self.videoWindowDisplayCallback(teacher, touchMovingVideoView);
                    }
                    if (!success) {
                        [self sendTeacherMediaInfoViewBackToSeat];
                    }
                    else {
                        self.teacherLeaveSeat = YES;
                    }
                }
            }
            touchMovingVideoView = nil;
            transformOriginFrame = CGRectZero;
        }
        else if (gesture.state == UIGestureRecognizerStateCancelled) {
            [touchMovingVideoView removeFromSuperview];
            touchMovingVideoView = nil;
            [self sendTeacherMediaInfoViewBackToSeat];
            transformOriginFrame = CGRectZero;
        }
    }];
    self.touchMoveGesture.cancelsTouchesInView = NO;
    [self.teacherMediaInfoContainerView addGestureRecognizer:self.tapGesture];
    [self.teacherMediaInfoContainerView addGestureRecognizer:self.touchMoveGesture];
}

- (void)sendTeacherMediaInfoViewBackToSeat {
    // 内部调用，容错，根据具体情况更新状态
    BJLMediaUser *teacher = [self.room.playingVM playingUserWithID:self.room.onlineUsersVM.onlineTeacher.ID
                                                            number:self.room.onlineUsersVM.onlineTeacher.number
                                                       mediaSource:BJLMediaSource_mainCamera];
    if (!teacher) {
        return;
    }
    self.teacherLeaveSeat = NO;
    if (!self.teacherMediaInfoView) {
        self.teacherMediaInfoView = [[BJLIcUserMediaInfoView alloc] initWithUser:teacher room:self.room];
    }
    [self.teacherMediaInfoView updateContentWithUser:teacher combineVideoView:YES];
    [self updatePadUserVideoDownsideTeacherMediaInfoContainerView:NO];
    [self.teacherMediaInfoContainerView addSubview:self.teacherMediaInfoView];
    [self.teacherMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.teacherMediaInfoContainerView);
    }];
}

- (nullable BJLIcUserMediaInfoView *)updatePadUserVideoDownsideTeacherMediaInfoViewLeaveSeat:(BOOL)leaveSeat {
    // 外部调用，强制更新状态
    self.teacherLeaveSeat = leaveSeat;
    [self updatePadUserVideoDownsideTeacherMediaInfoContainerView:leaveSeat];
    if (!self.teacherMediaInfoView) {
        return nil;
    }
    if (leaveSeat) {
        [self.teacherMediaInfoView removeFromSuperview];
    }
    else {
        [self sendTeacherMediaInfoViewBackToSeat];
    }
    return self.teacherMediaInfoView;
}

- (void)updatePadUserVideoDownsideTeacherMediaInfoContainerView:(BOOL)leaveSeat {
    self.teacherPlaceholderImageView.hidden = !leaveSeat;
    self.teacherNamelabel.text = self.room.onlineUsersVM.onlineTeacher ? [NSString stringWithFormat:@"%@ 的座位",self.room.onlineUsersVM.onlineTeacher.name] : nil;
}

- (void)remakePadUserVideoDownsideContainerViewForTeacherOrAssistantWithmediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    if (BJLIcTeacheVideoPosition_downside == self.room.roomInfo.interactiveClassTeacherVideoPosition) {
        [self.view addSubview:self.backgroundView];
        [self.backgroundView  bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        // 添加退出按钮
        [self.view addSubview:self.exitButton];
        [self.exitButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.greaterThanOrEqualTo(self.backgroundView);
            make.left.equalTo(self.backgroundView).offset([BJLIcAppearance sharedAppearance].toolbarMediumSpace).priorityHigh();
            make.top.equalTo(self.backgroundView.bjl_centerY).offset(7.0);
            make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
        }];
        // 媒体控制按钮
        [self.view addSubview:self.mediaBackgroundView];
        [self.mediaBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.exitButton);
            make.right.lessThanOrEqualTo(self.backgroundView).multipliedBy(0.15);
            make.top.equalTo(self.backgroundView).offset([BJLIcAppearance sharedAppearance].toolboxButtonSpace);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
            make.width.equalTo(@(([BJLIcAppearance sharedAppearance].toolbarLargeSpace + [BJLIcAppearance sharedAppearance].toolbarSmallSpace) * mediaButtons.count + [BJLIcAppearance sharedAppearance].toolbarSmallSpace));
        }];
        [self remakePadUserVideoDownsideConstraintsWithMediaButtons:mediaButtons];
        // 一般操作按钮
        [self.view addSubview:self.containerView];
        [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.backgroundView);
            make.centerY.equalTo(self.exitButton.bjl_centerY);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
            make.width.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize * optionButtons.count + [BJLIcAppearance sharedAppearance].toolbarMediumSpace * (optionButtons.count - 1)));
        }];
        [self remakePadUserVideoDownsideConstraintsWithOptionButtons:optionButtons];
        // 老师视图
        [self.view addSubview:self.teacherMediaInfoContainerView];
        [self.teacherMediaInfoContainerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.right.equalTo(self.backgroundView);
            make.height.equalTo(self.backgroundView);
            make.width.equalTo(self.teacherMediaInfoContainerView.bjl_height).multipliedBy(4.0/3.0);
        }];
    }
    else {
        [self.view addSubview:self.backgroundView];
        [self.backgroundView  bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].statusBarHeight);
            make.bottom.left.right.equalTo(self.view);
        }];
        // 添加退出按钮
        [self.view addSubview:self.exitButton];
        [self.exitButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.greaterThanOrEqualTo(self.backgroundView);
            make.left.greaterThanOrEqualTo(self.backgroundView);
            make.left.equalTo(self.backgroundView).offset([BJLIcAppearance sharedAppearance].toolbarMediumSpace).priorityHigh();
            make.bottom.equalTo(self.backgroundView.bjl_centerY).offset(-7.0);
            make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
        }];
        // 媒体控制按钮
        [self.view addSubview:self.mediaBackgroundView];
        [self.mediaBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.exitButton);
            make.right.lessThanOrEqualTo(self.backgroundView).multipliedBy(0.15);
            make.top.greaterThanOrEqualTo(self.backgroundView.bjl_centerY);
            make.bottom.lessThanOrEqualTo(self.backgroundView);
            make.centerY.equalTo(self.backgroundView.bjl_bottom).multipliedBy(3.0/4.0);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
            make.width.equalTo(@(([BJLIcAppearance sharedAppearance].toolbarLargeSpace + [BJLIcAppearance sharedAppearance].toolbarSmallSpace) * mediaButtons.count + [BJLIcAppearance sharedAppearance].toolbarSmallSpace));
        }];
        [self remakePadUserVideoDownsideConstraintsWithMediaButtons:mediaButtons];
        // 一般操作按钮
        [self.view addSubview:self.containerView];
        [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.backgroundView);
            make.centerY.equalTo(self.exitButton.bjl_centerY);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
            make.width.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize * optionButtons.count + [BJLIcAppearance sharedAppearance].toolbarMediumSpace * (optionButtons.count - 1)));
        }];
        [self remakePadUserVideoDownsideConstraintsWithOptionButtons:optionButtons];
        // 老师视图
        [self.view addSubview:self.teacherMediaInfoContainerView];
        [self.teacherMediaInfoContainerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.right.equalTo(self.backgroundView);
            make.height.equalTo(self.backgroundView);
            make.width.equalTo(self.teacherMediaInfoContainerView.bjl_height).multipliedBy(4.0/3.0);
        }];
    }
}

- (void)remakePadUserVideoDownsideToolbarConstraintsWithDrawingGranted:(BOOL)drawingGranted mediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    if (BJLIcTeacheVideoPosition_downside == self.room.roomInfo.interactiveClassTeacherVideoPosition) {
        // 授权的学生 toolbar 分成二层，留出下半部分给 toolbox，未授权的学生的 toolbar 只有一层，中心为 1/2
        [self.view addSubview:self.backgroundView];
        [self.backgroundView  bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        // 添加退出按钮
        [self.view addSubview:self.exitButton];
        [self.exitButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            if (drawingGranted) {
                make.top.equalTo(self.backgroundView.bjl_centerY).offset(7.0);
            }
            else {
                make.centerY.equalTo(self.backgroundView.bjl_bottom).multipliedBy(1.0/2.0);
            }
            make.left.greaterThanOrEqualTo(self.backgroundView);
            make.left.equalTo(self.backgroundView).offset([BJLIcAppearance sharedAppearance].toolbarMediumSpace).priorityHigh();
            make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
        }];
        // 媒体控制按钮
        [self.view addSubview:self.mediaBackgroundView];
        [self.mediaBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.exitButton);
            make.left.equalTo(self.exitButton).offset([BJLIcAppearance sharedAppearance].toolbarButtonWidth);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace)).priorityHigh();
            make.width.equalTo(@(([BJLIcAppearance sharedAppearance].toolbarLargeSpace + [BJLIcAppearance sharedAppearance].toolbarSmallSpace) * mediaButtons.count + [BJLIcAppearance sharedAppearance].toolbarSmallSpace));
        }];
        [self remakePadUserVideoDownsideConstraintsWithMediaButtons:mediaButtons];
        // 一般操作按钮 学生增加个举手按钮
        NSMutableArray *mutableOptionButtons = [optionButtons mutableCopy];
        [mutableOptionButtons bjl_addObject:self.speakRequestButton];
        self.speakRequestButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        self.speakRequestButton.layer.cornerRadius = [BJLIcAppearance sharedAppearance].buttonSize / 2;
        self.speakRequestButton.layer.borderWidth = 1.0;
        self.speakRequestButton.layer.borderColor = [UIColor bjl_colorWithHexString:@"#999999" alpha:0.3].CGColor;
        [self.view addSubview:self.containerView];
        [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.backgroundView);
            make.centerY.equalTo(self.exitButton);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize)).priorityHigh();
            make.width.lessThanOrEqualTo(@([BJLIcAppearance sharedAppearance].buttonSize * mutableOptionButtons.count + [BJLIcAppearance sharedAppearance].toolbarMediumSpace * (mutableOptionButtons.count - 1)));
        }];
        [self remakePadUserVideoDownsideConstraintsWithOptionButtons:mutableOptionButtons];
        // 举手时间进度，使用iphone的大小
        self.speakRequestProgressView.size = [BJLIcAppearance sharedAppearance].toolbarLargeSpace;
        [self.speakRequestButton addSubview:self.speakRequestProgressView];
        [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.speakRequestButton);
        }];
        // 老师视图
        [self.view addSubview:self.teacherMediaInfoContainerView];
        [self.teacherMediaInfoContainerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.right.equalTo(self.backgroundView);
            make.height.equalTo(self.backgroundView);
            make.width.equalTo(self.teacherMediaInfoContainerView.bjl_height).multipliedBy(4.0/3.0);
        }];
    }
    else {
        // 授权的学生 toolbar 分成二层，留出下半部分给 toolbox，未授权的学生的 toolbar 只有一层，中心为 1/2
        [self.view addSubview:self.backgroundView];
        [self.backgroundView  bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.top.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].statusBarHeight);
            make.bottom.left.right.equalTo(self.view);
        }];
        // 添加退出按钮
        [self.view addSubview:self.exitButton];
        [self.exitButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.greaterThanOrEqualTo(self.backgroundView);
            if (drawingGranted) {
                make.bottom.equalTo(self.backgroundView.bjl_centerY).offset(-7.0);
            }
            else {
                make.centerY.equalTo(self.backgroundView.bjl_bottom).multipliedBy(1.0/2.0);
            }
            make.left.greaterThanOrEqualTo(self.backgroundView);
            make.left.equalTo(self.backgroundView).offset([BJLIcAppearance sharedAppearance].toolbarMediumSpace).priorityHigh();
            make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace));
        }];
        // 媒体控制按钮
        [self.view addSubview:self.mediaBackgroundView];
        [self.mediaBackgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.exitButton);
            make.left.equalTo(self.exitButton).offset([BJLIcAppearance sharedAppearance].toolbarButtonWidth);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].toolbarLargeSpace)).priorityHigh();
            make.width.equalTo(@(([BJLIcAppearance sharedAppearance].toolbarLargeSpace + [BJLIcAppearance sharedAppearance].toolbarSmallSpace) * mediaButtons.count + [BJLIcAppearance sharedAppearance].toolbarSmallSpace));
        }];
        [self remakePadUserVideoDownsideConstraintsWithMediaButtons:mediaButtons];
        // 一般操作按钮 学生增加个举手按钮
        NSMutableArray *mutableOptionButtons = [optionButtons mutableCopy];
        [mutableOptionButtons bjl_addObject:self.speakRequestButton];
        self.speakRequestButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        self.speakRequestButton.layer.cornerRadius = [BJLIcAppearance sharedAppearance].buttonSize / 2;
        self.speakRequestButton.layer.borderWidth = 1.0;
        self.speakRequestButton.layer.borderColor = [UIColor bjl_colorWithHexString:@"#999999" alpha:0.3].CGColor;
        [self.view addSubview:self.containerView];
        [self.containerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.backgroundView);
            make.centerY.equalTo(self.exitButton);
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize)).priorityHigh();
            make.width.lessThanOrEqualTo(@([BJLIcAppearance sharedAppearance].buttonSize * mutableOptionButtons.count + [BJLIcAppearance sharedAppearance].toolbarMediumSpace * (mutableOptionButtons.count - 1)));
        }];
        [self remakePadUserVideoDownsideConstraintsWithOptionButtons:mutableOptionButtons];
        // 举手时间进度，使用iphone的大小
        self.speakRequestProgressView.size = [BJLIcAppearance sharedAppearance].toolbarLargeSpace;
        [self.speakRequestButton addSubview:self.speakRequestProgressView];
        [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.speakRequestButton);
        }];
        // 老师视图
        [self.view addSubview:self.teacherMediaInfoContainerView];
        [self.teacherMediaInfoContainerView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.right.equalTo(self.backgroundView);
            make.height.equalTo(self.backgroundView);
            make.width.equalTo(self.teacherMediaInfoContainerView.bjl_height).multipliedBy(4.0/3.0);
        }];
    }
}

- (void)remakePadUserVideoDownsideContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons {
    [self remakePadUserVideoDownsideToolbarConstraintsWithDrawingGranted:NO mediaButtons:mediaButtons optionButtons:optionButtons];
}

- (void)remakePadUserVideoDownsideConstraintsWithMediaButtons:(NSArray *)buttons {
    UIButton *lastMediaButton = nil;
    for (UIButton *button in buttons) {
        [self.view addSubview:button];
        // 第二套模板使用不同的背景，基于 mediaBackgroundView
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.equalTo(self.mediaBackgroundView);
            make.width.equalTo(button.bjl_height).priorityHigh();
            make.left.greaterThanOrEqualTo(self.mediaBackgroundView);
            make.left.equalTo(lastMediaButton.bjl_right ?: self.mediaBackgroundView.bjl_left).offset([BJLIcAppearance sharedAppearance].toolbarSmallSpace).priorityHigh();
            make.right.lessThanOrEqualTo(self.mediaBackgroundView);
        }];
        lastMediaButton = button;
    }
}

- (void)remakePadUserVideoDownsideConstraintsWithOptionButtons:(NSArray *)buttons {
    UIButton *lastButton = nil;
    for (UIButton *button in buttons) {
        [self.containerView addSubview:button];
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.equalTo(self.containerView);
            if (lastButton) {
                make.left.equalTo(lastButton.bjl_right).offset([BJLIcAppearance sharedAppearance].toolbarMediumSpace);
            }
            else {
                make.left.equalTo(self.containerView);
            }
            make.width.equalTo(button.bjl_height);
            if (button == buttons.lastObject) {
                make.right.equalTo(self.containerView);
            }
        }];
        lastButton = button;
    }
}

@end
