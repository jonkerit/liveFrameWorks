//
//  BJLIcRoomViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-07.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import "BJLIcRoomViewController.h"
#import "BJLIcRoomViewController+private.h"
#import "BJLIcRoomViewController+actions.h"
#import "BJLIcRoomViewController+layer.h"
#import "BJLIcRoomViewController+room.h"

#import "BJLIcAppearance.h"
#import "BJLIcPopoverViewController.h"
#import "BJLIcChatInputViewController.h"

#if DEBUG && __has_include(<BJLiveBase/BJLYYFPSLabel.h>)
#import <BJLiveBase/BJLYYFPSLabel.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcRoomViewController ()

@property (nonatomic, readwrite, nullable) BJLRoom *room;
@property (nonatomic, nullable) BJLProgressHUD *prevHUD;
@property (nonatomic) CGRect keyboardFrame;

@end

@implementation BJLIcRoomViewController {
    BOOL _entered;
}

#pragma mark - initialize

+ (__kindof instancetype)instanceWithSecret:(NSString *)roomSecret
                                   userName:(NSString *)userName
                                 userAvatar:(nullable NSString *)userAvatar {
    BJLRoom *room = [BJLRoom roomWithSecret:roomSecret userName:userName userAvatar:userAvatar];
    return [[self alloc] initWithRoom:room];
}


+ (__kindof instancetype)instanceWithID:(NSString *)roomID
                                apiSign:(NSString *)apiSign
                                   user:(BJLUser *)user {
    BJLRoom *room = [BJLRoom roomWithID:roomID apiSign:apiSign user:user];
    return [[self alloc] initWithRoom:room];
}


- (instancetype)initWithRoom:(BJLRoom *)room {
    NSParameterAssert(room);
    self = [super init];
    if (self) {
        self.room = room;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self->_autoPlayVideoBlacklist = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    [self.reachabilityManager stopMonitoring];
    self.reachabilityManager = nil;
    
    [self clean];
    [self bjl_stopAllMethodParametersObserving];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    self.view.backgroundColor = [UIColor blackColor];
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif
    
    [self makeLoadingController];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationLandscapeLeft
        && [UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationLandscapeRight) {
        [[UIDevice currentDevice] setValue:@(UIDeviceOrientationLandscapeLeft) forKey:@"orientation"];
    }
    if (!_entered) {
        _entered = YES;
        [self.room enterByValidatingConflict:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHideWithNotification:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrameWithNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

#pragma mark - UIViewControllerRotation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark -

- (void)makeLoadingController {
    [self makeRoomObservingBeforeEnterRoom];
    bjl_weakify(self);
    // 首先添加loading视图，loading界面无视设备情况，全屏显示
    [self.view addSubview:self.loadingLayer];
    [self.loadingLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    self->_loadingViewController = [[BJLIcLoadingViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.loadingViewController superview:self.loadingLayer];
    [self.loadingViewController setExitCallback:^{
        bjl_strongify(self);
        [self exit];
    }];
    [self.loadingViewController setLoadRoomInfoSucessCallback:^{
        bjl_strongify(self);
        [BJLIcAppearance sharedAppearanceWithTemplateType:self.room.roomInfo.interactiveClassTemplateType
                                          videoDefinition:self.room.featureConfig.maxVideoDefinition];
        [self makeLayoutLayer];
        [self makeWidgetLayer];
        [self makeOtherLayers];
        
        [self makeViewControllers];
        
        [self makeActions];
#if DEBUG
        [self makeDebugActions];
#endif
        [self makeRoomObserving];
    }];
    [self.loadingViewController setHideCallback:^{
        bjl_strongify(self);
        [self.loadingLayer removeFromSuperview];
        [self.toolbarViewController tryToShowCloudRecordingTipView];
    }];
    [self.loadingViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.loadingLayer);
    }];
}

- (void)makeViewControllers {
    bjl_weakify(self);
    
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    /* stausbar */
    self->_statusBarViewController = [[BJLIcStatusBarViewController alloc] initWithRoom:self.room];
    [self.statusBarViewController setShowWeakNetworkTipCallback:^(NSInteger duration) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithSpecialPrompt:@"当前网络状况差" duration:duration important:NO];
    }];
    [self bjl_addChildViewController:self.statusBarViewController superview:self.statusBar];
    [self.statusBarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.statusBar);
    }];
    
    /* blackboard */
    
    self->_blackboardLayoutViewController = [[BJLIcBlackboardLayoutViewController alloc] initWithRoom:self.room];
    [self.blackboardLayoutViewController setFullscreenParentViewController:self superview:self.fullscreenLayer];
    if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self.blackboardLayoutViewController setUpdateTeacherMediaInfoViewCallback:^BJLIcUserMediaInfoView * _Nonnull(BOOL leaveSeat, NSString *mediaID) {
            bjl_strongify(self);
            if ([self.toolbarViewController.teacherMediaInfoView.mediaID isEqualToString:mediaID]) {
                return [self.toolbarViewController updateTeacherMediaInfoViewLeaveSeat:leaveSeat];
            }
            return nil;
        }];
    }
    [self.blackboardLayoutViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:message];
    }];
    [self.blackboardLayoutViewController setShowWritingBoardTimeInputViewControllerCallBack:^{
        bjl_strongify(self);
        BJLIcChatInputViewController *chatInputViewController = [[BJLIcChatInputViewController alloc] initWithText:@""];
        [self bjl_addChildViewController:chatInputViewController superview:self.popoversLayer];
        [chatInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.popoversLayer);
        }];
        [chatInputViewController setEditCallback:^(NSString * _Nonnull text) {
            bjl_strongify(self);
            [self.blackboardLayoutViewController setWritingBoardTime:text];
        }];
    }];
    [self.blackboardLayoutViewController setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
        bjl_strongify(self);
        [self updateAutoPlayVideoBlacklist:user add:!on];
    }];
    [self.blackboardLayoutViewController setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        return [self tryToBlockUser:user];
    }];
    [self.blackboardLayoutViewController setReceiveLikeCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showLikeEffectViewController:BJLRoomLayout_blackboard user:user likeButton:button];
    }];
    [self.blackboardLayoutViewController setWebviewControllerKeyboardFrameChangeCallback:^(CGRect keyboardFrame, UIView * _Nonnull overlayView) {
        bjl_strongify(self);
        [self updateOverlayViewWithKeyboardFrame:keyboardFrame overlayView:overlayView];
    }];
    [self.blackboardLayoutViewController setCloseWebviewControllerCallback:^{
        bjl_strongify(self);
        [self askToCloseWebViewController];
    }];
    [self.blackboardLayoutViewController setCloseQuestionAnswerControllerCallback:^{
        bjl_strongify(self);
        [self askToCloseQuestionAnswerController];
    }];
    [self.blackboardLayoutViewController setCloseQuizControllerCallback:^{
        bjl_strongify(self);
        [self askToCloseQuizController];
    }];
    [self.blackboardLayoutViewController setCancelQuizControllerCallback:^{
        bjl_strongify(self);
        [self cancelPopoverWithType:BJLIcCloseQuiz];
    }];

    /* videogrid */
    
    self->_videosGridLayoutViewController = [[BJLIcVideosGridLayoutViewController alloc] initWithRoom:self.room];
    [self.videosGridLayoutViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:message];
    }];
    [self.videosGridLayoutViewController setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
        bjl_strongify(self);
        [self updateAutoPlayVideoBlacklist:user add:!on];
    }];
    [self.videosGridLayoutViewController setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        return [self tryToBlockUser:user];
    }];
    [self.videosGridLayoutViewController setReceiveLikeCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showLikeEffectViewController:BJLRoomLayout_gallary user:user likeButton:button];
    }];

    /* tools */
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        if (iPhone) {
            [self makePhone1to1ToolsViewController];
        }
        else {
            [self makePad1to1ToolsViewController];
        }
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self makePadUserVideoDownsideToolsViewController];
    }
    else {
        if (iPhone) {
            [self makePhoneUserVideoUpsideToolsViewController];
        }
        else {
            [self makePadUserVideoUpsideToolsViewController];
        }
    }
    
    /* chat */
    
    self->_chatViewController = [[BJLIcChatViewController alloc] initWithRoom:self.room];
    [self.chatViewController setForbidChatCallback:^BOOL(BOOL forbid) {
        bjl_strongify(self);
        NSError *error = [self.room.chatVM sendForbidAll:forbid];
        if (error) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
        }
        return !error;
    }];
    [self.chatViewController setReceiveUnreadMessageCallback:^(NSArray<BJLMessage *> * _Nonnull unreadMessage) {
        bjl_strongify(self);
        if (!self.toolbarViewController.chatListButton.selected) {
            self.toolbarViewController.chatListRedDot.hidden = NO;
        }
    }];
    [self.chatViewController setCloseCallback:^{
        bjl_strongify(self);
        self.toolbarViewController.chatListButton.selected = NO;
        [self.chatViewController bjl_removeFromParentViewControllerAndSuperiew];
    }];
    
    /* user */
    
    self->_userViewController = [[BJLIcUserViewController alloc] initWithRoom:self.room];
    [self.userViewController setForbidSpeakRequestCallback:^(BOOL forbid) {
        bjl_strongify(self);
        return [self updateForbidSpeakRequest:forbid];
    }];
    [self.userViewController setReceiveSpeakingRequestCallback:^(BJLUser * _Nonnull user, BOOL finish, NSInteger count) {
        bjl_strongify(self);
        if (!self.toolbarViewController.userListButton.selected) {
            self.toolbarViewController.userListRedDot.hidden = !count;
            self.toolbarViewController.userListRedDot.text = count > 99 ? @"99" : [NSString stringWithFormat:@"%td", count];
        }
        if (!self.toolbarViewController.menuButton.isSelected) {
            // 菜单隐藏时，红点显示到菜单上
            self.toolbarViewController.menuRedDot.hidden = !count;
            self.toolbarViewController.menuRedDot.text = count > 99 ? @"99" : [NSString stringWithFormat:@"%td", count];
        }
    }];
    [self.userViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:message];
    }];
    [self.userViewController setBlockUserCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        [self tryToBlockUser:user];
    }];
    [self.userViewController setShowSwitchStageTipViewCallback:^{
        bjl_strongify(self);
        [self showSwitchStageTipView];
    }];
    [self.userViewController setShowFreeAllBlockedUserCallback:^{
        bjl_strongify(self);
        [self showFreeAllBlockedUserView];
    }];
    [self.userViewController setCloseCallback:^{
        bjl_strongify(self);
        self.toolbarViewController.userListButton.selected = NO;
        for (UIViewController *viewController in self.userViewController.childViewControllers) {
            [viewController bjl_removeFromParentViewControllerAndSuperiew];
        }
        [self.userViewController bjl_removeFromParentViewControllerAndSuperiew];
    }];
    
    /* prompt */
    
    self->_promptViewController = [[BJLIcPromptViewController alloc] init];
    [self bjl_addChildViewController:self.promptViewController superview:self.popoversLayer];
    [self.promptViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.widgetLayer);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].promptViewHeight));
    }];
    
    /* document */
    
    self->_documentFileManagerViewController = [[BJLIcDocumentFileManagerViewController alloc] initWithRoom:self.room];
    [self.documentFileManagerViewController setHideCallback:^{
        bjl_strongify(self);
        if (self.toolbarViewController.coursewareButton.isSelected) {
            self.toolbarViewController.coursewareButton.selected = NO;
        }
        if (self.toolboxViewController.coursewareButton.isSelected) {
            [self.toolboxViewController cancelCurrentSelectedButton];
        }
    }];
    [self.documentFileManagerViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:message];
    }];
    [self.documentFileManagerViewController setSelectDocumentFileCallback:^(BJLIcDocumentFile * _Nonnull documentFile, UIImage * _Nullable image) {
        bjl_strongify(self);
        if ([self.childViewControllers containsObject:self.blackboardLayoutViewController]) {
            if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
                [self.blackboardLayoutViewController changeDocumentWithDocumentID:documentFile.remoteDocument.documentID pageIndex:0];
            }
            else {
                if (documentFile.type == BJLIcDocumentFileImage) {
                    if (!image) {
                        return;
                    }
                    // !!!: 图片通过修改图片数据的方式之外改变过方向的情况，需要更新 size 数据
                    BOOL needSwap = (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight || image.imageOrientation == UIImageOrientationLeftMirrored || image.imageOrientation == UIImageOrientationRightMirrored);
                    CGSize imageSize = needSwap ? CGSizeMake(documentFile.remoteDocument.pageInfo.height, documentFile.remoteDocument.pageInfo.width) : CGSizeMake(documentFile.remoteDocument.pageInfo.width, documentFile.remoteDocument.pageInfo.height);
                    [self.blackboardLayoutViewController addImageShapeToBlackboardWithURL:documentFile.remoteDocument.pageInfo.pageURLString imageSize:imageSize];
                }
//                else if (documentFile.type == BJLIcDocumentFileWebPPT) {
//                    [self.blackboardLayoutViewController displayWebDocumentWindowWithID:documentFile.remoteDocument.documentID
//                                                                          requestUpdate:YES];
//                }
                else {
                    [self.blackboardLayoutViewController displayDocumentWindowWithID:documentFile.remoteDocument.documentID requestUpdate:YES];
                }
            }
        }
    }];
    self->_documentFileDisplayListView = [[BJLIcDocumentFileDisplayListView alloc] initWithRoom:self.room
                                                                                  singleDisplay:(BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType)];
    [self.documentFileDisplayListView setSelectDocumentFileCallback:^(BJLIcDocumentFile * _Nonnull documentFile) {
        bjl_strongify(self);
        if (self.room.loginUser.isStudent) {
            return;
        }
        BJLDocument *document = documentFile.remoteDocument;
        if (document.isWebDocument) {
            [self.blackboardLayoutViewController displayWebDocumentWindowWithID:document.documentID requestUpdate:YES];
        }
        else {
            switch (self.documentFileDisplayListView.type) {
                case BJLIcDocumentFileDisplayLayoutTypeLayoutMaximized:
                    [self.blackboardLayoutViewController switchMaximizedDocumentWindowWithID:document.documentID isWebDocument:document.isWebDocument];
                    break;
                
                case BJLIcDocumentFileDisplayLayoutTypeLayoutFullScreen:
                    [self.blackboardLayoutViewController switchFullScreenDocumentWindowWithID:document.documentID isWebDocument:document.isWebDocument];
                    break;
                    
                default:
                    break;
            }
        }
    }];
    [self.documentFileDisplayListView setSelectDocumentCallback:^(BJLDocument * _Nonnull document, NSInteger index) {
        bjl_strongify(self);
        if (document && index >= 0) {
            [self.room.documentVM requestTurnToDocumentID:document.documentID pageIndex:index];
        }
    }];
    [self.documentFileDisplayListView setUploadDocumentCallback:^{
        bjl_strongify(self);
        [self enterCoursewareMode];
    }];
    
    // 举手
    [self.view insertSubview:self.requestSpeakinFullScreenButton aboveSubview:self.fullscreenLayer];
    [self.requestSpeakinFullScreenButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].fullScreenRequestSpeakButtonWidth));
        make.right.equalTo(self.fullscreenLayer).offset(-30);
        make.bottom.equalTo(self.fullscreenLayer).offset(-50);
    }];
    [self.requestSpeakinFullScreenButton addSubview:self.speakRequestProgressView];
    [self.speakRequestProgressView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.requestSpeakinFullScreenButton);
    }];
    
    /* teachingaid */
    
    self->_teachingAidViewController = [[BJLIcTeachingAidViewController alloc] initWithRoom:self.room];
    // 小黑板
    [self.teachingAidViewController setClickWritingBoardCallback:^{
        bjl_strongify(self);
        [self requsetAddWritingBoard];
    }];
    // 打开网页
    [self.teachingAidViewController setOpenWebViewCallback:^{
        bjl_strongify(self);
        [self openWebView];
    }];
    // 计时器
    [self.teachingAidViewController setCountDownCallback:^{
        bjl_strongify(self);
        [self openCountDown];
    }];
    // 抢答器
    [self.teachingAidViewController setQuestionResponderCallback:^{
        bjl_strongify(self);
        [self openQuestionResponder];
    }];
    // 答题器
    [self.teachingAidViewController setQuestionAnswerCallback:^{
        bjl_strongify(self);
        [self openQuestionAnswer];
    }];
    
    [self.teachingAidViewController setHideCallback:^{
        bjl_strongify(self);
        if (self.toolbarViewController.teachingAidButton.isSelected) {
            self.toolbarViewController.teachingAidButton.selected = NO;;
        }
        if (self.toolboxViewController.teachingAidButton.isSelected) {
            [self.toolboxViewController cancelCurrentSelectedButton];
        }
    }];
    
    /* express */
    
    if (self.room.featureConfig.enableExpressExport) {
        self->_expressViewController = [[BJLIcExpressViewController alloc] initWithRoom:self.room];
        [self.expressViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
            bjl_strongify(self);
            [self.promptViewController enqueueWithPrompt:message];
        }];
        [self.expressViewController setShowExpressExportCallback:^{
            bjl_strongify(self);
            if (self.presentedViewController) {
                [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
            }
            [self bjl_presentFullScreenViewController:self.expressViewController animated:YES completion:nil];
        }];
        [self.expressViewController setCloseCallback:^{
            bjl_strongify(self);
            [self.expressViewController bjl_dismissAnimated:YES completion:nil];
        }];
        if (self.shareExpressExportCallback) {
            [self.expressViewController setShareCallback:^(NSString *contentURLString, NSString *firstExpressURLString, NSString *userName) {
                bjl_strongify(self);
                self.shareExpressExportCallback(contentURLString, firstExpressURLString, userName);
            }];
        }
    }
        
#if DEBUG && __has_include(<BJLiveBase/BJLYYFPSLabel.h>)
    BJLYYFPSLabel *fpsLabel = [BJLYYFPSLabel new];
    [self.view addSubview:fpsLabel];
    [fpsLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equal.to(self.view).inset(5.0);
        make.right.equal.to(self.view.bjl_right).inset(60.0);
    }];
#endif
}

- (void)makePadUserVideoUpsideToolsViewController {
    bjl_weakify(self);
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self.toolboxViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (message.length) {
            [self.promptViewController enqueueWithPrompt:message];
        }
    }];
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
    
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbar];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbar);
    }];
}

- (void)makePhoneUserVideoUpsideToolsViewController {
    // 对于 userVideoUpside 的 iphone 布局，toolbar 存在控件（如举手）在 toolbox 上并需要参考 toolbox 布局
    bjl_weakify(self);
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self.toolboxViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (message.length) {
            [self.promptViewController enqueueWithPrompt:message];
        }
    }];
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
    
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self.toolbarViewController setRequestReferenceViewCallback:^UIView * _Nonnull {
        bjl_strongify(self);
        return self.toolbox;
    }];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbox];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.bottom.right.equalTo(self.toolbox);
        make.height.equalTo(self.layoutLayer).multipliedBy([BJLIcAppearance sharedAppearance].toolbarHeightFraction);
    }];
}

- (void)makePadUserVideoDownsideToolsViewController {
    // 对于 userVideoDownside 的布局，toolbox 的控件初始布局时需要参考 toolbar 布局，toolbar 老师视频的移动手势时要用到 toolbox
    bjl_weakify(self);
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self.toolbarViewController setRequestReferenceViewCallback:^UIView * _Nonnull{
        bjl_strongify(self);
        return self.toolbox;
    }];
    [self.toolbarViewController setVideoWindowDisplayCallback:^BOOL(BJLUser *user, BJLIcUserMediaInfoView * _Nullable view) {
        bjl_strongify(self);
        if (BJLRoomLayout_gallary == self.currentRoomLayout) {
            return NO;
        }
        [self.blackboardLayoutViewController displayVideoWindowWithVideoView:view requestUpdate:YES];
        return YES;
    }];
    [self.toolbarViewController setSendBackVideoViewCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeDisplayingVideoWindowsForUser:user requestUpdate:YES];
    }];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbar];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbar);
    }];
    
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self.toolboxViewController setRequestReferenceViewCallback:^UIView * _Nonnull{
        bjl_strongify(self);
        return self.toolbar;
    }];
    [self.toolboxViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (message.length) {
            [self.promptViewController enqueueWithPrompt:message];
        }
    }];
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
}

- (void)makePhone1to1ToolsViewController {
    bjl_weakify(self);
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbar];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbar);
    }];
    
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self.toolboxViewController setRequestReferenceViewCallback:^UIView * _Nonnull{
        bjl_strongify(self);
        return self.toolbar;
    }];
    [self.toolboxViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (message.length) {
            [self.promptViewController enqueueWithPrompt:message];
        }
    }];
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
}

- (void)makePad1to1ToolsViewController {
    bjl_weakify(self);
    UIView *toolboxBackgroundView = [UIView new];
    toolboxBackgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    [self.toolbox addSubview:toolboxBackgroundView];
    [toolboxBackgroundView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.toolbox);
        make.height.equalTo(self.layoutLayer).multipliedBy([BJLIcAppearance sharedAppearance].toolboxHeightFraction);
    }];
    self->_toolboxViewController = [[BJLIcToolboxViewController alloc] initWithRoom:self.room];
    [self.toolboxViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (message.length) {
            [self.promptViewController enqueueWithPrompt:message];
        }
    }];
    [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
    [self.toolboxViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbox);
    }];
    
    self->_toolbarViewController = [[BJLIcToolbarViewController alloc] initWithRoom:self.room];
    [self.toolbarViewController setRequestReferenceViewCallback:^UIView * _Nonnull{
        bjl_strongify(self);
        return self.toolbox;
    }];
    [self bjl_addChildViewController:self.toolbarViewController superview:self.toolbar];
    [self.toolbarViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.toolbar);
    }];
}

#pragma mark - protected

- (void)updateAutoPlayVideoBlacklist:(BJLMediaUser *)user add:(BOOL)add {
    if (add) {
        [self.autoPlayVideoBlacklist addObject:[self videoBlackListRetainKeyForUser:user]];
    }
    else {
        [self.autoPlayVideoBlacklist removeObject:[self videoBlackListRetainKeyForUser:user]];
    }
}

- (NSString *)videoBlackListRetainKeyForUser:(BJLMediaUser *)user {
    return [NSString stringWithFormat:@"%@-%td", user.number, user.mediaSource];
}

- (void)showLikeEffectViewController:(BJLRoomLayout)layout user:(BJLUser *)user likeButton:(UIButton *)button {
    if (self.currentRoomLayout != layout) {
        return;
    }
    CGRect frame = [self.fullscreenLayer convertRect:button.frame fromView:button.superview];
    BJLLikeEffectViewController *likeEffectViewController = [[BJLLikeEffectViewController alloc] initForInteractiveClassWithName:user.displayName endPoint:frame.origin];
    [self bjl_addChildViewController:likeEffectViewController superview:self.fullscreenLayer];
    [likeEffectViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.fullscreenLayer);
    }];
}

- (void)showSwitchStageTipView {
    bjl_weakify(self);
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcSwitchStage];
    BOOL fullScreen = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (fullScreen) {
        [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.popoversLayer);
        }];
    }
    else {
        [self.userViewController bjl_addChildViewController:popoverViewController superview:self.userViewController.view];
        [popoverViewController updateEffectHidden:YES];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.userViewController.view);
        }];
    }
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self.userViewController switchToOnStageListTableView];
    }];
}

- (void)showFreeAllBlockedUserView {
    bjl_weakify(self);
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcFreeBlockedUser];
    BOOL fullScreen = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (fullScreen) {
        [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.popoversLayer);
        }];
    }
    else {
        [self.userViewController bjl_addChildViewController:popoverViewController superview:self.userViewController.view];
        [popoverViewController updateEffectHidden:YES];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.userViewController.view);
        }];
    }
    // 解禁按钮在下面，因此 cancel 是确认
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.room.onlineUsersVM freeAllBlockedUsers];
    }];
}

- (void)askToCloseWebViewController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWebPage];
    [self.blackboardLayoutViewController.webViewWindowViewController bjl_addChildViewController:popoverViewController superview:self.blackboardLayoutViewController.webViewWindowViewController.view];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayoutViewController.webViewWindowViewController.view);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeWebViewController];
    }];
}

- (void)askToCloseQuizController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseQuiz];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeQuizController];
        self.popoverViewController = nil;
    }];
    self.popoverViewController = popoverViewController;
}

- (void)cancelPopoverWithType:(BJLIcPopoverViewType)type {
    if (self.popoverViewController.type == type) {
        [self.popoverViewController bjl_removeFromParentViewControllerAndSuperiew];
    }
}

- (void)askToCloseCountDownController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWebPage];
    [self.blackboardLayoutViewController.countDownViewController bjl_addChildViewController:popoverViewController superview:self.blackboardLayoutViewController.countDownViewController.view];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayoutViewController.countDownViewController.view);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeCountDownController];
    }];
}

- (void)askToCloseQuestionResponderController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWebPage];
    [self.blackboardLayoutViewController.questionResponderViewController bjl_addChildViewController:popoverViewController superview:self.blackboardLayoutViewController.questionResponderViewController.view];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayoutViewController.questionResponderViewController.view);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeQuestionResponderController];
    }];
}

- (void)askToCloseQuestionAnswerController {
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcCloseWebPage];
    [self.blackboardLayoutViewController.questionAnswerWindowViewController bjl_addChildViewController:popoverViewController superview:self.blackboardLayoutViewController.questionAnswerWindowViewController.view];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayoutViewController.questionAnswerWindowViewController.view);
    }];
    bjl_weakify(self);
    [popoverViewController setCancelCallback:^{
        bjl_strongify(self);
        [self.blackboardLayoutViewController closeQuestionAnswerController];
    }];
}

- (BOOL)tryToBlockUser:(BJLUser *)user {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        return NO;
    }
    NSString *message = [NSString stringWithFormat:@"是否将 %@ 移出教室？ \n移出后将无法再次进入教室", user.displayName];
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcKickOutUser message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        BJLError *error = [self.room.onlineUsersVM blockUserWithID:user.ID];
        if (error) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
        }
    }];
    return YES;
}

- (void)updateOverlayViewWithKeyboardFrame:(CGRect)keyboardFrame overlayView:(UIView *)overlayView {
    BOOL showKeyboard = NO;
    if (CGRectGetMinY(keyboardFrame) < CGRectGetHeight([UIScreen mainScreen].bounds)) {
        showKeyboard = YES;
    }
    bjl_weakify(self);
    if (showKeyboard) {
        if (self.overlayView) {
            return;
        }
        self.overlayView = [UIView new];
        [overlayView addSubview:self.overlayView];
        [overlayView sendSubviewToBack:self.overlayView];
        [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(overlayView);
        }];
        UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            [self.blackboardLayoutViewController tryToHideWebViewKeyboardView];
            [self.overlayView removeFromSuperview];
            self.overlayView = nil;
        }];
        [self.overlayView addGestureRecognizer:tapGesture];
    }
    else {
        [self.overlayView removeFromSuperview];
        self.overlayView = nil;
    }
}

- (void)showProgressHUDWithText:(NSString *)text {
    if (!text.length
        || [text isEqualToString:self.prevHUD.detailsLabel.text]) {
        return;
    }
    
    BJLProgressHUD *hud = [BJLProgressHUD bjl_hudForTextWithSuperview:self.view];
    [hud bjl_makeDetailsLabelWithLabelStyle];
    hud.detailsLabel.text = text;
    hud.minShowTime = 0.0; // !!!: MUST be 0.0
    bjl_weakify(self, hud);
    hud.completionBlock = ^{
        bjl_strongify(self, hud);
        if (hud == self.prevHUD) {
            self.prevHUD = nil;
        }
    };
    
    if (self.prevHUD) {
        [self.prevHUD hideAnimated:NO];
    }
    CGFloat minY = CGRectGetMinY(self.keyboardFrame);
    if (minY > CGFLOAT_MIN) {
        hud.offset = CGPointMake(0, - (CGRectGetHeight(self.view.frame) - minY) / 2);
    }
    [hud showAnimated:NO]; // YES?
    [hud hideAnimated:YES afterDelay:BJLProgressHUDTimeInterval];
    self.prevHUD = hud;
}

- (void)exit {
    [BJLIcAppearance destory];
    if (self.room) {
        [self.room exit];
        [self clean];
    }
    else {
        [self dismissWithError:nil];
    }
}

- (void)clean {
    self->_room = nil;
}

- (void)askToExit {
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:@"确定退出教室？"
                                message:nil
                                preferredStyle:UIAlertControllerStyleAlert];
    [alert bjl_addActionWithTitle:@"确定"
                            style:UIAlertActionStyleDestructive
                          handler:^(UIAlertAction * _Nonnull action) {
                              [self exit];
                          }];
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:NO completion:nil];
}

- (void)dismissWithError:(nullable BJLError *)error {
    [self classViewController:self willExitWithError:nil];
    
    void (^completion)(void) = ^{
        [self classViewController:self didExitWithError:error];
    };

    UINavigationController *navigation = [self.parentViewController bjl_as:[UINavigationController class]];
    BOOL isRoot = (navigation
                   && self == navigation.topViewController
                   && self == navigation.bjl_rootViewController);
    UIViewController *outermost = isRoot ? navigation : self;

    // pop
    if (navigation && !isRoot) {
        [navigation bjl_popViewControllerAnimated:YES completion:completion];
    }
    // dismiss
    else if (!outermost.parentViewController && outermost.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:completion];
    }
    // close in `roomViewController:didExitWithError:`
    else {
        completion();
    }
}

#pragma mark - keyboard notification

- (void)keyboardDidHideWithNotification:(NSNotification *)notification {
    self.keyboardFrame = CGRectZero;
}

- (void)keyboardWillChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    self.keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
}

#pragma mark - observable methods

- (BJLObservable)classViewControllerEnterRoomSuccess:(BJLIcRoomViewController *)classViewController {
    BJLMethodNotify((BJLIcRoomViewController *),
                    classViewController);
}

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController
          enterRoomFailureWithError:(BJLError *)error {
    BJLMethodNotify((BJLIcRoomViewController *, BJLError *),
                    classViewController, error);
}

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController
                  willExitWithError:(nullable BJLError *)error {
    BJLMethodNotify((BJLIcRoomViewController *, BJLError *),
                    classViewController, error);
}

- (BJLObservable)classViewController:(BJLIcRoomViewController *)classViewController
                   didExitWithError:(nullable BJLError *)error {
    BJLMethodNotify((BJLIcRoomViewController *, BJLError *),
                    classViewController, error);
}

#pragma mark - getters

@synthesize loadingLayer = _loadingLayer;
- (UIView *)loadingLayer {
    if (!_loadingLayer) {
        _loadingLayer = ({
            UIView *view = [UIView new];
            view.backgroundColor = [UIColor clearColor];
            view.accessibilityLabel = BJLKeypath(self, loadingLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _loadingLayer;
}

@synthesize backgroundImageView = _backgroundImageView;
- (UIImageView *)backgroundImageView {
    if(!_backgroundImageView) {
        _backgroundImageView = ({
            UIImageView *backgroundView = [UIImageView new];
            backgroundView.accessibilityLabel = BJLKeypath(self, backgroundImageView);
            [backgroundView setContentMode:UIViewContentModeScaleAspectFill];
            bjl_return backgroundView;
        });
    }
    return _backgroundImageView;
}

@synthesize layoutLayer = _layoutLayer;
- (UIView *)layoutLayer {
    if (!_layoutLayer) {
        _layoutLayer = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, layoutLayer);
            view.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _layoutLayer;
}

@synthesize statusBar = _statusBar;
- (UIView *)statusBar {
    if (!_statusBar) {
        _statusBar = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, statusBar);
            bjl_return view;
        });
    }
    return _statusBar;
}

@synthesize toolbar = _toolbar;
- (UIView *)toolbar {
    if (!_toolbar) {
        _toolbar = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, toolbar);
            bjl_return view;
        });
    }
    return _toolbar;
}

@synthesize layoutContainer = _layoutContainer;
- (UIView *)layoutContainer {
    if (!_layoutContainer) {
        _layoutContainer = ({
            UIView *view = [UIView new];
            view.accessibilityLabel = BJLKeypath(self, layoutContainer);
            bjl_return view;
        });
    }
    return _layoutContainer;
}

@synthesize blackboardLayer = _blackboardLayer;
- (UIView *)blackboardLayer {
    if (!_blackboardLayer) {
        _blackboardLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, blackboardLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _blackboardLayer;
}

@synthesize videosLayer = _videosLayer;
- (UIView *)videosLayer {
    if (!_videosLayer) {
        _videosLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, videosLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _videosLayer;
}

@synthesize widgetLayer = _widgetLayer;
- (UIView *)widgetLayer {
    if (!_widgetLayer) {
        _widgetLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, widgetLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _widgetLayer;
}

@synthesize widgetContainer = _widgetContainer;
- (UIView *)widgetContainer {
    if (!_widgetContainer) {
        _widgetContainer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, widgetContainer);
            bjl_return view;
        });
    }
    return _widgetContainer;
}

@synthesize toolbox = _toolbox;
- (UIView *)toolbox {
    if (!_toolbox) {
        _toolbox = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, toolbox);
            bjl_return view;
        });
    }
    return _toolbox;
}

@synthesize settingsLayer = _settingsLayer;
- (UIView *)settingsLayer {
    if (!_settingsLayer) {
        _settingsLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, settingsLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _settingsLayer;
}

@synthesize fullscreenToolboxLayer = _fullscreenToolboxLayer;
- (UIView *)fullscreenToolboxLayer {
    if (!_fullscreenToolboxLayer) {
        _fullscreenToolboxLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, fullscreenToolboxLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _fullscreenToolboxLayer;
}

@synthesize fullscreenLayer = _fullscreenLayer;
- (UIView *)fullscreenLayer {
    if (!_fullscreenLayer) {
        _fullscreenLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, fullscreenLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _fullscreenLayer;
}

@synthesize popoversLayer = _popoversLayer;
- (UIView *)popoversLayer {
    if (!_popoversLayer) {
        _popoversLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, popoversLayer);
            view.clipsToBounds = YES;
            bjl_return view;
        });
    }
    return _popoversLayer;
}

@synthesize lampView = _lampView;
- (UIView *)lampView {
    if (!_lampView) {
        _lampView = [BJLHitTestView new];
        _lampView.accessibilityLabel = BJLKeypath(self, lampView);
        _lampView.clipsToBounds = YES;
    }
    return _lampView;
}

@synthesize requestSpeakinFullScreenButton = _requestSpeakinFullScreenButton;
- (UIButton *)requestSpeakinFullScreenButton {
    if (!_requestSpeakinFullScreenButton) {
        _requestSpeakinFullScreenButton = ({
            UIButton *button = [UIButton new];
            button.accessibilityLabel = BJLKeypath(self, requestSpeakinFullScreenButton);
            button.layer.masksToBounds = YES;
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_normal"] forState:UIControlStateNormal];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_selected"] forState:UIControlStateSelected];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_selected"] forState:UIControlStateHighlighted];
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_toolbar_speakrequest_selected"] forState:UIControlStateSelected | UIControlStateHighlighted];
            button.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
            button.layer.cornerRadius = [BJLIcAppearance sharedAppearance].fullScreenRequestSpeakButtonWidth / 2;
            button.layer.borderWidth = 1.0;
            button.layer.borderColor = [UIColor bjl_colorWithHexString:@"#999999" alpha:0.3].CGColor;
            button.hidden = YES;
            bjl_return button;
        });
    }
    return _requestSpeakinFullScreenButton;
}

- (BJLAnnularProgressView *)speakRequestProgressView {
    if (!_speakRequestProgressView) {
        _speakRequestProgressView = ({
            BJLAnnularProgressView *progressView = [BJLAnnularProgressView new];
            progressView.size = [BJLIcAppearance sharedAppearance].fullScreenRequestSpeakButtonWidth - 6.0; // inset = 4, width = 2
            progressView.annularWidth = 2.0;
            progressView.color = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
            progressView.userInteractionEnabled = NO;
            progressView;
        });
    }
    return _speakRequestProgressView;
}

@end

NS_ASSUME_NONNULL_END
