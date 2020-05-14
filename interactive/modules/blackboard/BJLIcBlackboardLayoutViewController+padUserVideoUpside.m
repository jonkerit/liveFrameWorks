//
//  BJLIcBlackboardLayoutViewController+padUserVideoUpside.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+padUserVideoUpside.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"
#import "BJLIcBlackboardLayoutViewController+document.h"

@implementation BJLIcBlackboardLayoutViewController (padUserVideoUpside)

//第一套模板 ：大黑板<ppt<网页<小黑板<视频<抢答器、计时器、答题器<屏幕共享
- (void)makePadUserVideoUpsideSubviews {
    self.blackboardView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, blackboardView);
        view.clipsToBounds = NO;
        [self.view addSubview:view];
        bjl_return view;
    });
    
    self.videoListViewController = ({
        BJLIcUserVideoListViewController *viewController = [[BJLIcUserVideoListViewController alloc] initWithRoom:self.room];
        viewController.view.accessibilityLabel = BJLKeypath(self, videoListViewController.view);
        [self bjl_addChildViewController:viewController superview:self.view];
        bjl_return viewController;
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

    self.writingBoardWindowsView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, writingBoardWindowsView);
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

    // page number
    self.pageNumberLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.hidden = YES;
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 16.0;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.accessibilityLabel = BJLKeypath(self, pageNumberLabel);
        [self.view addSubview:label];
        bjl_return label;
    });
    
    self.audioFileButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_blackboard_audiofile"]
                forState:UIControlStateNormal];
        button.userInteractionEnabled = NO;
        button.hidden = YES;
        [self.view addSubview:button];
        bjl_return button;
    });
}

- (void)remakePadUserVideoUpsideContainerViewConstraints {
    // 视频窗口, 会随着黑板动态变化
    [self.videoListViewController.view bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.videosLayer);
    }];
    
    // 黑板固定 2:1
    [self.blackboardView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardLayer);
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

    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    // 小黑板窗口
    [self.writingBoardWindowsView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.blackboardView);
        make.right.equalTo(self.blackboardView).offset(iPhone ? -[BJLIcAppearance sharedAppearance].toolboxWidth : 0);
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

    // 页码
    [self.pageNumberLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.blackboardView).offset(0.0);
        make.top.equalTo(self.blackboardView.bjl_top).offset(24.0);
        make.height.equalTo(@32.0);
        make.width.equalTo(@120.0);
    }];
    
    // 音频文件图标
    [self.audioFileButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.videoListViewController.view.bjl_bottom).offset(10.0);
        make.right.equalTo(self.view).offset(-10.0);
        make.size.equal.sizeOffset(CGSizeMake(40.0, 40.0));
    }];
}

- (void)setupPadUserVideoUpsideBlackboardView {
    UIViewController *blackboardViewController = self.room.documentVM.blackboardViewController;
    [self bjl_addChildViewController:blackboardViewController superview:self.blackboardView];
    [blackboardViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.blackboardView);
    }];
    self.room.documentVM.blackboardImage = [[UIImage bjlic_imageNamed:@"bjl_blackboard_bg"]
                                            resizableImageWithCapInsets:UIEdgeInsetsZero
                                            resizingMode:UIImageResizingModeTile];
    //小黑板
    self.room.documentVM.writingBoardImage = [UIImage bjlic_imageNamed:@"bjl_ic_writingborad"];
}

- (void)makePadUserVideoUpsideObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self, documentWindowDisplayInfos)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BJLIcDocumentWindowViewController *topDocumentViewController;
             BOOL hasFullScreenWindow = NO;
             for (BJLWindowDisplayInfo *displayInfo in [self.documentWindowDisplayInfos copy]) {
                 if (displayInfo.isFullScreen
                     || (!hasFullScreenWindow && displayInfo.isMaximized)) {
                     BJLIcDocumentWindowViewController *tempWindow = [self.displayingDocumentWindows bjl_objectForKey:displayInfo.ID
                                                                                                                class:[BJLIcDocumentWindowViewController class]];
                     if (!tempWindow) {
                         tempWindow = [self displayDocumentWindowWithID:displayInfo.ID requestUpdate:NO];
                     }
                     topDocumentViewController = tempWindow;
                     hasFullScreenWindow = displayInfo.isFullScreen;
                     // !!! no break
                 }
             }
             self.topDocumentWindowController = topDocumentViewController;
             
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, topDocumentWindowController)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (old
                 && [old respondsToSelector:@selector(stopObserverForLaserPointView)]) {
                 // 停止上次监听
                 [old stopObserverForLaserPointView];
             }
             
             // 激光笔视图布局
             UIView *superView = now? self.topDocumentWindowController.view : self.view;
             UIView *constrantView = now? self.topDocumentWindowController.view : self.documentWindowsView;
             if (self.laserPointView.superview != superView) {
                 [self.laserPointView removeFromSuperview];
                 [superView addSubview:self.laserPointView];
             }
             
             if (now) {
                 // !!!: 前端需要 documentID 和 pageIndex
                 self.laserPointView.documentID = self.topDocumentWindowController.documentID;
                 [self bjl_kvo:BJLMakeProperty(self.topDocumentWindowController, pageIndex)
                        filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                            return now.integerValue != old.integerValue;
                        }
                      observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                          bjl_strongify(self);
                          self.laserPointView.pageIndex = now.integerValue;
                          return YES;
                      }];
                 
                 // 添加监听
                 [self.topDocumentWindowController startObserverForLaserPointView:self.laserPointView];
             }
             else {
                 self.laserPointView.documentID = BJLBlackboardID;
                 self.laserPointView.pageIndex = 0;
                 [self.laserPointView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                     make.edges.equalTo(constrantView);
                 }];
                 [self.laserPointView updateShapeShowSize:CGSizeZero];
             }
             
             return YES;
         }];
    
    // 黑板页码
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM.blackboardViewController, localPageIndex)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateBlackboardPageNumber:now.bjl_floatValue + 1];
             return YES;
         }];
    
    // 文档窗口位置更新
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didUpdateDocumentWindowWithModel:shouldReset:)
             observer:(BJLMethodObserver)^BOOL(BJLWindowUpdateModel *updateModel, BOOL shouldReset) {
                 bjl_strongify(self);
                 if (shouldReset) {
                     [self resetDocumentWindowsWithModel:updateModel];
                 }
                 else {
                     [self updateDocumentWindowWithModel:updateModel];
                 }
                 return YES;
             }];
}

@end
