//
//  BJLIcRoomViewController+actions.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase+Foundation.h>
#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJLAuthorization.h>

#import "BJLIcRoomViewController+actions.h"
#import "BJLIcRoomViewController+private.h"
#import "BJLIcAppearance.h"
#import "BJLIcPopoverViewController.h"
#import "BJLIcDocumentFileManagerViewController.h"
#import "BJLIcChatInputViewController.h"
#import "BJLIcChatDetailViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcRoomViewController (actions)

- (void)makeActions {

    [self makeStatusBarViewControllerActions];
    
    [self makeToolboxViewControllerActions];
    
    [self makeToolbarViewControllerActions];
    
    /* fire */
    
    [self switchToBlackboardLayout];
}

- (void)makeStatusBarViewControllerActions {
    bjl_weakify(self);

    [self.statusBarViewController.exitButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showExitPopoverViewController];
    }];
}

- (void)makeToolboxViewControllerActions {
    bjl_weakify(self);
    
    [self.toolboxViewController.coursewareButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
            [self updateDocumentFileDisplayListViewHidden:!!self.fileDisplayListViewController];
        }
        else {
            [self enterCoursewareMode];
        }
    }];
    
    [self.toolboxViewController.teachingAidButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self openTeachingAid];
    }];
}

- (void)makeToolbarViewControllerActions {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    bjl_weakify(self);
    
    [self.toolbarViewController.exitButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showExitPopoverViewController];
    }];
    
    [self.toolbarViewController.microphoneButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL on = !button.isSelected;
        [button bjl_disableForSeconds:[BJLIcAppearance sharedAppearance].robotDelayM];
        if (!self.room.loginUser.isTeacher && on) {
            BOOL isActive = NO;
            for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                if ([self.room.loginUser.number isEqualToString:user.number]) {
                    isActive = YES;
                    break;
                }
            }
            if (!isActive) {
                [self.promptViewController enqueueWithPrompt:@"未上台用户不能打开麦克风"];
            }
            else if (on && !self.room.loginUser.isTeacherOrAssistant) {
                [self.promptViewController enqueueWithPrompt:@"举手才能打开麦克风"];
            }
            else {
                [self updateRecordingAudio:on];
            }
        }
        else {
            [self updateRecordingAudio:on];
        }
    }];
    
    [self.toolbarViewController.cameraButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL on = !button.isSelected;
        [button bjl_disableForSeconds:[BJLIcAppearance sharedAppearance].robotDelayM];
        if (!self.room.loginUser.isTeacher && on) {
            BOOL isActive = NO;
            for (BJLMediaUser *user in [self.room.playingVM.playingUsers copy]) {
                if ([self.room.loginUser.number isEqualToString:user.number]) {
                    isActive = YES;
                    break;
                }
            }
            if (!isActive) {
                [self.promptViewController enqueueWithPrompt:@"未上台用户不能打开摄像头"];
            }
            else {
                [self updateRecordingVideo:on];
            }
        }
        else {
            [self updateRecordingVideo:on];
        }
    }];
    
    [self.toolbarViewController.blackboardLayoutButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        // version 1
        // !!!: 交互已改，切换到画廊布局不收回窗口
        [self switchToGalleryLayout];
        // request update
        [self.room.roomVM updateRoomLayout:BJLRoomLayout_gallary];
        // version 2
        // button.selected = YES;
        // [self switchToBlackboardLayout];
    }];
    
    [self.toolbarViewController.gallerylayoutButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        // version 1
        [self switchToBlackboardLayout];
        // request update
        [self.room.roomVM updateRoomLayout:BJLRoomLayout_blackboard];
        // version 2
        // button.selected = YES;
        // [self switchToGalleryLayout];
    }];
    
    [self.toolbarViewController.cloudRecordingButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL isSelected = button.isSelected;
        if (isSelected) {
            return;
        }
        [self startCloudRecordingAfterCheckState];
    }];
    
    [self.toolbarViewController.pauseCloudRecordingButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (!self.toolbarViewController.cloudRecordingButton.isSelected) {
            return;
        }
        BOOL isSelected = button.isSelected;
        button.selected = [self updateCloudRecording:isSelected] ? !isSelected : isSelected;
        if (!iPhone && BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType) {
            [self.toolbarViewController.cloudRecordingButton setTitle:button.isSelected?@"暂停录制":@"录制中..." forState:UIControlStateSelected];
        }
    }];
    
    [self.toolbarViewController.stopCloudRecordingButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (!self.toolbarViewController.cloudRecordingButton.isSelected) {
            return;
        }
        [self updateCloudRecording:NO];
        self.toolbarViewController.pauseCloudRecordingButton.selected = NO;
        self.toolbarViewController.cloudRecordingButton.selected = NO;
        if (!iPhone && BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType) {
            [self.toolbarViewController.cloudRecordingButton setTitle:@"录制中..." forState:UIControlStateSelected];
        }
    }];
    
    [self.toolbarViewController.coursewareButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        [self enterCoursewareMode];
    }];
    
    [self.toolbarViewController.teachingAidButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        [self openTeachingAid];
    }];
    
    [self.toolbarViewController.muteAllMicrophoneButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self updateAllRecordingAudioMute:YES];
    }];
    
    [self.toolbarViewController.unmuteAllMicrophoneButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self updateAllRecordingAudioMute:NO];
    }];
    
    [self.toolbarViewController.speakRequestButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL isSelected = button.isSelected;
        button.selected = [self updateSpeakRequest:!isSelected] ? !isSelected : isSelected;
    }];
    
    [self.toolbarViewController.forbidSpeakRequestButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL isSelected = button.isSelected;
        button.selected = [self updateForbidSpeakRequest:!isSelected] ? !isSelected : isSelected;
    }];
    
    [self.toolbarViewController.userListButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        [self updateUserListHidden:!button.isSelected];
    }];
    
    [self.toolbarViewController.chatListButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        [self updateChatListHidden:!button.isSelected];
    }];
    
    [self.requestSpeakinFullScreenButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        BOOL isSelected = button.isSelected;
        button.selected = [self updateSpeakRequest:!isSelected] ? !isSelected : isSelected;
    }];
}

#pragma mark - status bar

// 显示退出的弹框
- (void)showExitPopoverViewController {
    bjl_weakify(self);
    NSString *message = nil;
    if (self.room.loginUser.isTeacher) {
        message = @"正在关闭教室, 是否结束授课?";
    }
    else {
        message = @"是否退出教室？";
    }
    BJLIcPopoverViewType type = BJLIcExitViewNormal;
    if (self.room.featureConfig.enableExpressExport && self.room.loginUser.isTeacher && self.room.roomVM.liveStarted) {
        // 仅老师有是否生成表情报告提示
        type = BJLIcExitViewAppend;
    }
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:type message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self exit];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [popoverViewController setAppendCallback:^{
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:@"请求表情报告中，请稍候"];
        [self.room.roomVM sendLiveStarted:NO];
    }];
}

#pragma mark - tool box

// 显示文档管理视图
- (void)enterCoursewareMode {
    [self bjl_addChildViewController:self.documentFileManagerViewController superview:self.fullscreenLayer];
    [self.documentFileManagerViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.fullscreenLayer);
    }];
}

//打开教具
- (void)openTeachingAid {
    [self bjl_addChildViewController:self.teachingAidViewController superview:self.fullscreenLayer];
    [self.teachingAidViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.fullscreenLayer);
    }];
}

// 小黑板
- (void)requsetAddWritingBoard {
    if (!self.room.loginUser.isTeacher) {
        [self.promptViewController enqueueWithPrompt:@"老师才能打开小黑板"];
        return;
    }
    if (!self.room.roomVM.liveStarted) {
        [self.promptViewController enqueueWithPrompt:@"上课状态才能打开小黑板"];
        return;
    }
    
    //每次添加小黑板时, 先pull一次当前小黑板状态
    [self.room.documentVM pullWritingBoard:BJLWritingboardID];
}

// 打开网页
- (void)openWebView {
    [self.blackboardLayoutViewController openWebView];
}

// 计时器
- (void)openCountDown {
    if (!self.room.loginUser.isTeacher) {
        [self.promptViewController enqueueWithPrompt:@"老师才能使用计时器"];
        return;
    }
    if (!self.room.roomVM.liveStarted) {
        [self.promptViewController enqueueWithPrompt:@"上课状态才能使用计时器"];
        return;
    }
    [self.blackboardLayoutViewController openCountDownTimer];
}

// 答题器
- (void)openQuestionAnswer {
    if (!self.room.loginUser.isTeacher) {
        [self.promptViewController enqueueWithPrompt:@"老师才能使用答题器"];
        return;
    }
    if (!self.room.roomVM.liveStarted) {
        [self.promptViewController enqueueWithPrompt:@"上课状态才能使用答题器"];
        return;
    }
    
    [self.blackboardLayoutViewController openQuestionAnswer];
}

// 抢答器
- (void)openQuestionResponder {
    if (!self.room.loginUser.isTeacher) {
        [self.promptViewController enqueueWithPrompt:@"老师才能使用抢答器"];
        return;
    }
    if (!self.room.roomVM.liveStarted) {
        [self.promptViewController enqueueWithPrompt:@"上课状态才能使用抢答器"];
        return;
    }
    
    [self.blackboardLayoutViewController openQuestionResponder];
}

- (void)updateDocumentFileDisplayListViewHidden:(BOOL)hidden {
    if (hidden) {
        [self.documentFileDisplayListView hideContainerView];
        [self.documentFileDisplayListView removeFromSuperview];
        [self.fileDisplayListViewController bjl_removeFromParentViewControllerAndSuperiew];
        self.fileDisplayListViewController = nil;
    }
    else {
        if ([self.childViewControllers containsObject:self.fileDisplayListViewController]) {
            return;
        }
        [self.userViewController bjl_removeFromParentViewControllerAndSuperiew];
        [self.chatViewController bjl_removeFromParentViewControllerAndSuperiew];
        self.toolbarViewController.userListButton.selected = NO;
        self.toolbarViewController.chatListButton.selected = NO;
        self.toolbarViewController.userListRedDot.hidden = YES;
        self.toolbarViewController.chatListRedDot.hidden = YES;
        self.fileDisplayListViewController = [UIViewController new];
        self.fileDisplayListViewController.view.accessibilityLabel = @"fileDisplayListViewController";
        bjl_weakify(self);
        UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (self.toolboxViewController.coursewareButton.isSelected) {
                [self.toolboxViewController.coursewareButton sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
            else {
                [self updateDocumentFileDisplayListViewHidden:YES];
            }
        }];
        [self.fileDisplayListViewController.view addGestureRecognizer:tapGesture];
        [self.blackboardLayoutViewController bjl_addChildViewController:self.fileDisplayListViewController superview:self.blackboardLayoutViewController.blackboardLayer];
        [self.fileDisplayListViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.blackboardLayoutViewController.blackboardLayer);
        }];
        
        [self.documentFileDisplayListView removeFromSuperview];
        [self.fileDisplayListViewController.view addSubview:self.documentFileDisplayListView];
        [self.documentFileDisplayListView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.fileDisplayListViewController.view);
            make.width.equalTo(@(160.0));
            make.top.bottom.equalTo(self.blackboardLayoutViewController.blackboardLayer);
        }];
        [self.documentFileDisplayListView showContainerView];
    }
}

#pragma mark - tool bar

- (BOOL)updateRecordingAudio:(BOOL)on {
    return [self updateRecordingAudio:on recordingVideo:self.room.recordingVM.recordingVideo]; 
}
- (BOOL)updateRecordingVideo:(BOOL)on {
    return [self updateRecordingAudio:self.room.recordingVM.recordingAudio recordingVideo:on];
}

- (BOOL)updateRecordingAudio:(BOOL)audio recordingVideo:(BOOL)video {
    if (self.room.recordingVM.recordingAudio == audio
        && self.room.recordingVM.recordingVideo == video) {
        return YES;
    }
    BOOL audioChange = self.room.recordingVM.recordingAudio != audio;
    BOOL videoChange = self.room.recordingVM.recordingVideo != video;
    BJLError *error = [self.room.recordingVM setRecordingAudio:audio recordingVideo:video];
    if (error) {
        [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
    }
    else {
        if (audioChange) {
            [self.promptViewController enqueueWithPrompt:(self.room.recordingVM.recordingAudio
                                                          ? @"麦克风已打开"
                                                          : @"麦克风已关闭")];
        }
        if (videoChange) {
            [self.promptViewController enqueueWithPrompt:(self.room.recordingVM.recordingVideo
                                                          ? @"摄像头已打开"
                                                          : @"摄像头已关闭")];
        }
    }
    return !error;
}

// 切换成画廊布局
- (void)switchToGalleryLayout {
    // 切换到画廊布局
    if ([self.childViewControllers containsObject:self.videosGridLayoutViewController]) {
        return;
    }
    self.toolbarViewController.blackboardLayoutButton.hidden = YES;
    self.toolbarViewController.gallerylayoutButton.hidden = NO;
    self.toolboxViewController.view.hidden = YES;
    self.documentFileDisplayListView.hidden = YES;
    [self.blackboardLayoutViewController bjl_removeFromParentViewControllerAndSuperiew];
    if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self.toolbarViewController updateTeacherMediaInfoViewLeaveSeat:YES];
    }
    [self bjl_addChildViewController:self.videosGridLayoutViewController superview:self.layoutContainer];
    [self.videosGridLayoutViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.layoutContainer);
    }];
    self.currentRoomLayout = BJLRoomLayout_gallary;
}

// 切换成板书布局
- (void)switchToBlackboardLayout {
    // 切换到板书布局
    if ([self.childViewControllers containsObject:self.blackboardLayoutViewController]) {
        return;
    }
    self.toolbarViewController.blackboardLayoutButton.hidden = NO;
    self.toolbarViewController.gallerylayoutButton.hidden = YES;
    self.toolboxViewController.view.hidden = NO;
    self.documentFileDisplayListView.hidden = NO;
    [self.videosGridLayoutViewController bjl_removeFromParentViewControllerAndSuperiew];
    if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self.toolbarViewController updateTeacherMediaInfoViewLeaveSeat:NO];
    }
    [self bjl_addChildViewController:self.blackboardLayoutViewController superview:self.layoutContainer];
    [self.blackboardLayoutViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.layoutContainer);
    }];
    [self.blackboardLayoutViewController.blackboardLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.blackboardLayer);
    }];
    [self.blackboardLayoutViewController.videosLayer bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.videosLayer);
    }];
    self.currentRoomLayout = BJLRoomLayout_blackboard;
}

- (void)startCloudRecordingAfterCheckState {
    if (self.room.serverRecordingVM.serverRecording) {
        return;
    }
    bjl_weakify(self);
    [self.room.serverRecordingVM requestServerRecordingState:^{
        bjl_strongify(self);
        switch (self.room.serverRecordingVM.state) {
            case BJLServerRecordingState_ready:
            case BJLServerRecordingState_transcoding: {
                self.toolbarViewController.cloudRecordingButton.selected = [self updateCloudRecording:YES];
                break;
            }
                
            case BJLServerRecordingState_recording: {
                BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcStartCloudRecord];
                [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
                [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                    make.edges.equalTo(self.popoversLayer);
                }];
                bjl_weakify(self);
                [popoverViewController setCancelCallback:^{
                    bjl_strongify(self);
                    self.toolbarViewController.cloudRecordingButton.selected = [self startNewCloudRecoring];
                }];
                [popoverViewController setConfirmCallback:^{
                    bjl_strongify(self);
                    self.toolbarViewController.cloudRecordingButton.selected = [self updateCloudRecording:YES];
                }];
                break;
            }
                
            case BJLServerRecordingState_disable: {
                self.toolbarViewController.cloudRecordingButton.selected = NO;
                [self.promptViewController enqueueWithPrompt:@"云端录制不可用"];
                break;
            }
                
            default:
                break;
        }
    }];
}

// 开启新的云端录制
- (BOOL)startNewCloudRecoring {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        [self.promptViewController enqueueWithPrompt:@"当前用户无法录制"];
        return NO;
    }
    bjl_weakify(self);
    /* 开启新的录制需要请求服务器将之前的录制转码，
    目前为了UI友好，在点击新的录制直接将按钮置为选中，
     如果需要更准确的反应录制状态，
     只有在监听到录制的广播的时候才改变按钮状态，
     这样可能出现点击按钮一段时间之后才会变成选中状态 */
    [self bjl_observe:BJLMakeMethod(self.room.serverRecordingVM, requestServerRecordingTranscodeAccept)
             observer:^BOOL{
                 bjl_strongify(self);
                 [self updateCloudRecording:YES];
                 return NO;
             }];
    BJLError *error = [self.room.serverRecordingVM requestServerRecordingTranscode];
    if (error) {
        [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
    }
    return !error;
}

// 开启云端录制
- (BOOL)updateCloudRecording:(BOOL)recording {
    if (!self.room.loginUser.isTeacherOrAssistant) {
        self.toolbarViewController.cloudRecordingButton.selected = NO;
        [self.promptViewController enqueueWithPrompt:@"当前用户无法录制"];
        return NO;
    }
    
    BJLUser *presenter = self.room.onlineUsersVM.currentPresenter;
    BJLMediaUser *mediaPresenter = [self.room.playingVM playingUserWithID:presenter.ID
                                                                   number:presenter.number
                                                              mediaSource:BJLMediaSource_mainCamera];
    if (!mediaPresenter.videoOn && !mediaPresenter.audioOn) {
        [self.promptViewController enqueueWithPrompt:@"主讲人未开启采集不能录制"];
        return NO;
    }
    BJLError *error = [self.room.serverRecordingVM requestServerRecording:recording];
    if (error) {
        self.toolbarViewController.cloudRecordingButton.selected = NO;
        [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
    }
    return !error;
}

- (void)updateAllRecordingAudioMute:(BOOL)mute {
    BJLError *error = [self.room.recordingVM updateAllRecordingAudioMute:mute];
    if (error) {
        [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
    }
}

// 禁止举手
- (BOOL)updateForbidSpeakRequest:(BOOL)forbid {
    BJLError *error = [self.room.speakingRequestVM requestForbidSpeakingRequest:forbid];
    if (error) {
        [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
    }
    return !error;
}

// 用户列表
- (void)updateUserListHidden:(BOOL)isHidden {
    if (isHidden) {
        [self.userViewController bjl_removeFromParentViewControllerAndSuperiew];
    }
    else {
        if ([self.childViewControllers containsObject:self.userViewController]) {
            return;
        }
        [self.chatViewController bjl_removeFromParentViewControllerAndSuperiew];
        if (self.toolboxViewController.coursewareButton.isSelected && BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
            [self.toolboxViewController.coursewareButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        self.toolbarViewController.chatListButton.selected = NO;
        self.toolbarViewController.userListRedDot.hidden = YES;
        [self bjl_addChildViewController:self.userViewController superview:self.widgetContainer];
        [self.userViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.widgetContainer);
        }];
    }
}

// 聊天列表
- (void)updateChatListHidden:(BOOL)isHidden {
    if (isHidden) {
        [self.chatViewController bjl_removeFromParentViewControllerAndSuperiew];
    }
    else {
        if ([self.childViewControllers containsObject:self.chatViewController]) {
            return;
        }
        [self.userViewController bjl_removeFromParentViewControllerAndSuperiew];
        if (self.toolboxViewController.coursewareButton.isSelected && BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
            [self.toolboxViewController.coursewareButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        self.toolbarViewController.userListButton.selected = NO;
        self.toolbarViewController.chatListRedDot.hidden = YES;
        [self bjl_addChildViewController:self.chatViewController superview:self.widgetContainer];
        [self.chatViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.widgetContainer);
        }];
        bjl_weakify(self);
        [self.chatViewController setShowChatInputViewCallback:^(NSString *text) {
            bjl_strongify(self);
            BJLIcChatInputViewController *chatInputViewController = [[BJLIcChatInputViewController alloc] initWithText:text];
            [self bjl_addChildViewController:chatInputViewController superview:self.popoversLayer];
            [chatInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.edges.equalTo(self.popoversLayer);
            }];
            [chatInputViewController setEditCallback:^(NSString * _Nonnull text) {
                bjl_strongify(self);
                [self.chatViewController sendText:text];
            }];
        }];
        [self.chatViewController setShowChatDetailViewCallback:^(BJLMessage * _Nonnull message, NSArray<BJLMessage *> * _Nonnull imageMessages) {
            bjl_strongify(self);
            BJLIcChatDetailViewController *chatDetailViewController = [[BJLIcChatDetailViewController alloc] initWithMessage:message imageMessages:imageMessages];
            [self bjl_addChildViewController:chatDetailViewController superview:self.fullscreenLayer];
            [chatDetailViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.edges.equalTo(self.fullscreenLayer);
            }];
        }];
        [self.chatViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
            bjl_strongify(self);
            [self.promptViewController enqueueWithPrompt:message];
        }];
    }
}

// 更新举手状态
- (BOOL)updateSpeakRequest:(BOOL)requestSpeak {
    if (requestSpeak) {
        if (self.room.loginUser.isTeacherOrAssistant) {
            return NO;
        }
        if (self.room.featureConfig.disableSpeakingRequest) {
            [self.promptViewController enqueueWithPrompt:self.room.featureConfig.disableSpeakingRequestReason ?: @"举手功能被禁用"];
            return NO;
        }
        if (self.room.speakingRequestVM.forbidSpeakingRequest) {
            [self.promptViewController enqueueWithPrompt:@"老师设置了禁止举手"];
            return NO;
        }
        if (self.room.speakingRequestVM.speakingRequestTimeRemaining > 0.0) {
            [self.room.speakingRequestVM stopSpeakingRequest];
            return NO;
        }
        
        BJLError *error = [self.room.speakingRequestVM sendSpeakingRequest];
        if (error) {
            [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
        }
        else {
            [self.promptViewController enqueueWithPrompt:@"举手中，等待老师同意"];
        }
        return !error;
    }
    else {
        [self.room.speakingRequestVM stopSpeakingRequest];
        [self.promptViewController enqueueWithPrompt:@"已取消举手"];
    }
    return YES;
}

#pragma mark -

#if DEBUG
- (void)makeDebugActions {
    bjl_weakify(self);
    
    [self.toolbarViewController.widgetButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        self.widgetLayer.hidden = button.selected;
    }];
    
    [self.toolbarViewController.settingsButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        self.settingsLayer.hidden = button.selected;
    }];
    
    [self.toolbarViewController.fullscreenButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        self.fullscreenLayer.hidden = button.selected;
    }];
    
    [self.toolbarViewController.popoversButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        button.selected = !button.isSelected;
        self.popoversLayer.hidden = button.selected;
    }];
    
    /* fire */
    
    { // TEST
        // [self.toolbarViewController.widgetButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        // [self.toolbarViewController.settingsButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        // [self.toolbarViewController.fullscreenButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        // [self.toolbarViewController.popoversButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}
#endif

@end

NS_ASSUME_NONNULL_END
