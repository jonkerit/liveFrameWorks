//
//  BJLIcBlackboardLayoutViewController+video.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/17.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+video.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"
#import "BJLIcWindowViewController+protected.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcBlackboardLayoutViewController (video)

- (void)makeCallbacksForVideo {
    bjl_weakify(self);
    [self.videoListViewController setPopOverVideoViewCallback:^(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        if (!self.videosGridViewController) {
            self.videosGridViewController = [[BJLIcVideosGridLayoutViewController alloc] init];
            [self bjl_addChildViewController:self.videosGridViewController superview:self.videoWindowsView];
            [self.videosGridViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.edges.equalTo(self.videoWindowsView);
            }];
            [self.videosGridViewController updateContentWithUsers:@[user] room:self.room];
            [self.videosGridViewController setDataSourceEmptyCallback:^{
                bjl_strongify(self);
                [self.videosGridViewController bjl_removeFromParentViewControllerAndSuperiew];
                self.videosGridViewController = nil;
            }];
        }
    }];
    
    [self.videoListViewController setSendBackVideoViewCallback:^(BJLMediaUser * _Nonnull user) {
        bjl_strongify(self);
        [self closeDisplayingVideoWindowWithMediaID:user.mediaID requestUpdate:YES];
    }];
    
    [self.videoListViewController setReplaceVideoViewCallback:^(BJLMediaUser * _Nonnull old, BJLMediaUser * _Nonnull now) {
        bjl_strongify(self);
        BJLWindowDisplayInfo *oldDisplayInfo = nil;
        for (BJLWindowDisplayInfo *displayInfo in [self.videoWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:old.mediaID]) {
                oldDisplayInfo = displayInfo;
                break;
            }
        }
        if (!oldDisplayInfo) {
            return;
        }
        
        NSString *newMediaID = now.mediaID;
        oldDisplayInfo.ID = newMediaID;
        BJLIcVideoWindowViewController *window = [self.displayingVideoWindows bjl_objectForKey:newMediaID
                                                                                         class:[BJLIcVideoWindowViewController class]];
        if (!window) {
            BJLIcUserMediaInfoView *videoView = [[BJLIcUserMediaInfoView alloc] initWithUser:now room:self.room];
            if (videoView) {
                window = [self displayVideoWindowWithVideoView:videoView requestUpdate:NO];
            }
        }
        
        if (window) {
            NSString *action = BJLWindowsUpdateAction_open;
            if(oldDisplayInfo.isFullScreen) {
                action = BJLWindowsUpdateAction_fullScreen;
            }
            else if(oldDisplayInfo.isMaximized) {
                action = BJLWindowsUpdateAction_maximize;
            }
            [self setupVideoWindowWithMediaID:newMediaID action:action displayInfo:oldDisplayInfo];
        }
        [self closeDisplayingVideoWindowWithMediaID:old.mediaID requestUpdate:NO];
    }];
    
    [self.videoListViewController setSendBackAllVideoViewCallback:^{
        bjl_strongify(self);
        [self closeDisplayingVideoWindowsWithRequestUpdate:YES];
    }];
    
    [self.videoListViewController setReceiveLikeCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.receiveLikeCallback) {
            self.receiveLikeCallback(user, button);
        }
    }];
    [self.videoListViewController setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    [self.videoListViewController setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
        bjl_strongify(self);
        if (self.updateVideoCallback) {
            self.updateVideoCallback(user, on);
        }
    }];
    [self.videoListViewController setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        if (self.blockUserCallback) {
            return self.blockUserCallback(user);
        }
        return NO;
    }];
}

- (void)makeObserversForVideo {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.videoListViewController, videoUsersDidUpdate:)
             observer:^BOOL(NSArray<BJLUser *> *users){
                 bjl_strongify(self);
                 if (self.videosGridViewController) {
                     [self.videosGridViewController updateContentWithUsers:users room:self.room];
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUsersDidOverwrite:extraPlayingUsers:)
             observer:^BOOL{
                 bjl_strongify(self);
                 [self autoDisplayVideoWindowsIfNeeded];
                 return YES;
             }];
    
    if (self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1) {
        // 主讲人在推送主摄像头之外的视频流时自动展示窗口，根据需要最大化
        [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidUpdate:old:)
                 observer:^BOOL(BJLMediaUser *user, BJLMediaUser *oldUser) {
                     bjl_strongify(self);
                     // 用户掉线、被踢时关闭窗口
                     if (!user) {
                         [self closeDisplayingVideoWindowWithMediaID:user ? user.mediaID : oldUser.mediaID requestUpdate:NO];
                     }
                     else {
                         if (user
                             && oldUser
                             && user.mediaSource != oldUser.mediaSource) {
                             // 视频源切换，需要关闭 oldUser 的视频窗口
                             [self closeDisplayingVideoWindowWithMediaID:oldUser.mediaID requestUpdate:NO];
                         }
                         
                         //  mediaSource 变化时
                         if (user.mediaSource != BJLMediaSource_mainCamera
                             && (user.mediaSource != oldUser.mediaSource || user.videoOn != oldUser.videoOn)) { // 非 mediaSource 变化不处理
                             if (self.room.loginUser.isTeacher && user.isStudent && user.mediaSource == BJLMediaSource_extraCamera) {
                                 if (user.videoOn) {
                                     BJLIcUserMediaInfoView *videoView = [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room];
                                     CGFloat width = self.blackboardView.frame.size.width;
                                     CGFloat height = self.blackboardView.frame.size.height;
                                     CGFloat x = self.blackboardView.frame.origin.x + self.blackboardView.frame.size.width / 2.0 - width / 2.0;
                                     CGFloat y = self.blackboardView.frame.origin.y + self.blackboardView.frame.size.height / 2.0 - height / 2.0;
                                     videoView.frame = CGRectMake(x, y, width, height);
                                     // 打开辅助摄像头时给个初始 4:3 的数值
                                     [self displayVideoWindowWithVideoView:videoView requestUpdate:YES];
                                 }
                                 else {
                                     [self closeDisplayingVideoWindowWithMediaID:user.mediaID requestUpdate:YES];
                                 }
                             }
                             else {
                                 // 尝试自动最大化
                                 BOOL needsMaximize = (user.mediaSource == BJLMediaSource_screenShare || user.mediaSource == BJLMediaSource_extraScreenShare);
                                 if (![self autoDisplayVideoWindowWithoutRequestForUser:user needsMaximize:needsMaximize]) {
                                     // 不能自动全屏就关闭窗口
                                     [self closeDisplayingVideoWindowWithMediaID:user.mediaID requestUpdate:NO];
                                 }
                             }
                         }
                     }
                     
                     return YES;
                 }];
    }
    else {
        // 主讲人在推送主摄像头之外的视频流时自动展示窗口，根据需要最大化
        [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidUpdate:old:)
                 observer:^BOOL(BJLMediaUser *user, BJLMediaUser *oldUser) {
                     bjl_strongify(self);
                     // 用户掉线、被踢时关闭窗口
                     if (!user) {
                         [self closeDisplayingVideoWindowWithMediaID:user ? user.mediaID : oldUser.mediaID requestUpdate:NO];
                     }
                     else {
                         BOOL isPresenter = (self.room.onlineUsersVM.currentPresenter
                                             ? [user isSameUser:self.room.onlineUsersVM.currentPresenter]
                                             : [user isSameUser:self.room.onlineUsersVM.onlineTeacher]);
                         
                         if (!isPresenter) {
                             // 只处理主讲人的视频流
                             return YES;
                         }
                         
                         if (user
                             && oldUser
                             && user.mediaSource != oldUser.mediaSource) {
                             // 视频源切换，需要关闭 oldUser 的视频窗口
                             [self closeDisplayingVideoWindowWithMediaID:oldUser.mediaID requestUpdate:NO];
                         }
                         
                         // 主讲人 && 主视频 && mediaSource 变化时
                         if (user.mediaSource != BJLMediaSource_mainCamera
                             && (user.mediaSource != oldUser.mediaSource || user.videoOn != oldUser.videoOn)) { // 非 mediaSource 变化不处理
                                                                                                                // 尝试自动最大化
                             BOOL needsMaximize = (user.mediaSource == BJLMediaSource_screenShare || user.mediaSource == BJLMediaSource_extraScreenShare);
                             if (user.mediaSource == BJLMediaSource_extraCamera && BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
                                 needsMaximize = YES;
                             }
                             if (![self autoDisplayVideoWindowWithoutRequestForUser:user needsMaximize:needsMaximize]) {
                                 // 不能自动全屏就关闭窗口
                                 [self closeDisplayingVideoWindowWithMediaID:user.mediaID requestUpdate:NO];
                             }
                         }
                     }
                     
                     return YES;
                 }];
    }
    
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, didUpdateVideoWindowWithModel:shouldReset:)
             observer:(BJLMethodObserver)^BOOL(BJLWindowUpdateModel *updateModel, BOOL shouldReset) {
                 bjl_strongify(self);
                 if (shouldReset) {
                     [self resetVideoWindowsWithModel:updateModel];
                 }
                 else {
                     [self updateVideoWindowWithModel:updateModel];
                 }
                 
                 [self autoDisplayVideoWindowsIfNeeded];
                 
                 return YES;
             }];
    
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.playingVM, didRemoveActiveUser:),
                             BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidExit:)]
                  observer:^(BJLUser *user) {
                      bjl_strongify(self);
                      // !!! 监听到用户下台、退出教室时，老师负责发送关闭该用户窗口的通知
                      [self closeDisplayingVideoWindowsForUser:user
                                                 requestUpdate:self.room.loginUser.isTeacher ? YES : NO];
                  }];
    
    [self bjl_observe:BJLMakeMethod(self.room.onlineUsersVM, onlineUserDidEnter:)
             observer:^BOOL(BJLUser *user){
                 bjl_strongify(self);
                 [self closeDisplayingVideoWindowsForUser:user requestUpdate:NO];
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.playingVM, extraPlayingUsers)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             for (BJLMediaUser *user in self.room.playingVM.extraPlayingUsers) {
                 if (!user.videoOn
                     && user.audioOn
                     && user.mediaSource == BJLMediaSource_mediaFile) {
                     self.audioFileButton.hidden = NO;
                     return YES;
                 }
             }
             self.audioFileButton.hidden = YES;
             return YES;
         }];
}

#pragma mark - video window

- (void)autoDisplayVideoWindowsIfNeeded {
    // 主讲人在推送主摄像头之外的视频流时自动展示窗口，根据需要最大化
    BJLUser *presenter = self.room.onlineUsersVM.currentPresenter ?: self.room.onlineUsersVM.onlineTeacher;
    if (!presenter) {
        return;
    }
    
    // extraPlayingUsers 中寻找需要展示窗口的的视频流
    for (BJLMediaUser *extraUser in self.room.playingVM.extraPlayingUsers) {
        if ([extraUser isSameUser:presenter]
            && extraUser.mediaSource != BJLMediaSource_mainCamera) {
            BOOL needsMaximize = (extraUser.mediaSource == BJLMediaSource_screenShare || extraUser.mediaSource == BJLMediaSource_extraScreenShare);
            if (extraUser.mediaSource == BJLMediaSource_extraCamera && BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
                needsMaximize = YES;
            }
            // 尝试自动最大化
            if (![self autoDisplayVideoWindowWithoutRequestForUser:extraUser needsMaximize:needsMaximize]) {
                // 不能自动最大化就关闭窗口
                [self closeDisplayingVideoWindowWithMediaID:extraUser.mediaID requestUpdate:NO];
            }
        }
    }
    
    // playingUsers 中寻找需要展示窗口的的视频流
    for (BJLMediaUser *user in self.room.playingVM.playingUsers) {
        if ([user isSameUser:presenter]
            && user.mediaSource != BJLMediaSource_mainCamera) {
            BOOL needsMaximize = (user.mediaSource == BJLMediaSource_screenShare || user.mediaSource == BJLMediaSource_extraScreenShare);
            if (user.mediaSource == BJLMediaSource_extraCamera && BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
                needsMaximize = YES;
            }
            // 尝试自动最大化
            if (![self autoDisplayVideoWindowWithoutRequestForUser:user needsMaximize:needsMaximize]) {
                // 不能自动最大化就关闭窗口
                [self closeDisplayingVideoWindowWithMediaID:user.mediaID requestUpdate:NO];
            }
        }
    }
}

// 开启视频且非摄像头采集（屏幕共享 || 播放媒体文件），自动打开并最大化
- (BOOL)autoDisplayVideoWindowWithoutRequestForUser:(BJLMediaUser *)user needsMaximize:(BOOL)needsMaximize {
    if (!user
        || !user.videoOn
        || user.mediaSource == BJLMediaSource_mainCamera) {
        return NO;
    }
    
    [self.videoListViewController setUserLeaveSeatWithMediaID:user.mediaID];
    
    BJLIcVideoWindowViewController *window = [self.displayingVideoWindows bjl_objectForKey:user.mediaID
                                                                                     class:[BJLIcVideoWindowViewController class]];
    if (!window) {
        BJLIcUserMediaInfoView *videoView = [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room];
        if (videoView) {
            window = [self displayVideoWindowWithVideoView:videoView requestUpdate:NO];
        }
    }
    
    if (window) {
        for (BJLWindowDisplayInfo *displayInfo in self.videoWindowDisplayInfos) {
            if ([displayInfo.ID isEqualToString:window.videoView.mediaID]) {
                
                if (displayInfo.isFullScreen) {
                    [window fullScreenWithoutRequest];
                }
                else if (displayInfo.isMaximized) {
                    [window maximizeWithoutRequest];
                }
                else if (window.state != BJLWindowState_maximized
                         && window.state != BJLWindowState_fullscreen) {
                    [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
                }
                else {
                    [window restoreWithoutRequest];
                }
            }
        }
        
        if (needsMaximize) {
            if (user.mediaSource == BJLMediaSource_screenShare
                || user.mediaSource == BJLMediaSource_extraScreenShare) {
                // 最大化屏幕共享时，先收回对应主摄像头采集的窗口，!!!: 本应该由发屏幕分享的一方发送收回窗口的信令
                [self closeDisplayingVideoWindowWithMediaID:user.ID requestUpdate:NO];
            }
            [window maximizeWithoutRequest];
            window.doubleTapToMaximize = NO;
            if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
                [window bjl_removeFromParentViewControllerAndSuperiew];
                
                // 第二套模板的辅助摄像头放在大黑板层，不遮挡网页小黑板和其他视频窗口
                if(user.mediaSource == BJLMediaSource_extraCamera) {
                    [window setWindowedParentViewController:self superview:self.blackboardView];
                }
                else {
                    [window setWindowedParentViewController:self superview:self.alwaysMaximizeVideoWindowsView];
                }
            }
            else {
                [window bringToFrontWithoutRequest];
            }
        }
    }
    
    return YES;
}

- (void)resetVideoWindowsWithModel:(BJLWindowUpdateModel *)updateModel {
    [self closeDisplayingVideoWindowsWithRequestUpdate:NO];
    self.videoWindowDisplayInfos = [NSArray array];
    self.mutableVideoWindowDisplayInfos = [NSMutableArray array];
    
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        NSString *mediaID = displayInfo.ID;
        //reset窗口的时候，不应该使用action，应该把all displayinfo都展示成窗口, 区分窗口和最大化，全屏
        NSString *action = BJLWindowsUpdateAction_open;
        if(displayInfo.isFullScreen) {
            action = BJLWindowsUpdateAction_fullScreen;
        }
        else if(displayInfo.isMaximized) {
            action = BJLWindowsUpdateAction_maximize;
        }
        [self setupVideoWindowWithMediaID:mediaID action:action displayInfo:displayInfo];
    }
}

- (void)updateVideoWindowWithModel:(BJLWindowUpdateModel *)updateModel {
    NSString *mediaID = updateModel.ID;
    if (!mediaID.length) {
        return;
    }
    
    BJLWindowDisplayInfo *newDisplayInfo = nil;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        if ([displayInfo.ID isEqualToString:mediaID]) {
            newDisplayInfo = displayInfo;
            break;
        }
    }
    
    BJLWindowDisplayInfo *oldDisplayInfo = nil;
    for (BJLWindowDisplayInfo *displayInfo in [self.videoWindowDisplayInfos copy]) {
        if ([displayInfo.ID isEqualToString:mediaID]) {
            oldDisplayInfo = displayInfo;
            break;
        }
    }
    if (oldDisplayInfo) {
        [self.mutableVideoWindowDisplayInfos removeObject:oldDisplayInfo];
    }
    [self setupVideoWindowWithMediaID:mediaID action:updateModel.action displayInfo:newDisplayInfo];
}

- (void)setupVideoWindowWithMediaID:(NSString *)mediaID action:(NSString *)action displayInfo:(nullable BJLWindowDisplayInfo *)displayInfo {

    // 关闭
    if ([action isEqualToString:BJLWindowsUpdateAction_close]) {
        [self closeDisplayingVideoWindowWithMediaID:mediaID requestUpdate:NO];
        self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
        return;
    }
    
    // 兼容处理player_view_update 拿到数据为:action为Stick或者reposition, 但同时all为空的情况(理论上不允许出现)
    if (!displayInfo) {
        self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
        return;
    }
    
    BJLIcVideoWindowViewController *window = [self.displayingVideoWindows bjl_objectForKey:mediaID
                                                                                     class:[BJLIcVideoWindowViewController class]];
    BJLIcUserMediaInfoView *videoView = nil;
    // 打开
    if ([action isEqualToString:BJLWindowsUpdateAction_open] || !window) {
        if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
            // 第二套模板过滤掉老师主摄像头视频
            if (self.updateTeacherMediaInfoViewCallback) {
                videoView = self.updateTeacherMediaInfoViewCallback(YES, mediaID);
            }
        }
        // 如果不是第二套模板或者不是第二套模板的老师主摄像头视频，从用户列表中取视频
        if (!videoView) {
            // 首先认为 mediaID 是正确的，去取列表中的视图
            videoView = [self.videoListViewController setUserLeaveSeatWithMediaID:mediaID];
            if (!videoView) {
                // 如果没有取到，去获取mediaID 对应的user
                BJLMediaUser *user = [self.room.playingVM playingUserWithMediaID:mediaID];
                // 然后纠正因为绑定了窗口和用户导致主摄像头和屏幕共享是同一个用户信息的错误的数据
                BJLMediaUser *extraUser = [self availableExtraPlayingUserForUser:user] ?: user;
                // 再次尝试去获取视图
                videoView = [self.videoListViewController setUserLeaveSeatWithMediaID:extraUser.mediaID];
                if (!videoView && user) {
                    videoView = [[BJLIcUserMediaInfoView alloc] initWithUser:user room:self.room];
                }
            }
        }
        // 存在视频视图，打开
        if (videoView) {
            window = [self displayVideoWindowWithVideoView:videoView requestUpdate:NO];
        }
    }
    
    // 全屏 !!!: no else if
    if ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]) {
        [window fullScreenWithoutRequest];
    }
    // 最大化
    else if ([action isEqualToString:BJLWindowsUpdateAction_maximize]) {
        [window maximizeWithoutRequest];
    }
    // 还原
    else if ([action isEqualToString:BJLWindowsUpdateAction_restore]) {
        if (displayInfo.isFullScreen) {
            [window fullScreenWithoutRequest];
        }
        else if (displayInfo.isMaximized) {
            [window maximizeWithoutRequest];
        }
        else if (window.state != BJLWindowState_maximized
                 && window.state != BJLWindowState_fullscreen) {
            [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
        }
        else {
            if (displayInfo) {
                [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
            }
            [window restoreWithoutRequest];
        }
    }
    else {
        [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
    }
    [window bringToFrontWithoutRequest];
    if (displayInfo) {
        [self.mutableVideoWindowDisplayInfos bjl_addObject:displayInfo];
    }
    self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
}

- (nullable BJLMediaUser *)availableExtraPlayingUserForUser:(BJLMediaUser *)user {
    if (!user || user.isTeacher) {
        return nil;
    }
    
    // 倒序遍历，找出最新的 extraPlayingUser
    for (BJLMediaUser *extraPlayingUser in [self.room.playingVM.extraPlayingUsers reverseObjectEnumerator]) {
        if ([extraPlayingUser isSameUser:user]) {
            if (extraPlayingUser.videoOn && extraPlayingUser.mediaSource == BJLMediaSource_screenShare) {
                return extraPlayingUser;
            }
            else if (extraPlayingUser.mediaSource == BJLMediaSource_mediaFile) {
                return extraPlayingUser;
            }
        }
    }
    return nil;
}


@end

NS_ASSUME_NONNULL_END
