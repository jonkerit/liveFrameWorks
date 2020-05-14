//
//  BJLIcBlackboardLayoutViewController+padUserVideoDownside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+padUserVideoDownside.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"

@implementation BJLIcBlackboardLayoutViewController (padUserVideoDownside)

//第二套模板 ：ppt=大黑板=辅助摄像头<小黑板<网页<视频<计时器，答题器，抢答题<屏幕共享
- (void)makePadUserVideoDownsideSubviews {
    self.blackboardView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, blackboardView);
        view.clipsToBounds = YES;
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self.prevStepButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, prevStepButton);
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_blackboard_prevstep_enabled"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_blackboard_prevstep_disabled"] forState:UIControlStateDisabled];
        [button addTarget:self action:@selector(pageStepBackward) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        bjl_return button;
    });
    
    self.nextStepButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, nextStepButton);
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_blackboard_nextstep_enabled"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_blackboard_nextstep_disabled"] forState:UIControlStateDisabled];
        [button addTarget:self action:@selector(pageStepForward) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        bjl_return button;
    });
    
    self.videoListViewController = ({
        BJLIcUserVideoListViewController *viewController = [[BJLIcUserVideoListViewController alloc] initWithRoom:self.room];
        viewController.view.accessibilityLabel = BJLKeypath(self, videoListViewController.view);
        [self bjl_addChildViewController:viewController superview:self.view];
        bjl_return viewController;
    });
    
    self.writingBoardWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, writingBoardWindowsView);
        [self.view addSubview:view];
        bjl_return view;
    });

    self.documentWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, documentWindowsView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self.webDocumentWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, webDocumentWindowsView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self.webviewWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, webviewWindowsView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self.alwaysMaximizeVideoWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, alwaysMaximizeVideoWindowsView);
        [self.view addSubview:view];
        bjl_return view;
    });

    self.laserPointView = ({
        BJLIcLaserPointView *view = [[BJLIcLaserPointView alloc] initWithRoom:self.room];
        view.accessibilityLabel = BJLKeypath(self, laserPointView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self.videoWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, videoWindowsView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self.responderWindowView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, responderWindowView);
        [self.view addSubview:view];
        bjl_return view;
    });
}

- (void)remakePadUserVideoDownsideContainerViewConstraints {
    [self.blackboardView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardLayer);
    }];
    
    [self.videoListViewController.view bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.videosLayer);
    }];
    
    [self.nextStepButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.bottom.equalTo(self.blackboardView).offset(-30.0);
        make.width.height.equalTo(@42.0);
    }];
    
    [self.prevStepButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.nextStepButton.bjl_left).offset(-30.0);
        make.height.width.equalTo(self.nextStepButton);
        make.centerY.equalTo(self.nextStepButton);
    }];
    
    // 小黑板窗口
    [self.writingBoardWindowsView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];

    // 文档窗口
    [self.documentWindowsView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    // web 文档窗口
    [self.webDocumentWindowsView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardView);
    }];

    // 网页窗口
    [self.webviewWindowsView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];

    // 一直保持最大化的视频窗口，第一套模板存在自动最大化的视频窗口时不能使用黑板，目前不用处理
    [self.alwaysMaximizeVideoWindowsView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    // 激光笔视图
    [self.laserPointView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.documentWindowsView);
    }];
    
    // 视频窗口
    [self.videoWindowsView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    
    // 答题器抢答器计时器等窗口
    [self.responderWindowView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
}

- (void)setupPadUserVideoDownsideBlackboardView {
    // 课件
    self.room.slideshowViewController.shouldSwitchNativePPTBlock = ^(NSString * _Nullable documentID, void (^ _Nonnull callback)(BOOL)) {
        callback(YES);
    };
    self.room.slideshowViewController.imageSize = 1080;
    self.room.slideshowViewController.view.backgroundColor = [UIColor blackColor];
    self.room.slideshowViewController.view.accessibilityLabel = @"slideshowViewControllerView";
    self.room.slideshowViewController.prevPageIndicatorImage = [UIImage bjl_imageNamed:@"bjl_ic_ppt_prev"];
    self.room.slideshowViewController.nextPageIndicatorImage = [UIImage bjl_imageNamed:@"bjl_ic_ppt_next"];
    self.room.slideshowViewController.disableCrossDoc = YES;
    [self.room.slideshowViewController updateScaleEnabled:YES];
    BOOL enabled = (self.room.loginUser.isTeacherOrAssistant
                    || self.room.documentVM.authorizedPPT);
    [self.room.slideshowViewController updateScrollEnabled:enabled];
    [self bjl_addChildViewController:self.room.slideshowViewController superview:self.blackboardView];
    [self.room.slideshowViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    BJLWindowDisplayInfo *newDisplayInfo = ({
        BJLWindowDisplayInfo *info = [BJLWindowDisplayInfo new];
        info.ID = @"0";
        info.x = CGRectGetMinX(self.blackboardView.frame);
        info.y = CGRectGetMinY(self.blackboardView.frame);
        info.width = CGRectGetWidth(self.blackboardView.frame);
        info.height = CGRectGetHeight(self.blackboardView.frame);
        info.isFullScreen = NO;
        info.isMaximized = YES;
        info;
    });
    [self.mutableDocumentWindowDisplayInfos bjl_addObject:newDisplayInfo];
    self.documentWindowDisplayInfos = [self.mutableDocumentWindowDisplayInfos copy];
    
    //小黑板
    self.room.documentVM.writingBoardImage = [UIImage bjlic_imageNamed:@"bjl_ic_writingborad"];
    
    if (self.room.loginUser.isTeacherOrAssistant) {
        // 备注
        self.pptRemarkInfoButton = ({
            UIButton *button = [UIButton new];
            button.backgroundColor = [UIColor clearColor];
            [button setImage:[UIImage bjlic_imageNamed:@"window_pptremark_off"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"window_pptremark_on"] forState:UIControlStateSelected];
            [button addTarget:self action:@selector(switchShowPPTRemarkInfo) forControlEvents:UIControlEventTouchUpInside];
            button.clipsToBounds = YES;
            button;
        });
        [self.blackboardView addSubview:self.pptRemarkInfoButton];
        [self.pptRemarkInfoButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.bottom.equalTo(self.blackboardView);
            make.left.equalTo(self.blackboardView).offset(12.0);
        }];
    }
}

- (void)pageStepForward {
    if (self.room.slideshowViewController.canStepForward) {
        [self.room.slideshowViewController pageStepForward];
    }
}

- (void)pageStepBackward {
    if (self.room.slideshowViewController.canStepBackward) {
        [self.room.slideshowViewController pageStepBackward];
    }
}

- (void)makePadUserVideoDownsideObserving {
    bjl_weakify(self);
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.slideshowViewController, viewType),
                         BJLMakeProperty(self.room.documentVM, authorizedPPT),
                         BJLMakeProperty(self.room.documentVM, currentSlidePage)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  BJLSlidePage *currentSlidePage = self.room.documentVM.currentSlidePage;
                  BJLDocument *document = [self.room.documentVM documentWithID:currentSlidePage.documentID];
                  if (!document) {
                      return;
                  }
                  BOOL enabledPPT = self.room.loginUser.isTeacher
                                    || (self.room.loginUser.isStudent && self.room.documentVM.authorizedPPT)
                                    || (self.room.loginUser.isAssistant && [self.room.roomVM getAssistantaAuthorityWithDocumentControl]);
                  [self.room.slideshowViewController updateScrollEnabled:enabledPPT];
                  [self.room.slideshowViewController updateWebPPTInteractable:enabledPPT];
                  // 翻页按钮在单页文档，静态文档，未知页码的 h5 课件，未授权时隐藏
                  if (BJLPPTViewType_Native == self.room.slideshowViewController.viewType
                      || (document.pageInfo.pageCount <= 1 && document.pageInfo.isWebDoc)
                      || !enabledPPT) {
                      self.nextStepButton.hidden = YES;
                      self.prevStepButton.hidden = YES;
                  }
                  else {
                      self.nextStepButton.hidden = NO;
                      self.prevStepButton.hidden = NO;
                  }
              }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.slideshowViewController, canStepForward),
                         BJLMakeProperty(self.room.slideshowViewController, canStepBackward)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.room.slideshowViewController.pageGestureCanStepForward = self.room.slideshowViewController.canStepForward;
        self.nextStepButton.enabled = self.room.slideshowViewController.canStepForward;
        self.room.slideshowViewController.pageGestureCanStepBackward = self.room.slideshowViewController.canStepBackward;
        self.prevStepButton.enabled = self.room.slideshowViewController.canStepBackward;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, showPPTRemarkInfo)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.pptRemarkInfoButton.selected = now.boolValue;
             return YES;
         }];
}

- (void)switchShowPPTRemarkInfo {
    [self.room.slideshowViewController updateShowPPTRemarkInfo:!self.room.slideshowViewController.showPPTRemarkInfo];
}

@end
