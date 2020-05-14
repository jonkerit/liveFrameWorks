//
//  BJLScRoomViewController+actions.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController+actions.h"
#import "BJLScRoomViewController+private.h"
#import "BJLScImageViewController.h"

@implementation BJLScRoomViewController (actions)

- (void)makeActionsOnViewDidLoad {
    bjl_weakify(self);

#pragma mark - topBar
    
    [self.topBarViewController setExitCallback:^{
        bjl_strongify(self);
        [self exit];
    }];

    [self.topBarViewController setShowSettingCallback:^{
        bjl_strongify(self);
        [self.overlayViewController showWithContentViewController:self.settingsViewController contentView:nil];
        [self.settingsViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.bottom.equalTo(self.overlayViewController.view);
            make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
        }];
    }];
    
#pragma mark - minorContentView
    
    UITapGestureRecognizer *minorContentViewGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        // 如果小窗为老师 & 老师不在教室时, 不响应点击手势
        if (!self.teacherMediaInfoView && self.minorWindowType == BJLScWindowType_teacherVideo) {
            return;
        }
        if (self.minorWindowType == BJLScWindowType_teacherVideo) {
            [self showMenuForTeacherVideo];
        }
        else if (self.minorWindowType == BJLScWindowType_ppt) {
            // 小屏幕是PPT时，大屏幕只能是老师视频
            if (self.majorWindowType != BJLScWindowType_teacherVideo) {
                return;
            }
            
            if (self.teacherExtraMediaInfoView) {
                BJLMediaUser *mediaUser = self.teacherExtraMediaInfoView.mediaUser;
                if (mediaUser.videoOn) {
                    BOOL playingVideo = [self isVideoPlayingUser:mediaUser];
    
                    BJLError *error = [self.room.playingVM updatePlayingUserWithID:mediaUser.ID videoOn:!playingVideo mediaSource:mediaUser.mediaSource];
                    if (error) {
                        [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                    }
                    else {
                        // 主动关闭老师辅助摄像头后不再自动打开
                        [self.teacherExtraMediaInfoView updateCloseVideoPlaceholderHidden:!playingVideo];
                        [self updateAutoPlayVideoBlacklist:mediaUser add:playingVideo];
                        [self showProgressHUDWithText:playingVideo ? @"已关闭视频" : @"已开启视频"];
                    }
                }
            }
        }
    }];
    [self.minorContentView addGestureRecognizer:minorContentViewGesture];

#pragma mark - videosViewController
    
    [self.videosViewController setReplaceMajorWindowCallback:^(BJLScMediaInfoView * _Nullable mediaInfoView, NSInteger index, BJLScWindowType majorWindowType, BOOL recording) {
        bjl_strongify(self);
        if (majorWindowType == BJLScWindowType_userVideo) {
            // 预期将全屏替换成用户视频
            switch (self.majorWindowType) {
                case BJLScWindowType_ppt:
                    // 全屏为 PPT 或者老师辅助摄像头
                    [self.videosViewController replaceMajorContentViewAtIndex:index recording:recording teacherExtraMediaInfoView:self.teacherExtraMediaInfoView];
                    break;
                    
                case BJLScWindowType_userVideo:
                    // 全屏为用户视频，此时 PPT 或者老师辅助摄像头在视频列表区域
                    [self.videosViewController replaceMajorContentViewAtIndex:index recording:recording teacherExtraMediaInfoView:self.teacherExtraMediaInfoView];
                    [self replaceMajorContentViewWithUserMediaInfoView:mediaInfoView];
                    break;
                    
                case BJLScWindowType_teacherVideo:
                    // 全屏为老师视频，先把老师替换到小屏，把小屏 PPT 或者老师辅助摄像头放到视频列表
                    [self replaceMinorContentViewWithTeacherMediaInfoView];
                    [self.videosViewController replaceMajorContentViewAtIndex:index recording:recording teacherExtraMediaInfoView:self.teacherExtraMediaInfoView];
                    break;
                    
                default:
                    break;
            }
            [self replaceMajorContentViewWithUserMediaInfoView:mediaInfoView];
        }
        else if (majorWindowType == BJLScWindowType_ppt) {
            // 收回 PPT 或者老师辅助摄像头
            [self.videosViewController replaceMajorContentViewAtIndex:index recording:recording teacherExtraMediaInfoView:nil];
            [self replaceMajorContentViewWithPPTView];
        }
    }];
    
    [self.videosViewController setResetPPTCallback:^{
        bjl_strongify(self);
        [self.videosViewController resetVideo];
        [self replaceMajorContentViewWithPPTView];
    }];
    
    [self.videosViewController setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
        bjl_strongify(self);
        [self updateAutoPlayVideoBlacklist:user add:on];
    }];
    
#pragma mark - documentToolView
    
    [self.documentToolView setPenCallback:^{
        bjl_strongify(self);
        BOOL enable = !self.room.slideshowViewController.drawingEnabled;
        if (enable) {
            if (self.room.loginUser.isTeacherOrAssistant) {
                if (!self.room.roomVM.liveStarted) {
                    [self showProgressHUDWithText:@"上课状态才能开启画笔"];
                    return ;
                }
            }
            else if (self.room.featureConfig.disableSpeakingRequest) {
                [self showProgressHUDWithText:@"画笔功能被禁用"];
                return ;
            }
            else if (!self.room.drawingVM.drawingGranted) {
                [self showProgressHUDWithText:@"未被授权使用画笔"];
                return ;
            }
            
            if (self.room.slideshowViewController.localPageIndex != self.room.documentVM.currentSlidePage.documentPageIndex) {
                [self showProgressHUDWithText:@"PPT 翻页与老师不同步，不能开启画笔"];
                return ;
            }
        }
        
        if (self.majorWindowType == BJLScWindowType_userVideo) {
            [self.videosViewController resetVideo];
            [self replaceMajorContentViewWithPPTView];
        }
        
        if (self.majorWindowType == BJLScWindowType_teacherVideo) {
            [self replaceMajorContentViewWithPPTView];
            [self replaceMinorContentViewWithTeacherMediaInfoView];
        }
        
        BJLError *error = [self.room.drawingVM updateDrawingEnabled:enable];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }];
    
    [self.documentToolView setClearDrawingCallback:^{
        bjl_strongify(self);
        if (!self.room.roomVM.liveStarted) {
            [self showProgressHUDWithText:@"上课状态才能使用画笔"];
            return ;
        }
        else if (self.room.featureConfig.disableSpeakingRequest) {
            [self showProgressHUDWithText:@"画笔功能被禁用"];
            return ;
        }
        else if (!self.room.drawingVM.drawingGranted) {
            [self showProgressHUDWithText:@"未被授权使用画笔"];
            return ;
        }
        
        if (self.room.slideshowViewController.localPageIndex != self.room.documentVM.currentSlidePage.documentPageIndex) {
            [self showProgressHUDWithText:@"PPT 翻页与老师不同步，不能开启画笔"];
            return ;
        }

        [self.room.slideshowViewController clearDrawing];
    }];
    
    [self.documentToolView setShowCoursewareCallback:^{
        bjl_strongify(self);
        [self.overlayViewController showWithContentViewController:self.pptManagerViewController contentView:nil];
        [self.pptManagerViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.right.bottom.equalTo(self.overlayViewController.view);
            make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
        }];
    }];

    [self.documentToolView setHiddenCallback:^(BOOL hidden) {
        bjl_strongify(self);
        self.documentToolView.hidden = hidden;
        self.documentToolHidden = hidden;
    }];
    
    [self.documentToolView setOpenCountDownCallback:^{
        bjl_strongify(self);
        if (!self.room.loginUser.isTeacher) {
            return ;
        }
        
        if (!self.countDownEditViewController) {
            self.countDownEditViewController = [[BJLScCountDownEditViewController alloc] initWithRoom:self.room
                                                                                            totalTime:self.countDownViewController.originCountDownTime
                                                                                 currentCountDownTime:self.countDownViewController.currentCountDownTime
                                                                                           isDecrease:self.countDownViewController.isDecrease];
            [self.countDownEditViewController setCloseCallback:^{
                bjl_strongify(self);
                [self.overlayViewController hide];
            }];
        }
        
        [self.overlayViewController showWithContentViewController:self.countDownEditViewController contentView:nil];
        [self.countDownEditViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.overlayViewController.view.bjl_safeAreaLayoutGuide ?: self.overlayViewController.view);
            make.right.bottom.equalTo(self.overlayViewController.view.bjl_safeAreaLayoutGuide ?: self.overlayViewController.view);
            make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
        }];
    }];
    
    // 大小班切换时, 用户角色可能变化,需要更新画笔工具的约束
    [self.documentToolView setRemakeConstraintsCallback:^{
        bjl_strongify(self);
        if (self.documentToolView.superview) {
            [self.documentToolView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.height.equalTo(@(self.documentToolView.expectedSize.height)).priorityHigh();
            }];
        }
    }];
    
#pragma mark - overlay
    
    [self.overlayViewController setShowCallback:^{
        bjl_strongify(self);
        [self bjl_addChildViewController:self.overlayViewController superview:self.overlayView];
        [self.overlayViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.overlayView);
        }];
    }];
    
#pragma mark - segmentViewController

    [self.segmentViewController setShowChatInputViewCallback:^(BOOL whisperChatUserExpend) {
        bjl_strongify(self);
        [self showChatInputViewWithWhisperChatUserExpend:whisperChatUserExpend];
    }];
    
    [self.segmentViewController setShowImageViewCallback:^(BJLMessage *currentImageMessage, NSArray<BJLMessage *> *imageMessages, BOOL isStickyMessage) {
        bjl_strongify(self);
        [self showFullImageWithMessage:currentImageMessage
                         imageMessages:imageMessages
                       isStickyMessage:isStickyMessage];
    }];
    
    [self.segmentViewController setChangeChatStatusCallback:^(BJLChatStatus chatStatus, BJLUser * _Nullable targetUser) {
        bjl_strongify(self);
        [self.chatInputViewController updateChatStatus:chatStatus withTargetUser:targetUser];
    }];
    
    [self.segmentViewController setShowQuestionInputViewCallback:^(BJLQuestion * _Nonnull question) {
        bjl_strongify(self);
        [self.questionInputViewController updateWithQuestion:question];
        [self.overlayViewController showWithContentViewController:self.questionInputViewController contentView:nil];
        [self.questionInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.bottom.equalTo(self.overlayViewController.view);
        }];
    }];

#pragma mark - handUpButton
    
    [self.handUpButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        bjl_returnIfRobot(BJLScRobotDelayS);
        if (self.room.loginUser.isStudent) {
            if (self.room.speakingRequestVM.speakingEnabled
                || (self.room.speakingRequestVM.speakingRequestTimeRemaining > 0)) {
                [self.room.speakingRequestVM stopSpeakingRequest];
            }
            else {
                if (self.room.featureConfig.disableSpeakingRequest) {
                    [self showProgressHUDWithText:self.room.featureConfig.disableSpeakingRequestReason ?: @"举手功能被禁用"];
                    return;
                }
                if (self.room.speakingRequestVM.forbidSpeakingRequest) {
                    [self showProgressHUDWithText:@"老师设置了禁止举手"];
                    return;
                }
                
                BJLError *error = [self.room.speakingRequestVM sendSpeakingRequest];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                else {
                    [self showProgressHUDWithText:@"举手中，等待老师同意"];
                }
            }
        }
        else {
            [self.overlayViewController showWithContentViewController:self.speakRequestUsersViewController contentView:nil];
            [self.speakRequestUsersViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.right.bottom.equalTo(self.overlayViewController.view);
                make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
            }];
        }
    }];
    #pragma mark - handUpButton
     #pragma mark - 修改处
    [self.opertionScreenBtn bjl_addHandler:^(UIButton * _Nonnull button) {
        button.selected = !button.isSelected;
        self.segmentView.hidden = button.isSelected;
        self.minorContentView.hidden = button.isSelected;
        // 选中的是全屏，分选中的是3分屏
        if (button.isSelected) {
            [self.majorContentView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.containerView);
            }];
        } else {
            [self.majorContentView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.bottom.equalTo(self.containerView);
                make.top.equalTo(self.videosView.bjl_bottom);
                make.right.equalTo(self.segmentView.bjl_left);
            }];
        }
    }];
    
     #pragma mark - 修改处
    // 全屏切换
    [self.changeScreenButton bjl_addHandler:^(UIButton * _Nonnull button) {
        button.selected = !button.isSelected;
        if (button.isSelected) {
            [self replaceMajorContentViewWithTeacherMediaInfoView];
            [self replaceMinorContentViewWithPPTView];
        } else {
            [self replaceMajorContentViewWithPPTView];
            [self replaceMinorContentViewWithTeacherMediaInfoView];
        }
    }];
    
#pragma mark - videoButton

    [self.videoButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:BJLScRobotDelayM];
        BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                    recordingVideo:!self.room.recordingVM.recordingVideo];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
        else {
            [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                           ? @"摄像头已打开"
                                           : @"摄像头已关闭")];
        }

    }];
    
#pragma mark - audioButton
    
    [self.audioButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:BJLScRobotDelayM];
        BJLError *error = [self.room.recordingVM setRecordingAudio:!self.room.recordingVM.recordingAudio
                                                    recordingVideo:self.room.recordingVM.recordingVideo];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
        else {
            [self showProgressHUDWithText:(self.room.recordingVM.recordingAudio
                                           ? @"麦克风已打开"
                                           : @"麦克风已关闭")];
        }

    }];
    
    [self.noticeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.room.loginUser.isTeacherOrAssistant) {
            [self.overlayViewController showWithContentViewController:self.noticeEditViewController contentView:nil];
            [self.noticeEditViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.right.bottom.equalTo(self.overlayViewController.view);
                make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
            }];
        }
        else {
            [self.overlayViewController showWithContentViewController:self.noticeViewController contentView:nil];
            [self.noticeViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.right.bottom.equalTo(self.overlayViewController.view);
                make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
            }];
        }
    }];
    
    [self.questionButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self showQuestionViewController];
    }];

#pragma mark - 1v1
    
    if (self.is1V1Class) {
        [self.chatViewController setShowImageViewCallback:^(BJLMessage *currentImageMessage, NSArray<BJLMessage *> *imageMessages, BOOL isStickyMessage) {
               bjl_strongify(self);
               [self showFullImageWithMessage:currentImageMessage
                                imageMessages:imageMessages
                              isStickyMessage:isStickyMessage];
        }];
        [self.chatViewController setShowChatInputViewCallback:^(BOOL whisperChatUserExpend) {
            bjl_strongify(self);
            [self showChatInputViewWithWhisperChatUserExpend:whisperChatUserExpend];
        }];
        [self.chatViewController setNewMessageCallback:^(NSInteger count) {
            bjl_strongify(self);
            if (self.chatButton) {
                self.chatRedDot.hidden = !count;
            }
        }];
        
        [self.chatButton bjl_addHandler:^(UIButton * _Nonnull button) {
            bjl_strongify(self);
            [self bjl_addChildViewController:self.chatViewController superview:self.segmentView];
            [self.chatViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.segmentView);
            }];
        }];
        
        [self.chatViewController setBackToVideoCallback:^{
            bjl_strongify(self);
            [self.chatViewController bjl_removeFromParentViewControllerAndSuperiew];
        }];
        UITapGestureRecognizer *secondMinorContentViewGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (self.secondMinorMediaInfoView) {
                [self showMenuForStudentVideo];
            }
        }];
        [self.secondMinorContentView addGestureRecognizer:secondMinorContentViewGesture];
    }
    
    // gesture
    [self makeGestureAction];
}

#pragma mark - Question

- (void)showQuestionViewController {
    [self.overlayViewController showWithContentViewController:self.questionViewController contentView:nil];
    [self.questionViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.right.bottom.equalTo(self.overlayViewController.view);
        make.width.equalTo(self.overlayViewController.view).multipliedBy(0.5);
    }];
    [self.questionViewController updateSegmentHidden:NO];
    [self updateQuestionRedDotHidden:YES];
}

- (void)updateQuestionRedDotHidden:(BOOL)hidden {
    self.questionRedDotHidden = hidden;
    self.questionRedDot.hidden = hidden || self.questionButton.hidden;
}

#pragma mark - gesture

- (void)makeGestureAction {
    bjl_weakify(self);
    [self.majorContentView addGestureRecognizer:[UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if (self.room.drawingVM.drawingEnabled) {
            return ;
        }
        
        [self setControlsHidden:!self.controlsHidden animated:NO];
    }]];
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated {
    self.controlsHidden = hidden;
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    BOOL topBarViewHidden = hidden && !iPad && !self.is1V1Class;
    self.topBarView.hidden = topBarViewHidden;
    [self.topBarView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(topBarViewHidden ? @(0) : @(BJLScTopBarHeight));
    }];
    
    [self updateButtonStates];
    
    // drawingEnabled 画笔使用中时 不可隐藏.
    self.documentToolView.hidden = !self.room.drawingVM.drawingEnabled && (self.documentToolHidden || hidden);
}

#pragma mark -

- (void)showFullImageWithMessage:(BJLMessage *)currentImageMessage imageMessages:(NSArray<BJLMessage *> *)imageMessages isStickyMessage:(BOOL)isStickyMessage{
    BJLScImageViewController *imageViewController = [[BJLScImageViewController alloc] initWithMessage:currentImageMessage imageMessages:imageMessages isStickyMessage:isStickyMessage && self.room.loginUser.isTeacherOrAssistant];
    bjl_weakify(self, imageViewController);
    [imageViewController setCancelStickyCallback:^{
        bjl_strongify(self, imageViewController);
        if (self.room.loginUser.isTeacherOrAssistant) {
            BJLError *error = [self.room.chatVM sendStickyMessage:nil];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
            }
            else {
                [imageViewController hide];
            }
        }
    }];
    
    [self bjl_addChildViewController:imageViewController superview:self.imageViewLayer];
    [imageViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.imageViewLayer);
    }];
}

- (void)showChatInputViewWithWhisperChatUserExpend:(BOOL)whisperChatUserExpend {
    if (!self.room.loginUser.isTeacherOrAssistant
        && (self.room.chatVM.forbidMe)) {
        [self showProgressHUDWithText:@"禁言状态不能发送消息"];
        return;
    }
    
    if (self.room.loginUser.isAudition) {
        [self showProgressHUDWithText:@"试听用户不能发送消息"];
        return;
    }

    if (whisperChatUserExpend) {
        [self.chatInputViewController showWhisperChatList];
    }
    
    [self.overlayViewController showWithContentViewController:self.chatInputViewController contentView:nil];
    [self.chatInputViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.overlayViewController.view);
    }];
}

- (void)updatePPTUserInteractionEnable {
    self.room.slideshowViewController.view.userInteractionEnabled = (self.majorWindowType == BJLScWindowType_ppt);
}

#pragma mark - button state

- (void)updateButtonStates {
    if (self.is1V1Class) {
        [self update1V1ButtonStates];
        return;
    }
    self.videoButton.hidden = (self.room.loginUser.isStudent && (!self.room.speakingRequestVM.speakingEnabled || self.room.featureConfig.hideStudentCamera)) || self.controlsHidden || self.room.loginUser.isAudition;
    self.audioButton.hidden = (self.room.loginUser.isStudent && !self.room.speakingRequestVM.speakingEnabled) || self.controlsHidden || self.room.loginUser.isAudition;
    
    self.videoButton.selected = (self.room.loginUser.isTeacherOrAssistant || (self.room.loginUser.isStudent && self.room.speakingRequestVM.speakingEnabled)) && self.room.recordingVM.recordingVideo;
    self.audioButton.selected = (self.room.loginUser.isTeacherOrAssistant || (self.room.loginUser.isStudent && self.room.speakingRequestVM.speakingEnabled)) && self.room.recordingVM.recordingAudio;
    // 学生显示，老师或者助教在举手列表人数大于 0 时显示
    self.handUpButton.hidden = !(self.room.loginUser.isStudent || (self.room.loginUser.isTeacherOrAssistant && [self.room.speakingRequestVM.speakingRequestUsers count] > 0)) || self.controlsHidden || self.room.loginUser.isAudition;
    self.changeScreenButton.hidden = self.controlsHidden;

    if (self.room.loginUser.isStudent) {
        self.handUpButton.selected = self.room.speakingRequestVM.speakingEnabled;
    }
    
    NSString *liveTabs = self.room.loginUser.isStudent ? self.room.featureConfig.liveTabsOfStudent : self.room.featureConfig.liveTabs;
    BOOL enableQuestion = [liveTabs containsString:@"answer"] && self.room.featureConfig.enableQuestion;
    self.noticeButton.hidden = self.controlsHidden;
    self.questionButton.hidden = self.controlsHidden || !enableQuestion;
    BOOL questionRedDotHidden = self.controlsHidden || !enableQuestion || self.questionRedDotHidden;
    self.questionRedDot.hidden = questionRedDotHidden;
}

- (void)update1V1ButtonStates {
    self.videoButton.hidden = self.controlsHidden || self.room.loginUser.isAudition;
    self.audioButton.hidden = self.controlsHidden || self.room.loginUser.isAudition;
    
    self.videoButton.selected = self.room.recordingVM.recordingVideo;
    self.audioButton.selected = self.room.recordingVM.recordingAudio;
}

#pragma mark - replaceContentView

- (void)replaceMajorContentViewWithPPTView {
    [self.room.slideshowViewController bjl_removeFromParentViewControllerAndSuperiew];
    [self bjl_addChildViewController:self.room.slideshowViewController superview:self.majorContentView];
    [self.room.slideshowViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.majorContentView);
    }];
    if (self.teacherExtraMediaInfoView) {
        // 存在老师辅助摄像头时，盖住白板
        [self.teacherExtraMediaInfoView removeFromSuperview];
        [self.majorContentView addSubview:self.teacherExtraMediaInfoView];
        [self.teacherExtraMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.majorContentView);
        }];
    }
    self.majorWindowType = BJLScWindowType_ppt;
}

- (void)replaceMinorContentViewWithPPTView {
    [self.room.slideshowViewController bjl_removeFromParentViewControllerAndSuperiew];
    [self bjl_addChildViewController:self.room.slideshowViewController superview:self.minorContentView];
    [self.room.slideshowViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.minorContentView);
    }];
    if (self.teacherExtraMediaInfoView) {
        // 存在老师辅助摄像头时，盖住白板
        [self.teacherExtraMediaInfoView removeFromSuperview];
        [self.minorContentView addSubview:self.teacherExtraMediaInfoView];
        [self.teacherExtraMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.minorContentView);
        }];
    }
    self.minorWindowType = BJLScWindowType_ppt;
}

- (void)replaceMajorContentViewWithTeacherMediaInfoView {
    [self.teacherMediaInfoView removeFromSuperview];
    [self.majorContentView addSubview:self.teacherMediaInfoView];
    [self.teacherMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.majorContentView);
    }];
    self.majorWindowType = BJLScWindowType_teacherVideo;
}

- (void)replaceMinorContentViewWithTeacherMediaInfoView {
    [self.teacherMediaInfoView removeFromSuperview];
    [self.minorContentView addSubview:self.teacherMediaInfoView];
    [self.teacherMediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.minorContentView);
    }];
    self.minorWindowType = BJLScWindowType_teacherVideo;
}

- (void)replaceMajorContentViewWithUserMediaInfoView:(BJLScMediaInfoView *)mediaInfoView {
    [mediaInfoView removeFromSuperview];
    [self.majorContentView addSubview:mediaInfoView];
    [mediaInfoView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.majorContentView);
    }];
    self.majorWindowType = BJLScWindowType_userVideo;
}
#pragma mark - menu

- (void)showMenuForTeacherVideo {
    bjl_weakify(self);
    
    UIAlertController *alert = [UIAlertController
                                 bjl_lightAlertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];

//    [alert bjl_addActionWithTitle:@"全屏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        bjl_strongify(self);
//        if (self.majorWindowType == BJLScWindowType_userVideo) {
//            // 大屏是用户视频时，先把用户视频放回视频列表
//            [self.videosViewController resetVideo];
//        }
//        [self replaceMinorContentViewWithPPTView];
//        [self replaceMajorContentViewWithTeacherMediaInfoView];
//
//        if (self.room.loginUser.isTeacher && self.room.featureConfig.shouldSyncPPTVideoSwitch)  {
//            [self.room.roomVM exchangeVideoPositonWithPPT:YES];
//        }
//    }];
    
    if (self.room.loginUser.isTeacher) {
        if (!self.room.loginUserIsPresenter
            && self.room.featureConfig.canChangePresenter) {
            [alert bjl_addActionWithTitle:@"设为主讲"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                                        bjl_strongify(self);
                                        BJLError *error = [self.room.onlineUsersVM requestChangePresenterWithUserID:self.room.loginUser.ID];
                                        if (error) {
                                            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                        }
                                  }];
        }
        
        [alert bjl_addActionWithTitle:@"切换摄像头"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
                                    bjl_strongify(self);
                                  if (!self.room.recordingVM.recordingVideo) {
                                      return;
                                  }
                                  BJLError *error = [self.room.recordingVM updateUsingRearCamera:!self.room.recordingVM.usingRearCamera];
                                  if (error) {
                                      [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                  }
                              }];
        
        [alert bjl_addActionWithTitle:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                       ? @"开启美颜" : @"关闭美颜")
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * _Nonnull action) {
                                    bjl_strongify(self);
                                  if (!self.room.recordingVM.recordingVideo) {
                                      return;
                                  }
                                  BJLError *error = [self.room.recordingVM updateVideoBeautifyLevel:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                                                                                     ? BJLVideoBeautifyLevel_on : BJLVideoBeautifyLevel_off)];
                                  if (error) {
                                      [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                  }
                              }];
        
        [alert bjl_addActionWithTitle:self.room.recordingVM.recordingVideo ? @"关闭摄像头" : @"打开摄像头"
                                style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * _Nonnull action) {
                                    bjl_strongify(self);
                                  BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                                              recordingVideo:!self.room.recordingVM.recordingVideo];
                                  if (error) {
                                      [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                  }
                                  else {
                                      [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                                                     ? @"摄像头已打开"
                                                                     : @"摄像头已关闭")];
                                  }
                              }];
    }
    else {
        BJLMediaUser *mediaUser = self.teacherMediaInfoView.mediaUser;
        if (mediaUser.videoOn) {
//            BOOL playingVideo = [self isVideoPlayingUser:mediaUser];
//            [alert bjl_addActionWithTitle:playingVideo ? @"关闭视频" : @"开启视频"
//                                    style:UIAlertActionStyleDefault
//                                  handler:^(UIAlertAction * _Nonnull action) {
//                                      bjl_strongify(self);
//                                      BJLError *error = [self.room.playingVM updatePlayingUserWithID:mediaUser.ID videoOn:!playingVideo mediaSource:mediaUser.mediaSource];
//                                      if (error) {
//                                          [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
//                                      }
//                                      else {
//                                          // 主动关闭老师视频后不再自动打开
//                                          [self.teacherMediaInfoView updateCloseVideoPlaceholderHidden:!playingVideo];
//                                          [self updateAutoPlayVideoBlacklist:mediaUser add:playingVideo];
//                                      }
//                                  }];
                BOOL playingVideo = [self isVideoPlayingUser:mediaUser];

                BJLError *error = [self.room.playingVM updatePlayingUserWithID:mediaUser.ID videoOn:!playingVideo mediaSource:mediaUser.mediaSource];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                else {
                    // 打开或者关闭老师摄像头后不再自动打开
                    [self.teacherMediaInfoView updateCloseVideoPlaceholderHidden:!playingVideo];
                    [self updateAutoPlayVideoBlacklist:mediaUser add:playingVideo];
                    [self showProgressHUDWithText:playingVideo ? @"已关闭视频" : @"已开启视频"];
                }
        }else{
            [self showProgressHUDWithText:@"老师已关闭摄像头"];
        }
    }
    
//    [alert bjl_addActionWithTitle:@"取消"
//                            style:UIAlertActionStyleCancel
//                          handler:nil];
//
//    if (alert.preferredStyle == UIAlertControllerStyleActionSheet) {
//        UIView *sourceView = self.minorContentView;
//        alert.popoverPresentationController.sourceView = sourceView;
//        alert.popoverPresentationController.sourceRect = ({
//            CGRect rect = sourceView.bounds;
//            rect.origin.y = CGRectGetMaxY(rect) - 1.0;
//            rect.size.height = 1.0;
//            rect;
//        });
//        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
//    }
//    if (self.presentedViewController) {
//        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
//    }
//    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showMenuForStudentVideo {
    UIAlertController *alert = [UIAlertController
                                 bjl_lightAlertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    bjl_weakify(self);
    if ([self.room.loginUser isSameUser:self.secondMinorMediaInfoView.user]) {
           [alert bjl_addActionWithTitle:@"切换摄像头"
                                   style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * _Nonnull action) {
                                       bjl_strongify(self);
                                     if (!self.room.recordingVM.recordingVideo) {
                                         return;
                                     }
                                     BJLError *error = [self.room.recordingVM updateUsingRearCamera:!self.room.recordingVM.usingRearCamera];
                                     if (error) {
                                         [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                     }
                                 }];
           
           [alert bjl_addActionWithTitle:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                          ? @"开启美颜" : @"关闭美颜")
                                   style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * _Nonnull action) {
                                       bjl_strongify(self);
                                     if (!self.room.recordingVM.recordingVideo) {
                                         return;
                                     }
                                     BJLError *error = [self.room.recordingVM updateVideoBeautifyLevel:(self.room.recordingVM.videoBeautifyLevel == BJLVideoBeautifyLevel_off
                                                                                                        ? BJLVideoBeautifyLevel_on : BJLVideoBeautifyLevel_off)];
                                     if (error) {
                                         [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                     }
                                 }];
           
           [alert bjl_addActionWithTitle:self.room.recordingVM.recordingVideo ? @"关闭摄像头" : @"打开摄像头"
                                   style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * _Nonnull action) {
                                       bjl_strongify(self);
                                     BJLError *error = [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                                                                 recordingVideo:!self.room.recordingVM.recordingVideo];
                                     if (error) {
                                         [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                     }
                                     else {
                                         [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                                                        ? @"摄像头已打开"
                                                                        : @"摄像头已关闭")];
                                     }
                                 }];
       }
       else {
           BJLMediaUser *mediaUser = self.secondMinorMediaInfoView.mediaUser;
           if (mediaUser.videoOn) {
               BOOL playingVideo = [self isVideoPlayingUser:mediaUser];
               [alert bjl_addActionWithTitle:playingVideo ? @"关闭视频" : @"开启视频"
                                       style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * _Nonnull action) {
                                         bjl_strongify(self);
                                         BJLError *error = [self.room.playingVM updatePlayingUserWithID:mediaUser.ID videoOn:!playingVideo mediaSource:mediaUser.mediaSource];
                                         if (error) {
                                             [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                         }
                                         else {
                                             // 主动关闭视频后不再自动打开
                                             [self.secondMinorMediaInfoView updateCloseVideoPlaceholderHidden:!playingVideo];
                                             [self updateAutoPlayVideoBlacklist:mediaUser add:playingVideo];
                                         }
                                     }];
           }
           if (self.room.loginUser.isTeacherOrAssistant
               && self.room.loginUser.noGroup
               && mediaUser.isStudent) {
               [alert bjl_addActionWithTitle:@"奖励"
                                       style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * _Nonnull action) {
                                       bjl_strongify(self);
                                         BJLError *error = [self.room.roomVM sendLikeForUserNumber:mediaUser.number];
                                         if (error) {
                                             [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                                         }
                                     }];
           }
       }
       
       [alert bjl_addActionWithTitle:@"取消"
                               style:UIAlertActionStyleCancel
                             handler:nil];

       if (alert.preferredStyle == UIAlertControllerStyleActionSheet) {
           UIView *sourceView = self.minorContentView;
           alert.popoverPresentationController.sourceView = sourceView;
           alert.popoverPresentationController.sourceRect = ({
               CGRect rect = sourceView.bounds;
               rect.origin.y = CGRectGetMaxY(rect) - 1.0;
               rect.size.height = 1.0;
               rect;
           });
           alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
       }
       if (self.presentedViewController) {
           [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
       }
       [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateAutoPlayVideoBlacklist:(BJLMediaUser *)user add:(BOOL)add {
    if (add) {
        [self.autoPlayVideoBlacklist addObject:[self videoKeyForUser:user]];
    }
    else {
        [self.autoPlayVideoBlacklist removeObject:[self videoKeyForUser:user]];
    }
}

- (BOOL)isVideoPlayingUser:(BJLMediaUser *)mediaUser {
    for (BJLMediaUser *user in [self.room.playingVM.videoPlayingUsers copy]) {
        if ([user isSameMediaUser:mediaUser]) {
            return YES;
        }
    }
    return NO;
}

@end
