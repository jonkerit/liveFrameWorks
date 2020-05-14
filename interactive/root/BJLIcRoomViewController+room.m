//
//  BJLIcRoomViewController+room.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//
#import <BJLiveBase/BJLWebImage.h>

#import "BJLIcRoomViewController+room.h"
#import "BJLIcRoomViewController+private.h"
#import "BJLIcRoomViewController+actions.h"
#import "BJLIcAppearance.h"
#import "BJLIcLiveStartView.h"
#import "BJLIcPopoverViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcRoomViewController (room)

#pragma mark - room observers

- (void)makeRoomObservingBeforeEnterRoom {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomSuccess)
             observer:^BOOL{
                 bjl_strongify(self);
                 [self setupReachabilityManager];
                 [self classViewControllerEnterRoomSuccess:self];
                 [self.promptViewController enqueueWithPrompt:@"进入教室成功"];
                 
#if ! defined(__LP64__) || ! __LP64__ // #see CGFloat
                 [self.promptViewController enqueueWithPrompt:@"您的设备性能不足，可能无法正常上课，建议更换高性能设备以获得更好的体验"
                                                     duration:[BJLIcAppearance sharedAppearance].promptDuration
                                                    important:YES];
#endif
                 
                 // 进入教室成功才设置 block
                 [self.room setReloadingBlock:^(BJLLoadingVM * _Nonnull reloadingVM, void (^ _Nonnull callback)(BOOL)) {
                     bjl_strongify(self);
                     self.hasReload = YES;
                     [self.promptViewController enqueueWithPrompt:@"网络中断！正在尝试重新连接..." duration:0 important:YES];
                     [self makeObservingForLoadingVM:reloadingVM];
                     
//                     网络断开时，直接关闭计时器， 抢答器
                     [self.blackboardLayoutViewController destoryCountDownAndResponder];
                     callback(YES);
                 }];
                 
                 // VMs 配置项
                 self.room.drawingVM.showBrushOwnerNameWhenSelected = YES;
                 
                 [self makeObservingForLossRate];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, enterRoomFailureWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self classViewController:self enterRoomFailureWithError:error];
                 [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"进入教室失败:%td-%@", error.code, error.localizedDescription ?: error.localizedFailureReason]];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, roomWillExitWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self stopLossRateObservingTimer];

                 if (self.room.loginUser.isTeacher
                     && error.code != BJLErrorCode_exitRoom_loginConflict) {
                     if (self.room.serverRecordingVM.serverRecording) {
                         [self.room.serverRecordingVM requestServerRecording:NO]; // 退出教室停止录课
                     }
                     if (self.room.roomVM.liveStarted) {
                         [self.room.roomVM sendLiveStarted:NO]; // 退出教室下课
                         NSError *error = [self.room.chatVM sendForbidAll:NO];   // 解除禁言
                         if (error) {
                             [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
                         }
                         
                         [self.blackboardLayoutViewController closeWritingBoardWithGatherRequest]; //收回作答中的小黑板
                     }
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room, roomDidExitWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self clean];
                 [self roomDidExitWithError:error];
                 return YES;
             }];
}

- (void)makeRoomObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
           filter:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return !!now;
           }
         observer:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self makeObserving];
             return NO;
         }];
    
    [self makeDocumentDisplayObserving];
}

- (void)makeObservingForLoadingVM:(BJLLoadingVM *)loadingVM {
    self.recordingAudioBeforeReload = self.room.recordingVM.recordingAudio;
    self.recordingVideoBeforeReload = self.room.recordingVM.recordingVideo;
    bjl_weakify(self);
    loadingVM.suspendBlock = ^(BJLLoadingStep step,
                               BJLLoadingSuspendReason reason,
                               BJLError *error,
                               void (^continueCallback)(BOOL isContinue)) {
        bjl_strongify(self);
        // 成功
        if (reason != BJLLoadingSuspendReason_errorOccurred) {
            continueCallback(YES);
            return;
        }

        NSInteger progress = 1;
        switch (step) {
            case BJLLoadingStep_checkNetwork:
                progress = 1;
                break;
                
            case BJLLoadingStep_loadRoomInfo:
                progress = 2;
                break;
                
            case BJLLoadingStep_connectRoomServer:
                progress = 3;
                break;
            
            case BJLLoadingStep_connectMasterServer:
                progress = 4;
                break;
                
            default:
                break;
        }
        
        if (error.code == BJLErrorCode_enterRoom_timeExpire) {
            BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcExitViewTimeOut message:[NSString stringWithFormat:@"教室已过期"]];
            [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
            [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.popoversLayer);
            }];
            bjl_weakify(self);
            [popoverViewController setConfirmCallback:^{
                bjl_strongify(self);
                continueCallback(NO);
                [self exit];
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }
        else {
            BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcExitViewConnectFail message:[NSString stringWithFormat:@"网络连接失败（进度%ld/4），您可以退出或继续连接", (long)progress]];
            [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
            [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.popoversLayer);
            }];
            bjl_weakify(self);
            [popoverViewController setCancelCallback:^{
                bjl_strongify(self);
                continueCallback(NO);
                [self exit];
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [popoverViewController setConfirmCallback:^{
                continueCallback(YES);
            }];
        }
    };
    
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingSuccess)
             observer:^BOOL() {
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"重新连接成功"];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(loadingVM, loadingFailureWithError:)
             observer:^BOOL(BJLError *error) {
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"连接失败"];
                 return YES;
             }];
}

- (void)makeObserving {
     bjl_weakify(self);
    
    /* 录课 */
    
    if (self.room.loginUser.isTeacherOrAssistant) {
        __block BOOL isInitial = YES;
        [self bjl_observe:BJLMakeMethod(self.room.serverRecordingVM, didReceiveServerRecording:fromUser:)
                 observer:(BJLMethodObserver)^BOOL(BOOL serverRecording, BJLUser *fromUser) {
            bjl_strongify(self);
            NSString *message = nil;
            switch (self.room.loginUser.role) {
                case BJLUserRole_teacher:
                    switch (fromUser.role) {
                        case BJLUserRole_teacher:
                            message = serverRecording ? @"已开启云端录制" : @"已关闭云端录制";
                            break;
                            
                        case BJLUserRole_assistant:
                            message = serverRecording ? @"助教已开启云端录制" : @"助教已关闭云端录制";
                            break;
                            
                        default:
                            break;
                    }
                    break;
                    
                case BJLUserRole_assistant:
                    switch (fromUser.role) {
                        case BJLUserRole_teacher:
                            message = serverRecording ? @"老师已开启云端录制" : @"老师已关闭云端录制";
                            break;
                            
                        case BJLUserRole_assistant:
                            message = serverRecording ? @"已开启云端录制" : @"已关闭云端录制";
                            break;
                            
                        default:
                            break;
                    }
                    break;
                    
                default:
                    break;
            }
            if (message.length && (!isInitial || serverRecording)) {
                [self.promptViewController enqueueWithPrompt:message];
            }
            isInitial = NO;
            return YES;
        }];
        [self bjl_observe:BJLMakeMethod(self.room.serverRecordingVM, requestServerRecordingDidFailed:)
                 observer:^BOOL(NSString *message) {
                     bjl_strongify(self);
                     [self.promptViewController enqueueWithPrompt:message];
                     self.toolbarViewController.cloudRecordingButton.selected = NO;
                     return YES;
                 }];
        
        [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyToUserID:allowed:success:)
                   filter:(BJLMethodObserver)^BOOL(NSString *userID, BOOL allowed, BOOL success) {
                       // bjl_strongify(self);
                       return allowed && !success;
                   }
                 observer:(BJLMethodObserver)^BOOL(NSString *userID, BOOL allowed, BOOL success) {
                     bjl_strongify(self);
                     [self.promptViewController enqueueWithPrompt:@"坐席已满，请设置下台后继续操作"];
                     return YES;
                 }];
    }
    
    /* 上课 */
    
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             for (UIView *view in self.popoversLayer.subviews) {
                 if ([view isKindOfClass:[BJLIcLiveStartView class]]) {
                     [view removeFromSuperview];
                 }
             }
            if (!self.room.roomVM.liveStarted && (self.room.loginUser.isTeacher || (self.room.loginUser.isAssistant && self.room.featureConfig.enableAssistantStartClass))) {
                 BJLIcLiveStartView *liveStartView = [[BJLIcLiveStartView alloc] init];
                 [self.popoversLayer addSubview:liveStartView];
                 [self.popoversLayer sendSubviewToBack:liveStartView];
                 [liveStartView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                     if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
                         make.center.equalTo(self.layoutLayer);
                     }
                     else {
                         make.center.equalTo(self.widgetLayer);
                     }
                     make.height.equalTo(@([BJLIcAppearance sharedAppearance].liveStartButtonHeight));
                     make.width.equalTo(@([BJLIcAppearance sharedAppearance].liveStartButtonWidth));
                 }];
                 bjl_weakify(self);
                 [liveStartView setLiveStartCallback:^BOOL{
                     bjl_strongify(self);
                     BJLError *error = [self.room.roomVM sendLiveStarted:YES];
                     if (error) {
                         [self.promptViewController enqueueWithPrompt:error.localizedFailureReason ?: error.localizedDescription];
                     }
                     return !error;
                 }];
             }
             if ([old boolValue] != [now boolValue]) {
                 [self.promptViewController enqueueWithPrompt:now.boolValue ? @"上课啦" : @"下课啦"];
             }
             return YES;
         }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.roomVM, liveStarted),
                         BJLMakeProperty(self.room.mediaVM, inLiveChannel)]
              observer:^(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  if (self.room.roomVM.liveStarted && self.room.mediaVM.inLiveChannel) {
                      BOOL isActive = NO;
                      for (BJLUser *playingUser in self.room.playingVM.playingUsers) {
                          if ([playingUser.ID isEqualToString:self.room.loginUser.ID]) {
                              isActive = YES;
                          }
                      }
                      // 上课并且加入了直播频道之后，如果在自己在上台用户中，开启音视频
                      if (isActive ) {
                          if (self.hasReload) {
                              // 重连的情况下读取断线前的状态
                              [self updateRecordingAudio:self.recordingAudioBeforeReload recordingVideo:self.recordingVideoBeforeReload];
                          }
                          else {
                              // 老师无条件开启音视频，1v1模板台上用户无条件开启音视频, 配置了默认打开音频的学生开启音频
                              BOOL recordingAudio = self.room.loginUser.isTeacher
                              || BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType
                              || (self.room.loginUser.isStudent && self.room.featureConfig.shouleStudentOpenAudioDefault);
                              [self updateRecordingAudio:recordingAudio recordingVideo:YES];
                          }
                      }
                  }
              }];
    
    /* 视频播放 */
    
    self.room.playingVM.autoPlayVideoBlock = ^BJLAutoPlayVideo(BJLMediaUser *user, NSInteger cachedDefinitionIndex) {
        bjl_strongify(self);
        BOOL autoPlay = user.number && ![self.autoPlayVideoBlacklist containsObject:user.number];
        NSInteger definitionIndex = cachedDefinitionIndex;
        if (autoPlay) {
            NSInteger maxDefinitionIndex = MAX(0, (NSInteger)user.definitions.count - 1);
            definitionIndex = (cachedDefinitionIndex <= maxDefinitionIndex
                               ? cachedDefinitionIndex : maxDefinitionIndex);
        }
        return BJLAutoPlayVideoMake(autoPlay, definitionIndex);
    };
    
    /* 麦克风和摄像头权限 */
    __block UIAlertController *alertController = nil;
    [self.room.recordingVM setCheckMicrophoneAndCameraAccessCallback:^(BOOL microphone, BOOL camera, BOOL granted, UIAlertController * _Nullable alert) {
        bjl_strongify(self);
        if (granted) {
            return;
        }
        // 未授权时重置当前的 UI 状态
        if (microphone) {
            self.toolbarViewController.microphoneButton.selected = NO;
        }
        if (camera) {
            self.toolbarViewController.cameraButton.selected = NO;
        }
        if (alert) {
            if (self.presentedViewController) {
                if (self.presentedViewController == alertController && alert != alertController) {
                    [self.room.recordingVM setCheckMicrophoneAndCameraAccessActionCompletion:^{
                        bjl_strongify(self);
                        self.room.recordingVM.checkMicrophoneAndCameraAccessActionCompletion = nil;
                        alertController = alert;
                        [self presentViewController:alert animated:YES completion:nil];
                    }];
                }
                else {
                    alertController = alert;
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }
            else {
                alertController = alert;
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }];
    
    /* 通用监听 */
    
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, recordingDidRemoteChangedRecordingAudio:recordingVideo:recordingAudioChanged:recordingVideoChanged:)
             observer:(BJLMethodObserver)^BOOL(BOOL recordingAudio, BOOL recordingVideo, BOOL recordingAudioChanged, BOOL recordingVideoChanged) {
                 bjl_strongify(self);
                 NSString *message = @"";
                 if (recordingAudioChanged) {
                     message = recordingAudio ? @"老师开启了你的麦克风" : @"老师关闭了你的麦克风";
                 }
                 else if (recordingVideoChanged) {
                     message = recordingVideo ? @"老师开启了你的摄像头" : @"老师关闭了你的摄像头";
                 }
                 [self.promptViewController enqueueWithPrompt:message];
                 return YES;
             }];
    [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidAll)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self.promptViewController enqueueWithPrompt:now.boolValue ? @"老师禁止聊天" : @"老师允许聊天"];
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidMe)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self.promptViewController enqueueWithPrompt:now.boolValue ? @"你已被禁言":@"你已被解除禁言"];
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, forbidSpeakingRequest)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self.promptViewController enqueueWithPrompt:now.boolValue?@"老师禁止举手":@"老师允许举手"];
             return YES;
         }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUpdateWebPageWithURLString:open:isCache:)
             observer:(BJLMethodObserver)^BOOL(NSString *urlString, BOOL open, BOOL isCache) {
                 bjl_strongify(self);
                 if (!open && !isCache) {
                     [self.promptViewController enqueueWithPrompt:@"网页已被收回"];
                 }
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, didUpadateAllRecordingAudioMute:)
             observer:(BJLMethodObserver)^BOOL(BOOL mute) {
                 bjl_strongify(self);
                 if (mute) {
                     [self.promptViewController enqueueWithPrompt:@"老师已关闭全体学生的麦克风"];
                 }
                 else {
                     [self.promptViewController enqueueWithPrompt:@"老师已开启全体学生的麦克风"];
                 }
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, didBlockUser:)
             observer:^BOOL(BJLUser *blockedUser) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isTeacherOrAssistant) {
                     [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"%@ 已被移出", blockedUser.displayName]];
                 }
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
             observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
                 bjl_strongify(self);
                 if ([user.ID isEqualToString:self.room.loginUser.ID] && !isUserCancelled) {
                     if (speakingEnabled) {
                         // 举手同意时，如果上台了，就打开音频，如果没上台，就打开音频和视频
                         if ([self.room.playingVM playingUserWithID:self.room.loginUser.ID
                                                             number:self.room.loginUser.number
                                                        mediaSource:BJLMediaSource_mainCamera]) {
                             [self updateRecordingAudio:YES];
                         }
                         else {
                             [self updateRecordingAudio:YES recordingVideo:YES];
                         }
                         [self.promptViewController enqueueWithPrompt:@"老师同意发言，已进入发言状态"];
                     }
                     else {
                         [self updateRecordingAudio:NO];
                         [self.promptViewController enqueueWithPrompt:@"稍等一下，一会请你回答"];
                     }
                 }
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUpdateRoomLayout:)
             observer:(BJLMethodObserver)^BOOL(BJLRoomLayout roomLayout) {
                 bjl_strongify(self);
                 if (roomLayout == BJLRoomLayout_gallary) {
                     // !!!: 交互已改，切换到画廊布局不收回窗口
                     [self switchToGalleryLayout];
                 }
                 else if (roomLayout == BJLRoomLayout_blackboard) {
                     [self switchToBlackboardLayout];
                 }
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didAddActiveUser:)
               filter:^BOOL(BJLUser *user) {
                   bjl_strongify(self);
                   return ![user.ID isEqualToString:self.room.loginUser.ID];
               }
             observer:^BOOL(BJLUser *user) {
                 bjl_strongify(self);
                 if (self.room.featureConfig.maxBackupUserCount > 0) {
                     [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"%@ 已上台", user.displayName]];
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didRemoveActiveUser:)
               filter:^BOOL(BJLUser *user) {
                   bjl_strongify(self);
                   return ![user.ID isEqualToString:self.room.loginUser.ID];
               }
             observer:^BOOL(BJLUser *user) {
                 bjl_strongify(self);
                 if (self.room.featureConfig.maxBackupUserCount > 0) {
                     [self.promptViewController enqueueWithPrompt:[NSString stringWithFormat:@"%@ 已下台", user.displayName]];
                 }
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didAddActiveUserDeny:responseCode:)
             observer:^BOOL(BJLUser *user, NSInteger responseCode) {
                 bjl_strongify(self);
                 NSString *message = (responseCode == 2) ? @"该学生已离开教室" : @"上台人数已满";
                 [self.promptViewController enqueueWithPrompt:message];
                 return YES;
             }];
    // 上麦失败的提示
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, recordingDidDeny)
             observer:^BOOL {
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"服务器拒绝发布音视频，音视频并发已达上限"];
                 return YES;
             }];
    
    // webRTC 进入直播频道失败
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, enterLiveChannelFailed)
             observer:^BOOL{
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"进入直播频道失败，请重试" duration:[BJLIcAppearance sharedAppearance].promptDuration important:YES];
                 return YES;
             }];
    
    // webRTC 直播频道断开提示
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, didLiveChannelDisconnectWithError:)
             observer:^BOOL(NSError *error){
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"直播频道已断开，请重试" duration:[BJLIcAppearance sharedAppearance].promptDuration important:YES];
                 return YES;
             }];
    
    // webRTC 推流重试提示
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, republishing)
             observer:^BOOL {
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"音视频推送失败，自动重试中" duration:[BJLIcAppearance sharedAppearance].promptDuration important:YES];
                 return YES;
             }];
    
    // webRTC 推流重试提示
    [self bjl_observe:BJLMakeMethod(self.room.recordingVM, publishFailed)
             observer:^BOOL {
                 bjl_strongify(self);
                 [self.promptViewController enqueueWithPrompt:@"音视频推送失败，请重试" duration:[BJLIcAppearance sharedAppearance].promptDuration important:YES];
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveAttentionWarning:)
             observer:^BOOL(NSString *content) {
        bjl_strongify(self);
        [self.promptViewController enqueueWithPrompt:content];
        return YES;
    }];
    
    /** 助教 */
    if (self.room.loginUser.isAssistant) {
                [self bjl_observe:BJLMakeMethod(self.room.playingVM, didAddActiveUser:)
                   filter:^BOOL(BJLUser *user) {
                       bjl_strongify(self);
                       return [user.ID isEqualToString:self.room.loginUser.ID];
                   }
                 observer:^BOOL(BJLUser *user) {
                     // 上台后开启视频
                     bjl_strongify(self);
                     if (self.room.roomVM.liveStarted && self.room.mediaVM.inLiveChannel) {
                         if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                             [self updateRecordingVideo:NO];
                         }
                         else {
                             [self updateRecordingVideo:YES];
                         }
                     }
                     return YES;
                 }];
    }
    
    /* 学生 */
    
    if (!self.room.loginUser.isTeacherOrAssistant) {
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room.drawingVM, drawingGranted),
                             BJLMakeProperty(self.room.drawingVM, writingBoardEnabled),
                             BJLMakeProperty(self.room.documentVM, authorizedPPT)]
                  observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                      bjl_strongify(self);
                      BOOL enable = self.room.drawingVM.drawingGranted || self.room.drawingVM.writingBoardEnabled || self.room.documentVM.authorizedPPT;
                      [self.toolbarViewController remakeToolbarConstraintsForStudentWithDrawingGranted:enable];
                      if (!enable) {
                          // 取消授权时清理选中状态，重新布局
                          [self.toolboxViewController cancelCurrentSelectedButton];
                      }
                      // !!!: 被授权的时候任意文档窗口都不能是全屏
                      [self.toolboxViewController remakeToolboxConstraintsWithLayoutType:BJLIcToolboxLayoutNormal];
                  }];
        [self bjl_observe:BJLMakeMethod(self.room.playingVM, didAddActiveUser:)
                   filter:^BOOL(BJLUser *user) {
                       bjl_strongify(self);
                       return [user.ID isEqualToString:self.room.loginUser.ID];
                   }
                 observer:^BOOL(BJLUser *user) {
                     // 上台后开启视频
                     bjl_strongify(self);
                     if (self.room.roomVM.liveStarted && self.room.mediaVM.inLiveChannel) {
                         // 1v1 台上学生无条件开启音视频, 配置了默认打开音频的学生打开音频
                         BOOL recordingAudio = (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) || (self.room.loginUser.isStudent && self.room.featureConfig.shouleStudentOpenAudioDefault);
                         if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                             [self updateRecordingAudio:recordingAudio recordingVideo:NO];
                         }
                         else {
                             [self updateRecordingAudio:recordingAudio recordingVideo:YES];
                         }
                     }
                     return YES;
                 }];
    }
    
    // 助教和学生下台需要关闭音视频
    if (!self.room.loginUser.isTeacher) {
        [self bjl_observe:BJLMakeMethod(self.room.playingVM, didRemoveActiveUser:)
                   filter:^BOOL(BJLUser *user) {
                       bjl_strongify(self);
                       return [user.ID isEqualToString:self.room.loginUser.ID];
                   }
                 observer:^BOOL(BJLUser *user) {
                     bjl_strongify(self);
                     [self updateRecordingAudio:NO recordingVideo:NO];
                     return YES;
                 }];
    }
    
    [self bjl_kvo:BJLMakeProperty(self.room, featureConfig)
           filter:^BOOL(NSString *_Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
               return  !!value;
           }
         observer:^BOOL(id _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if(self.room.featureConfig.backgroundURLString.length) {
                 [self.backgroundImageView bjl_setImageWithURL:[NSURL URLWithString:self.room.featureConfig.backgroundURLString] placeholder:nil completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                     bjl_strongify(self);
                     if(image) {
                         self.layoutLayer.backgroundColor = [UIColor clearColor];
                     }
                     else {
                         self.layoutLayer.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
                     }
                 }];
             }
             return YES;
    }];
    
//    全屏下的举手按钮
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingRequestFromUser:)
             observer:^BOOL(BJLUser *user) {
                 bjl_strongify(self);
                 // 收到举手提示
                 [self.promptViewController enqueueWithSpecialPrompt:@"教室内有学生举手" duration:[BJLIcAppearance sharedAppearance].promptDuration important:NO];
                 return YES;
             }];
    [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, recordingAudio)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.requestSpeakinFullScreenButton.enabled = !now.boolValue;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestTimeRemaining)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return timeRemaining.doubleValue != old.doubleValue;
           }
         observer:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (timeRemaining.doubleValue <= 0.0) {
                 self.speakRequestProgressView.progress = 0.0;
                 self.requestSpeakinFullScreenButton.selected = NO;
             }
             else {
                 CGFloat progress = timeRemaining.doubleValue / self.room.speakingRequestVM.speakingRequestTimeoutInterval; // 1.0 ~ 0.0
                 self.speakRequestProgressView.progress = progress;
             }
             return YES;
         }];
    
    if (self.room.loginUser.isStudent) {
        [self makeObservingForLamp];
        [self makeObservingForEvaluation];
    }
}

- (void)makeDocumentDisplayObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.blackboardLayoutViewController, documentWindowDisplayInfos)
         observer:^BOOL(NSArray<BJLWindowDisplayInfo *> * _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             // 第二套模板不需要处理文档窗口导致的布局变动
             if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
                 return NO;
             }
             // 没有画笔权限的用户不需要处理
             if (self.room.loginUser.isStudent && !self.room.drawingVM.drawingGranted) {
                 return YES;
             }
             // 如果存在最大化或者全屏的窗口，更新布局，显示侧边文件管理视图
             BOOL isExistMaximized = NO;
             BOOL isExistFullScreen = NO;
             BJLWindowDisplayInfo *mainMaximizedDisplayInfo = nil;
             BJLWindowDisplayInfo *mainFullScreenDisplayInfo = nil;
             NSMutableArray<BJLIcDocumentFile *> *documentFileList = [NSMutableArray new];
             if (now.count) {
                 // 数组逆序遍历的第一个全屏或者最大化的窗口是当前窗口
                 for (BJLWindowDisplayInfo *windowDisplayInfo in [now reverseObjectEnumerator]) {
                     // 存在全屏
                     if (windowDisplayInfo.isFullScreen && !mainMaximizedDisplayInfo) {
                         isExistFullScreen = YES;
                         mainFullScreenDisplayInfo = windowDisplayInfo;
                     }
                     // 存在最大化
                     if (windowDisplayInfo.isMaximized && !mainFullScreenDisplayInfo) {
                         isExistMaximized = YES;
                         mainMaximizedDisplayInfo = windowDisplayInfo;
                     }
                     // 转换文档数据
                     BJLDocument *document = [self.room.documentVM documentWithID:windowDisplayInfo.ID];
                     BJLIcDocumentFile *documentFile = [[BJLIcDocumentFile alloc] initWithRemoteDocument:document];
                     [documentFileList bjl_addObject:documentFile];
                 }
             }
             
             // 当前存在全屏窗口，但是 toolbox 不是全屏的布局，全屏窗口屏蔽最大化窗口，侧边栏的状态和 toolbox 一一对应，不另加判断
             if (isExistFullScreen && self.toolboxViewController.type != BJLIcToolboxLayoutFullScreen) {
                 // 移动层级
                 [self.toolboxViewController bjl_removeFromParentViewControllerAndSuperiew];
                 [self bjl_addChildViewController:self.toolboxViewController superview:self.fullscreenToolboxLayer];
                 [self.toolboxViewController.view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                     make.edges.equalTo(self.fullscreenToolboxLayer);
                 }];
                 
                 if (self.room.loginUser.isTeacherOrAssistant) {
                     [self.documentFileDisplayListView removeFromSuperview];
                     [self.fullscreenToolboxLayer addSubview:self.documentFileDisplayListView];
                     [self.documentFileDisplayListView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                         make.left.equalTo(self.fullscreenLayer);
                         make.width.equalTo(@([BJLIcAppearance sharedAppearance].documentFileDisplayListWidth));
                         make.top.bottom.equalTo(self.fullscreenLayer).inset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight);
                     }];
                     // 重新布局
                     [self.documentFileDisplayListView updateWithDocumentFileList:documentFileList layoutType:BJLIcDocumentFileDisplayLayoutTypeLayoutFullScreen];
                 }
                 // 重新布局
                 [self.toolboxViewController remakeToolboxConstraintsWithLayoutType:BJLIcToolboxLayoutFullScreen];
             }
             // 当前存在最大化窗口，但是 toolbox 不是最大化的布局
             else if (isExistMaximized && self.toolboxViewController.type != BJLIcToolboxLayoutMaximized) {
                 // 如果 toolbox 是全屏的布局, 需要移动层级
                 if (self.toolboxViewController.type == BJLIcToolboxLayoutFullScreen) {
                     [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
                     [self.toolboxViewController.view bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                         make.edges.equalTo(self.toolbox);
                     }];
                 }
                 // 视图可能还未添加，因此必须移动层级
                 if (self.room.loginUser.isTeacherOrAssistant) {
                     [self.documentFileDisplayListView removeFromSuperview];
                     [self.toolbox addSubview:self.documentFileDisplayListView];
                     [self.documentFileDisplayListView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                         make.left.equalTo(self.toolbox);
                         make.width.equalTo(@([BJLIcAppearance sharedAppearance].documentFileDisplayListWidth));
                         make.top.bottom.equalTo(self.blackboardLayer).inset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight); 
                     }];
                     // 重新布局
                     [self.documentFileDisplayListView updateWithDocumentFileList:documentFileList layoutType:BJLIcDocumentFileDisplayLayoutTypeLayoutMaximized];
                 }
                 // 重新布局
                 [self.toolboxViewController remakeToolboxConstraintsWithLayoutType:BJLIcToolboxLayoutMaximized];
             }
             // 当前不存在全屏窗口，最大化窗口，但是 toolbox 的状态不是 normal 布局
             else if (!isExistMaximized && !isExistFullScreen && self.toolboxViewController.type != BJLIcToolboxLayoutNormal) {
                 if (self.toolboxViewController.type == BJLIcToolboxLayoutFullScreen) {
                     // 如果是全屏窗口，移动层级
                     [self bjl_addChildViewController:self.toolboxViewController superview:self.toolbox];
                     [self.toolboxViewController.view bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                         make.edges.equalTo(self.toolbox);
                     }];
                 }
                 if (self.room.loginUser.isTeacherOrAssistant) {
                     // 移除视图
                     [self.documentFileDisplayListView removeFromSuperview];
                     // 重新布局
                     [self.documentFileDisplayListView updateWithDocumentFileList:documentFileList layoutType:BJLIcDocumentFileDisplayLayoutTypeLayoutNormal];
                 }
                 // 重新布局
                 [self.toolboxViewController remakeToolboxConstraintsWithLayoutType:BJLIcToolboxLayoutNormal];
             }
             
             return YES;
         }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.blackboardLayoutViewController, videoWindowDisplayInfos),
                         BJLMakeProperty(self.blackboardLayoutViewController, documentWindowDisplayInfos),
                         BJLMakeProperty(self.blackboardLayoutViewController, webDocumentWindowDisplayInfos)]
                filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                    bjl_strongify(self);
                    return self.room.loginUser.isStudent;
                }
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  // 如果存在全屏的窗口，更新全屏下的举手按钮
                  NSArray *allDisplayInfos = [NSArray arrayWithArray:self.blackboardLayoutViewController.documentWindowDisplayInfos];
                  allDisplayInfos = [allDisplayInfos arrayByAddingObjectsFromArray:self.blackboardLayoutViewController.webDocumentWindowDisplayInfos];
                  allDisplayInfos = [allDisplayInfos arrayByAddingObjectsFromArray:self.blackboardLayoutViewController.videoWindowDisplayInfos];
                  BOOL existFullScreenWindow = NO;
                  for (BJLWindowDisplayInfo *displayInfo in allDisplayInfos) {
                      if (displayInfo.isFullScreen) {
                          existFullScreenWindow = YES;
                          break;
                      }
                  }
                  self.requestSpeakinFullScreenButton.hidden = !existFullScreenWindow;
               }];
}

- (void)roomDidExitWithError:(BJLError *)error {
    // !error: 主动退出
    // BJLErrorCode_exitRoom_disconnected: self.loadingViewController 已处理
    if (!error || error.code == BJLErrorCode_exitRoom_disconnected) {
        [self dismissWithError:error];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"%@: %@(%td)",
                         error.localizedDescription,
                         error.localizedFailureReason ?: @"",
                         error.code];
    BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcExitViewKickOut message:message];
    [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
    [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.popoversLayer);
    }];
    bjl_weakify(self);
    [popoverViewController setConfirmCallback:^{
        bjl_strongify(self);
        [self exit];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

#pragma mark - lamp

- (void)makeObservingForLamp {
    // 使用 Initial 会导致开始监听时触发两次
    bjl_weakify(self);
    [self bjl_kvoMerge:@[BJLMakeProperty(self, customLampContent),
                         BJLMakeProperty(self.room.roomVM, lamp)]
               options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
              observer:^(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  [self updateLamp];
              }];
}

- (void)updateLamp {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    
    BJLLamp *lamp = self.room.roomVM.lamp;
    NSString *lampContent = (self.customLampContent
                             ?: lamp.content);
    
    if (!lampContent.length || lamp.alpha == 0) {
        return;
    }
    
    // lampLabel
    UILabel *lampLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [[UIColor bjl_colorWithHexString:@"#090300" alpha:0.3] colorWithAlphaComponent:(lamp.alpha)];
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 1.0;
        label.font = lamp.font > 0 ? ([UIFont systemFontOfSize:lamp.font] ?: [UIFont systemFontOfSize:10]) : [UIFont systemFontOfSize:10];
        label.textColor = [[UIColor bjl_colorWithHexString:lamp.color] colorWithAlphaComponent:(lamp.alpha)] ?: [UIColor colorWithWhite:1.0 alpha:0.5];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = lampContent;
        [label sizeToFit];
        label.userInteractionEnabled = NO;
        label;
    });
    
    // 文字边距
    CGSize labelSize = CGSizeMake(lampLabel.bounds.size.width + 20.0, lampLabel.bounds.size.height + 10.0);
    
    // 垂直方向位置比例，产生从 垂直方向最小比例（精确到小数点后 3 位） 到 1 之间的一个随机比例，确定跑马灯的垂直方向的位置
    CGFloat containerViewWidth = self.view.bounds.size.width;
    CGFloat containerViewHeight = self.view.bounds.size.height;
    CGFloat minVerticalRatio = 0;
    if  (containerViewHeight > 0) {
        minVerticalRatio = labelSize.height / (containerViewHeight);
    }
    int temp = ceil(minVerticalRatio * 1000);
    CGFloat verticalRatio = ((arc4random() % (1000 - temp)) + temp) / 1000.0;
    
    [self.lampView addSubview:lampLabel];
    [lampLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.lampView.bjl_left).offset(labelSize.width + containerViewWidth);
        make.bottom.equalTo(self.lampView).multipliedBy(verticalRatio);
        make.size.equal.sizeOffset(labelSize);
    }];
    [self.lampView layoutIfNeeded];
    
    // animation
    CGFloat speed = 50.0; // 跑马灯速度
    NSTimeInterval duration = (labelSize.width + containerViewWidth) / speed;
    bjl_weakify(self);
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         bjl_strongify(self);
                         // 设置动画结束后的最终位置
                         [lampLabel bjl_updateConstraints:^(BJLConstraintMaker *make) {
                             make.right.equalTo(self.lampView.bjl_left);
                         }];
                         [self.lampView layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [lampLabel removeFromSuperview];
                     }];
    // 显示间隔
    [self performSelector:_cmd withObject:nil afterDelay:(duration + 60)];
}

#pragma mark - evaluation

- (void)makeObservingForEvaluation {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return old.boolValue != now.boolValue;
    }
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition || now.boolValue) {
            return YES;
        }
        if (!self.room.featureConfig.enableEvaluation || !self.room.featureConfig.evaluationSwitch) {
            return YES;
        }

        BJLIcEvaluationViewController *evaluationVC = [[BJLIcEvaluationViewController alloc] initWithRoom:self.room];
        [self bjl_addChildViewController:evaluationVC superview:self.fullscreenLayer];
        [evaluationVC.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            BOOL iphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
            if (iphone) {
                make.edges.equalTo(self.fullscreenLayer).insets(UIEdgeInsetsMake(20.0, 16.0, 20.0, 16.0));
            }
            else {
                make.center.equalTo(self.fullscreenLayer);
                make.width.equalTo(@540.0).priorityHigh();
                make.height.equalTo(@600.0).priorityHigh();
            }
        }];
        return YES;
    }];
}

#pragma mark - reachability

- (void)setupReachabilityManager {
    self.reachabilityManager = ({
        __block BOOL isFirstTime = YES;
        bjl_weakify(self);
        BJLAFNetworkReachabilityManager *manager = [BJLAFNetworkReachabilityManager manager];
        [manager setReachabilityStatusChangeBlock:^(BJLAFNetworkReachabilityStatus status) {
            bjl_strongify(self);
            if (status != BJLAFNetworkReachabilityStatusReachableViaWWAN) {
                return;
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (status != BJLAFNetworkReachabilityStatusReachableViaWWAN) {
                    return;
                }
                if (isFirstTime) {
                    isFirstTime = NO;
                    UIAlertController *alert = [UIAlertController
                                                bjl_lightAlertControllerWithTitle:@"正在使用3G/4G网络，可手动关闭视频以减少流量消耗"
                                                message:nil
                                                preferredStyle:UIAlertControllerStyleAlert];
                    [alert bjl_addActionWithTitle:@"知道了"
                                            style:UIAlertActionStyleCancel
                                          handler:nil];
                    if (self.presentedViewController) {
                        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                    }
                    [self presentViewController:alert animated:YES completion:nil];
                }
                else {
                    [self showProgressHUDWithText:@"正在使用3G/4G网络"];
                }
            });
        }];
        [manager startMonitoring];
        manager;
    });
}

#pragma mark - lossRate

- (void)makeObservingForLossRate {
    self.lossRateDictionary = [NSMutableDictionary new];
    self.presenterLossRateDictionary = [NSMutableDictionary new];
    [self restartLossRateObservingTimer];

    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, mediaLossRateDidUpdateWithUser:videoLossRate:audioLossRate:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat videoLossRate, CGFloat audioLossRate){
                 bjl_strongify(self);
                 // 目前只统计所有用户主摄流的丢包
                 if(user.mediaSource != BJLMediaSource_mainCamera) {
                     return YES;
                 }
                 
                 CGFloat packageLossRate = MIN(MAX(0.0, videoLossRate), 100.0);
                 // 尝试舍弃丢包100%的情况, 防止正常网络下偶现丢包100%, 导致app弹框强提示. 如果网络实际丢包持续到达100%, 那么上层信令服务器应该已经断开了
                 if(packageLossRate == 100) {
                     return YES;
                 }

                 NSString *userKey = [self userLossRateKeyWithUserID:user.ID mediaSource:user.mediaSource];
                 NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                 if (!lossRateArray) {
                     lossRateArray = [NSMutableArray new];
                 }
                 NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                 NSDictionary<NSNumber *, NSNumber *> *lossRateDic = [NSDictionary dictionaryWithObject:@(packageLossRate) forKey:@(timeInterval)];
                 [lossRateArray bjl_addObject:lossRateDic];
                 [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, didReceivePresenterLossRate:isVideo:userID:mediaSource:)
               filter:^BOOL{
                   bjl_strongify(self);
                   return !self.room.loginUserIsPresenter;
               }
             observer:(BJLMethodObserver)^BOOL(CGFloat lossRate, BOOL isVideo, NSString *userID, BJLMediaSource mediaSourcce) {
                 bjl_strongify(self);
                 if(mediaSourcce != BJLMediaSource_mainCamera) {
                     return YES;
                 }

                 NSString *userKey = [self userLossRateKeyWithUserID:userID mediaSource:mediaSourcce];
                 NSMutableArray<NSDictionary *> *lossRateArray = [[self.presenterLossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                 if (!lossRateArray) {
                     lossRateArray = [NSMutableArray new];
                 }
                 NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                 NSDictionary<NSNumber *, NSNumber *> *lossRateDic = [NSDictionary dictionaryWithObject:@(lossRate) forKey:@(timeInterval)];
                 [lossRateArray bjl_addObject:lossRateDic];
                 [self.presenterLossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                 return YES;
             }];

}

- (void)restartLossRateObservingTimer {
    [self stopLossRateObservingTimer];
    bjl_weakify(self);
    self.lossRateObservingTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify_ifNil(self) {
            [timer invalidate];
            return;
        }
        /* 弱网提示
         每个用户单独计算M秒内平均丢包率;
         自己上行有丢包时, 在自己的界面提示/直播间界面提示;
         自己下行有丢包时, ((有上行丢包&&下行丢包低于上行2倍) || 无上行)->提示自己网络差, (有上行&&上行无丢包 || 下行丢包高于上行两倍)-> 对方网络差
         */
        
        NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
        NSString *loginUserKey = [self userLossRateKeyWithUserID:self.room.loginUser.ID mediaSource:BJLMediaSource_mainCamera];

        NSMutableArray<NSDictionary *> *loginUserLossRateArray = [[self.lossRateDictionary bjl_arrayForKey:loginUserKey] mutableCopy];
        NSInteger loginUserLossRateArrayCount = [loginUserLossRateArray count];
        CGFloat loginUserLossRate = 0.0f;
        if(loginUserLossRateArrayCount) {
            CGFloat totalLossRate = 0.0f;
            for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [loginUserLossRateArray copy]) {
                // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                    if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                        // 大于 lossRateRetainTime 的数据移除
                        [loginUserLossRateArray removeObject:lossRateDic];
                    }
                    else {
                        // 否则加入计算
                        totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                    }
                }
            }
            loginUserLossRate = (loginUserLossRateArray.count > 0) ? totalLossRate / loginUserLossRateArray.count : 0.0f;
            // 更新丢包率的字典
            [self.lossRateDictionary bjl_setObject:loginUserLossRateArray forKey:loginUserKey];
        }
        BJLNetworkStatus loginUserLossRateStatus = [self netWorkStatusWithLossRate:loginUserLossRate];
        
        // 自己是否有上行
        BOOL hasUpPackage = self.room.recordingVM.recordingVideo || self.room.recordingVM.recordingAudio;
        // 自己上行是否丢包
        BOOL hasUpPackageLoss = hasUpPackage && loginUserLossRateStatus != BJLNetworkStatus_normal;
        BOOL shouldLoginUserShowWeakNetWork = hasUpPackageLoss;

        for (NSString *userKey in [self.lossRateDictionary.allKeys copy]) {
            NSString *userID = [self userIDForUserLossRateKey:userKey];
            if([userID isEqualToString:self.room.loginUser.ID]) {
                continue;
            }

            NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
            NSInteger count = lossRateArray.count;
            
            if (count > 0) {
                CGFloat totalLossRate = 0.0;
                for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [lossRateArray copy]) {
                    // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                    for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                        if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                            // 大于 lossRateObservingTimeInterval 的数据移除
                            [lossRateArray removeObject:lossRateDic];
                        }
                        else {
                            // 否则加入计算
                            totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                        }
                    }
                }
                // 更新丢包率的字典
                [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];

                CGFloat lossRate = (lossRateArray.count > 0) ? totalLossRate / lossRateArray.count : 0.0f;
                BJLNetworkStatus status = [self netWorkStatusWithLossRate:lossRate];
                
                // 当前窗口为主讲人窗口时, 取广播丢包率判断
                BOOL isPresenterID = [userID isEqualToString:self.room.onlineUsersVM.currentPresenter.ID];
                if(isPresenterID) {
                    CGFloat presenterLossRate = 0.0f;
                    for (NSString *presenterUserKey in self.presenterLossRateDictionary.allKeys) {
                        NSMutableArray<NSDictionary *> *presenterLossRateArray = [[self.presenterLossRateDictionary bjl_arrayForKey:presenterUserKey] mutableCopy];
                        NSInteger presenterLossRateArrayCount = [presenterLossRateArray count];
                        if(presenterLossRateArrayCount) {
                            CGFloat totalLossRate = 0.0f;
                            for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [presenterLossRateArray copy]) {
                                // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                                for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                                    if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.room.featureConfig.lossRateRetainTime) {
                                        // 大于 lossRateRetainTime 的数据移除
                                        [presenterLossRateArray removeObject:lossRateDic];
                                    }
                                    else {
                                        // 否则加入计算
                                        totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                                    }
                                }
                            }
                            // 更新主讲人丢包率的字典
                            [self.presenterLossRateDictionary bjl_setObject:presenterLossRateArray forKey:presenterUserKey];
                            if([presenterUserKey isEqualToString:userKey]) {
                                presenterLossRate = (presenterLossRateArray.count > 0) ? totalLossRate / presenterLossRateArray.count : 0.0f;
                            }
                        }
                    }
                    BJLNetworkStatus presenterLossRateStatus = [self netWorkStatusWithLossRate:presenterLossRate];

                    if ((BJLNetworkStatus_normal != status && BJLNetworkStatus_normal != presenterLossRateStatus && lossRate > presenterLossRate * 2 ) || (BJLNetworkStatus_normal != status && BJLNetworkStatus_normal == presenterLossRateStatus)) {
                        // 直接自己窗口展示弱网
                        shouldLoginUserShowWeakNetWork = YES;
                        loginUserLossRateStatus = status;
                        break;
                    }
                }
                // (自己无上行&&有下行丢包) || (上行丢包&&下行低于上行两倍丢包)
                else if((status != BJLNetworkStatus_normal && !hasUpPackage)
                   || (hasUpPackageLoss && lossRate <= loginUserLossRate * 2 && status != BJLNetworkStatus_normal)) {
                    // 直接自己窗口展示弱网
                    shouldLoginUserShowWeakNetWork = YES;
                    loginUserLossRateStatus = hasUpPackageLoss ? loginUserLossRateStatus : status;
                    break;
                }
            }
        }
        if(shouldLoginUserShowWeakNetWork) {
            [self updateNetWorkStatus:loginUserLossRateStatus];
        }
    }];
}

- (NSString *)userLossRateKeyWithUserID:(NSString *)userID mediaSource:(BJLMediaSource)mediaSource {
    return [NSString stringWithFormat:@"%@-%td", userID, mediaSource];
}

- (BJLMediaSource)mediaSourceForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    BJLMediaSource mediaSource = BJLMediaSource_mainCamera;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        mediaSource = [key substringFromIndex:separatorRange.location + separatorRange.length].integerValue;
    }
    return mediaSource;
}
- (nullable NSString *)userIDForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    NSString *userID = nil;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        userID = [key substringToIndex:separatorRange.location];
    }
    return userID;
}

- (void)stopLossRateObservingTimer {
    if (self.lossRateObservingTimer || [self.lossRateObservingTimer isValid]) {
        [self.lossRateObservingTimer invalidate];
        self.lossRateObservingTimer = nil;
    }
}

- (BJLNetworkStatus)netWorkStatusWithLossRate:(CGFloat)lossRate {
    NSMutableArray *lossRateArray = [self.room.featureConfig.lossRateLevelArray copy];
    
    BJLNetworkStatus preLossRateLevel = BJLNetworkStatus_normal;
    BJLNetworkStatus currentLossRateLevel = BJLNetworkStatus_normal;
    for (NSInteger index = 0 ; index < [lossRateArray count]; index++) {
        NSNumber *nmber = [lossRateArray objectAtIndex:index];
        CGFloat lossRateLevel = nmber.floatValue;
        if(preLossRateLevel == BJLNetworkStatus_normal && lossRateLevel > 0 && lossRateLevel <= 100) {
            preLossRateLevel = (BJLNetworkStatus)index;
        }
        
        if(lossRateLevel <= 0 || lossRateLevel > 100) {
            continue;
        }
        
        if(lossRateLevel <= lossRate) {
            preLossRateLevel = (BJLNetworkStatus)index;
            continue;
        }
        
        if(lossRateLevel > lossRate) {
            currentLossRateLevel = (BJLNetworkStatus)index;
            break;
        }
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal && preLossRateLevel == BJLNetworkStatus_normal) {
        return BJLNetworkStatus_normal;
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal) {
        currentLossRateLevel = (preLossRateLevel + 1 <= BJLNetworkStatus_Bad_level5) ? (preLossRateLevel + 1) : BJLNetworkStatus_Bad_level5;
    }
    else {
        currentLossRateLevel = (currentLossRateLevel <= BJLNetworkStatus_Bad_level5) ? currentLossRateLevel : BJLNetworkStatus_Bad_level5;
    }
    return currentLossRateLevel;
}

- (void)updateNetWorkStatus:(BJLNetworkStatus)status {
    if(status == BJLNetworkStatus_Bad_level4 || status == BJLNetworkStatus_Bad_level5) {
        [self.promptViewController enqueueWithSpecialPrompt:@"您的网络情况极差" duration:[BJLIcAppearance sharedAppearance].promptDuration important:NO];
    }

    /*
     由于目前丢包率不稳定, 容易瞬时达到峰值, 暂时先注释掉弹框提示
    if(status == BJLNetworkStatus_Bad_level5 && !self.hasShowVeryBadAlert) {
        self.hasShowVeryBadAlert = YES;
        BJLIcPopoverViewController *popoverViewController = [[BJLIcPopoverViewController alloc] initWithPopoverViewType:BJLIcHighLoassRate message:@"哎呀，您的网络开小差了，检测网络后重新进入教室"];
        [self bjl_addChildViewController:popoverViewController superview:self.popoversLayer];
        bjl_weakify(self);
        [popoverViewController setConfirmCallback:^{
            bjl_strongify(self);
            self.hasShowVeryBadAlert = NO;
            [self exit];
            [self dismissViewControllerAnimated:YES completion:nil];

        }];
        [popoverViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.popoversLayer);
        }];
    }
     */
}
@end

NS_ASSUME_NONNULL_END
