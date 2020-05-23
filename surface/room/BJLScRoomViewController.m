//
//  BJLScRoomViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController.h"
#import "BJLScRoomViewController+private.h"

@implementation BJLScRoomViewController {
    BOOL _entered;
}

#pragma mark - init

+ (__kindof instancetype)instanceWithID:(NSString *)roomID
                                apiSign:(NSString *)apiSign
                                   user:(BJLUser *)user {
    BJLRoom *room = [BJLRoom roomWithID:roomID apiSign:apiSign user:user];
    return [[self alloc] initWithRoom:room];
}

+ (__kindof instancetype)instanceWithSecret:(NSString *)roomSecret
                                   userName:(NSString *)userName
                                 userAvatar:(nullable NSString *)userAvatar {
    BJLRoom *room = [BJLRoom roomWithSecret:roomSecret userName:userName userAvatar:userAvatar];
    return [[self alloc] initWithRoom:room];
}

- (instancetype)initWithRoom:(BJLRoom *)room {
    NSParameterAssert(room);
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self->_room = room;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        [self prepareForEnterRoom];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor bjl_colorWithHex:0X666666];
    
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
#endif
    
    self.loadingLayer = ({
        BJLHitTestView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, loadingLayer);
        bjl_return view;
    });
    [self.view addSubview:self.loadingLayer];
    [self.loadingLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    [self makeObservingBeforeEnterRoom];
    
    bjl_weakify(self);
    self.loadingViewController = [[BJLScLoadingViewController alloc] initWithRoom:self.room];
    [self.loadingViewController setShowCallback:^(BOOL reloading) {
        bjl_strongify(self);
        [self bjl_dismissPresentedViewControllerAnimated:NO completion:nil];
        [self.overlayViewController hide];
        // 发生网络请求错误，返回是一个页面
        BJLError *error = [[BJLError alloc] init];
        [self roomViewController:self enterRoomFailureWithError:error];
    }];
    [self.loadingViewController setHideCallback:^{
        bjl_strongify(self);
        [self.pptManagerViewController startAllUploadingTasks];
    }];
    [self.loadingViewController setExitCallback:^{
        bjl_strongify(self);
        [self askToExit];
    }];
    [self.loadingViewController setExitCallbackWithError:^(BJLError * _Nullable error) {
        bjl_strongify(self);
        [self roomDidExitWithError:error];
    }];
    [self.loadingViewController setLoadRoomInfoSucessCallback:^{
        bjl_strongify(self);
        [self makeConstraints];
        [self makeViewControllers];
        [self makeActionsOnViewDidLoad];
        [self makeObserving];
    }];
    [self bjl_addChildViewController:self.loadingViewController superview:self.loadingLayer];
    [self.loadingViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.loadingLayer);
    }];
}

#pragma mark - enter

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationLandscapeLeft
        && [UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationLandscapeRight) {
        [[UIDevice currentDevice] setValue:@(UIDeviceOrientationLandscapeLeft) forKey:@"orientation"];
    }

    /* 第一次 `viewDidAppear:` 时进入教室、而不是 `viewDidLoad`，因为要避免
     在创建 `BJLRoomViewController` 实例后、如果触发 `viewDidLoad` 但没有立即展示；
     然后 `viewDidLoad` 中调用 `enter`，进教室过程中可能需要弹出提示；
     但在 `viewDidAppear:` 之前弹出的提示无法显示，并在终端打印警告。
     Warning: Attempt to present <UIAlertController> on <BJLScRoomViewController> whose view
     is not in the window hierarchy!
     */
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
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
}

#pragma mark - UIViewControllerRotation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)prefersStatusBarHidden {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    return iPhone;
}

#pragma mark - exit

- (void)roomDidExitWithError:(BJLError *)error {
    // !error: 主动退出
    // BJLErrorCode_exitRoom_disconnected: self.loadingViewController 已处理
    if (!error
        || error.code == BJLErrorCode_exitRoom_disconnected) {
        [self dismissWithError:error];
        return;
    }
    
    if (error.code == BJLErrorCode_enterRoom_auditionTimeout
        || error.code == BJLErrorCode_exitRoom_auditionTimeout) {
        
        SEL setTitle_ = @selector(setTitle:);
        BOOL enableCountdown = [UIAlertAction instancesRespondToSelector:setTitle_];
        NSString * const defaultTitle = @"确定";
        NSString * const format = @" (%td)";
        
        __block UIAlertController *alert = nil;
        __block UIAlertAction *action = nil;
        __block NSInteger countdown = 5;
        
        NSTimer *timer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            countdown--;
            if (enableCountdown) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [action performSelector:setTitle_ withObject:[defaultTitle stringByAppendingFormat:format, countdown]];
#pragma clang diagnostic pop
            }
            if (countdown <= 0) {
                [timer invalidate];
                if (self.presentedViewController == alert) {
                    [alert dismissViewControllerAnimated:NO completion:^{
                        [self dismissWithError:error];
                    }];
                }
            }
        }];
        
        alert = [UIAlertController
                 bjl_lightAlertControllerWithTitle:self.room.featureConfig.auditionEndTip ?: @"哎呀，您的试听时间已到！"
                 message:nil
                 preferredStyle:UIAlertControllerStyleAlert];
        action = [alert bjl_addActionWithTitle:(enableCountdown ? [defaultTitle stringByAppendingFormat:format, countdown] : defaultTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [timer invalidate];
            [self dismissWithError:error];
        }];
        [[UIViewController bjl_topViewController] presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"%@: %@(%td)",
                         error.localizedDescription,
                         error.localizedFailureReason ?: @"",
                         error.code];
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:message
                                message:nil
                                preferredStyle:UIAlertControllerStyleAlert];
    bjl_weakify(self);
    [alert addAction:[UIAlertAction
                      actionWithTitle:@"确定"
                      style:UIAlertActionStyleCancel
                      handler:^(UIAlertAction * _Nonnull action) {
                          bjl_strongify(self);
                          [self dismissWithError:error];
                      }]];
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)exit {
    if (self.room) {
        [self.room exit];
    }
    else {
        [self dismissWithError:nil];
    }
}

- (void)dismissWithError:(nullable BJLError *)error {
    [self roomViewController:self willExitWithError:nil];
    
    bjl_weakify(self);
    void (^completion)(void) = ^{
        bjl_strongify(self);
        [self roomViewController:self didExitWithError:error];
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

- (void)clean {
    self->_room = nil;
}

- (void)askToExit {
    bjl_weakify(self);
    UIAlertController *alertController = [UIAlertController bjl_lightAlertControllerWithTitle:@"退出教室" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController bjl_addActionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
    [alertController bjl_addActionWithTitle:@"退出" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        bjl_strongify(self);
        [self exit];
    }];
    if (self.room.roomVM.liveStarted && self.room.loginUser.isTeacher) {
        [alertController bjl_addActionWithTitle:@"下课并退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            bjl_strongify(self);
            [self.room.roomVM sendLiveStarted:NO];
            [self exit];
        }];
    }
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - NSNotification

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

#pragma mark - hud

- (void)showProgressHUDWithText:(NSString *)text {
    [self showProgressHUDWithText:text superView:self.view];
}

- (void)showProgressHUDWithText:(NSString *)text superView:(UIView *)superview {
    if (!text.length
        || [text isEqualToString:self.prevHUD.detailsLabel.text]) {
        return;
    }
    
    BJLProgressHUD *hud = [BJLProgressHUD bjl_hudForTextWithSuperview:superview];
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

#pragma mark - action

- (void)prepareForEnterRoom {
    self.autoPlayVideoBlacklist = [NSMutableSet new];
    self.documentToolHidden = YES;
    self.majorWindowType = BJLScWindowType_ppt;
    self.minorWindowType = BJLScWindowType_teacherVideo;
    bjl_weakify(self);
    self.room.playingVM.autoPlayVideoBlock = ^BJLAutoPlayVideo(BJLMediaUser *user, NSInteger cachedDefinitionIndex) {
        bjl_strongify(self);
        NSString *videoKey = [self videoKeyForUser:user];
        BOOL autoPlay = videoKey && ![self.autoPlayVideoBlacklist containsObject:videoKey];
        NSInteger definitionIndex = cachedDefinitionIndex;
        if (autoPlay) {
            NSInteger maxDefinitionIndex = MAX(0, (NSInteger)user.definitions.count - 1);
            definitionIndex = (cachedDefinitionIndex <= maxDefinitionIndex
                               ? cachedDefinitionIndex : maxDefinitionIndex);
        }
        return BJLAutoPlayVideoMake(autoPlay, definitionIndex);
    };
    self.room.documentVM.whiteboard = ({
        BJLWhiteboard *whiteboard = [BJLWhiteboard new];
        whiteboard.width = 1600.0;
        whiteboard.height = 1200.0;
        whiteboard.urlString = @"https://img.baijiayun.com/0baijiatools/bed38ee1db799ecf13cfe2df92e46c1f/whiteboard.png";
        whiteboard;
    });
}

/**
 * force :是否要加入`大班课的学生不自动打开音视频`这个判断条件
*/
- (void)autoStartRecordingAudioAndVideoForce:(BOOL)force {
    if (self.room.loginUser.isAssistant) {
        return;
    }
    
    if (self.room.roomInfo.roomType == BJLRoomType_1vNClass
        && self.room.loginUser.isStudent
        && force) {
        return;
    }
    
    BOOL openVideo = !(self.room.loginUser.isStudent && !self.room.featureConfig.autoPublishVideoStudent);
    
    BOOL audioChange = !self.room.recordingVM.recordingAudio;
    BOOL videoChange = self.room.recordingVM.recordingVideo != openVideo;
    BJLError *error = [self.room.recordingVM setRecordingAudio:YES recordingVideo:openVideo];
    if (error) {
        [self showProgressHUDWithText:(error.localizedFailureReason ?: error.localizedDescription ?: @"麦克风、摄像头打开失败")];
        return;
    }
    
    NSString *message = nil;
    if (audioChange) {
        message = self.room.recordingVM.recordingAudio ? @"麦克风已打开" : @"麦克风已关闭";
    }
    if (videoChange) {
        message = self.room.recordingVM.recordingVideo ? @"摄像头已打开" : @"摄像头已关闭";
    }
    if (message) {
        [self showProgressHUDWithText:message];
    }
}

- (void)updateVideosConstraintsWithCurrentPlayingUsers {
    NSInteger count = self.room.mainPlayingAdapterVM.playingUsers.count + self.room.extraPlayingAdapterVM.playingUsers.count;
    
    // 老师窗口和其他用户分离，（老师在线，除了老师的音视频流，有一个以上 playinguser 的情况），（或是老师不在线或者当前登录用户是老师，有 1 个以上 playinguser 的情况），显示视频列表
    BOOL videosViewHidden = YES;
    if (self.room.loginUser.isTeacher) {
        // 目前移动端当老师不支持多个摄像头，因此只要有正在播放的流，就显示出列表
        if (count >= 1) {
            videosViewHidden = NO;
        }
    }
    else {
        BJLMediaUser *extraTeacher = nil;
        NSInteger mediaUserCount = 0; // 只有老师的的预期视频流数量
        for (BJLMediaUser *user in [self.room.mainPlayingAdapterVM.playingUsers copy]) {
            if (user.isTeacher) {
                mediaUserCount ++;
                break;
            }
        }
        for (BJLMediaUser *user in [self.room.extraPlayingAdapterVM.playingUsers copy]) {
            if (user.isTeacher) {
                extraTeacher = user;
                mediaUserCount ++;
                break;
            }
        }
        [self updateTeacherExtraVideoViewWithMediaUser:extraTeacher];
        // 如果实际的音视频流比 只有老师的的预期视频流数量 多，则显示视频列表
        if (count >= mediaUserCount + 1 || self.room.recordingVM.recordingVideo) {
            videosViewHidden = NO;
        }
    }
    [self updateVideosViewHidden:videosViewHidden];
}

- (NSString *)videoKeyForUser:(BJLMediaUser *)user {
    return [NSString stringWithFormat:@"%@-%td", user.number, user.mediaSource];
}

#pragma mark - observable methods

- (BJLObservable)roomViewControllerEnterRoomSuccess:(BJLScRoomViewController *)roomViewController {
    BJLMethodNotify((BJLScRoomViewController *),
                    roomViewController);
    if ([self.delegate respondsToSelector:@selector(roomViewControllerEnterRoomSuccess:)]) {
        [self.delegate roomViewControllerEnterRoomSuccess:self];
    }
}

- (BJLObservable)roomViewController:(BJLScRoomViewController *)roomViewController
           enterRoomFailureWithError:(BJLError *)error {
    BJLMethodNotify((BJLScRoomViewController *, BJLError *),
                    roomViewController, error);
    if ([self.delegate respondsToSelector:@selector(roomViewController:enterRoomFailureWithError:)]) {
        [self.delegate roomViewController:self enterRoomFailureWithError:error];
    }
}

- (BJLObservable)roomViewController:(BJLScRoomViewController *)roomViewController
                   willExitWithError:(nullable BJLError *)error {
    BJLMethodNotify((BJLScRoomViewController *, BJLError *),
                    roomViewController, error);
    if ([self.delegate respondsToSelector:@selector(roomViewController:willExitWithError:)]) {
        [self.delegate roomViewController:self willExitWithError:error];
    }
}

- (BJLObservable)roomViewController:(BJLScRoomViewController *)roomViewController
                    didExitWithError:(nullable BJLError *)error {
    BJLMethodNotify((BJLScRoomViewController *, BJLError *),
                    roomViewController, error);
    if ([self.delegate respondsToSelector:@selector(roomViewController:didExitWithError:)]) {
        [self.delegate roomViewController:self didExitWithError:error];
    }
}

#pragma mark - getter

- (BOOL)enableShare {
    return self.room.featureConfig.enableShare;
}

- (BOOL)is1V1Class {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return self.room.roomInfo.roomType == BJLRoomType_1v1Class || self.room.roomInfo.roomType == BJLRoomType_1to1;
#pragma clang diagnostic pop
}

- (BJLScSettingsViewController *)settingsViewController {
    if (!_settingsViewController) {
        _settingsViewController = [[BJLScSettingsViewController alloc] initWithRoom:self.room];
    }
    return _settingsViewController;
}

- (BJLScNoticeViewController *)noticeViewController {
    if (!_noticeViewController) {
        _noticeViewController = [[BJLScNoticeViewController alloc] initWithRoom:self.room];
    }
    return _noticeViewController;
}

- (BJLScNoticeEditViewController *)noticeEditViewController {
    if (!_noticeEditViewController) {
        _noticeEditViewController = [[BJLScNoticeEditViewController alloc] initWithRoom:self.room];
    }
    return _noticeEditViewController;
}
- (BJLScQuestionViewController *)questionViewController {
    if (!_questionViewController) {
        _questionViewController = [[BJLScQuestionViewController alloc] initWithRoom:self.room];
        bjl_weakify(self);
        [_questionViewController setReplyCallback:^(BJLQuestion * _Nonnull question, BJLQuestionReply * _Nullable reply) {
            bjl_strongify(self);
            [self.questionInputViewController updateWithQuestion:question];
            [self.overlayViewController showWithContentViewController:self.questionInputViewController contentView:nil];
            [self.questionInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.right.bottom.equalTo(self.overlayViewController.view);
            }];
        }];
        [_questionViewController setShowQuestionInputViewCallback:^{
            bjl_strongify(self);
            [self.questionInputViewController updateWithQuestion:nil];
            [self.overlayViewController showWithContentViewController:self.questionInputViewController contentView:nil];
            [self.questionInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.right.bottom.equalTo(self.overlayViewController.view);
            }];
        }];
    }
    return _questionViewController;
}

- (BJLScPPTManagerViewController *)pptManagerViewController {
    if (!_pptManagerViewController) {
        _pptManagerViewController = [[BJLScPPTManagerViewController alloc] initWithRoom:self.room];
        bjl_weakify(self);
        [_pptManagerViewController setUploadingCallback:^(NSInteger failedCount, void (^ _Nullable retry)(void)) {
            bjl_strongify(self);
            if (failedCount > 0) {
                [self showProgressHUDWithText:[NSString stringWithFormat:@"有%td个课件上传失败", failedCount]];
            }
            else {
                [self showProgressHUDWithText:@"课件上传完成"];
            }
        }];
    }
    return _pptManagerViewController;
}

- (BJLScSpeakRequestUsersViewController *)speakRequestUsersViewController {
    if (!_speakRequestUsersViewController) {
        _speakRequestUsersViewController = [[BJLScSpeakRequestUsersViewController alloc] initWithRoom:self.room];
        bjl_weakify(self);
        [_speakRequestUsersViewController setReceiveSpeakingRequestCallback:^(NSInteger count) {
            bjl_strongify(self);
            self.handUpButton.hidden = !((self.room.loginUser.isTeacherOrAssistant && self.room.loginUser.groupID == 0) && count > 0);
            // 只有大班老师或者和助教才可以处理举手
            if (self.room.loginUser.isTeacherOrAssistant && self.room.loginUser.groupID == 0) {
                self.userSpeakRequestRedDot.hidden = (count <= 0);
                self.userSpeakRequestRedDot.text = count > 99 ? @"···" : [NSString stringWithFormat:@"%td", count];
            }
            else {
                self.userSpeakRequestRedDot.hidden = YES;
            }
        }];
    }
    return _speakRequestUsersViewController;
}

- (BJLScChatInputViewController *)chatInputViewController {
    if (!_chatInputViewController) {
        _chatInputViewController = [[BJLScChatInputViewController alloc] initWithRoom:self.room];
        
        bjl_weakify(self);
        [_chatInputViewController setChangeChatStatusCallback:^(BJLChatStatus chatStatus, BJLUser * _Nullable targetUser) {
            bjl_strongify(self);
            if (self.segmentViewController) {
                [self.segmentViewController.chatViewController updateChatStatus:chatStatus withTargetUser:targetUser];
            }
            else {
                [self.chatViewController updateChatStatus:chatStatus withTargetUser:targetUser];
            }
        }];
        
        [_chatInputViewController setSelectImageFileCallback:^(ICLImageFile * _Nonnull file, UIImage * _Nullable image) {
            bjl_strongify(self);
            [self.overlayViewController hide];
            if (self.segmentViewController) {
                [self.segmentViewController.chatViewController refreshMessages];
                [self.segmentViewController.chatViewController sendImageFile:file image:image];
            }
            else {
                [self.chatViewController refreshMessages];
                [self.chatViewController sendImageFile:file image:image];
            }
        }];
        
        [_chatInputViewController setFinishCallback:^(NSString * _Nullable errorMessage) {
            bjl_strongify(self);
            [self.overlayViewController hide];
            if (errorMessage.length) {
                [self showProgressHUDWithText:errorMessage];
            }
            else {
                if (self.segmentViewController) {
                    [self.segmentViewController.chatViewController refreshMessages];
                }
                else {
                    [self.chatViewController refreshMessages];
                }
            }
        }];
    }
    return _chatInputViewController;
}

- (BJLScQuestionInputViewController *)questionInputViewController {
    if (!_questionInputViewController) {
        _questionInputViewController = ({
            BJLScQuestionInputViewController *vc = [[BJLScQuestionInputViewController alloc] initWithRoom:self.room];
            bjl_weakify(self);
            [vc setSendQuestionCallback:^(NSString * _Nonnull content) {
                bjl_strongify(self);
                [self.questionViewController sendQuestion:content];
                [self.questionViewController clearReplyQuestion];
                [self.overlayViewController hide];
                [self showQuestionViewController];
            }];
            [vc setSaveReplyCallback:^(BJLQuestion * _Nonnull question, NSString * _Nonnull reply) {
                bjl_strongify(self);
                [self.questionViewController updateQuestion:question reply:reply];
                [self.questionViewController clearReplyQuestion];
                [self.overlayViewController hide];
                [self showQuestionViewController];
            }];
            [vc setCancelCallback:^{
                bjl_strongify(self);
                [self.overlayViewController hide];
                [self.questionViewController clearReplyQuestion];
            }];
            vc;
        });
    }
    return _questionInputViewController;
}

@end
