//
//  BJLRoomViewController+observing.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-01-19.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/UIKit+BJL_M9Dev.h>

#import "BJLRoomViewController+protected.h"
#import "BJLViewImports.h"
#import "BJLLikeEffectViewController.h"
#import "BJLAnswerSHeetResultViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLRoomViewController (observing)

/**
 场景:
 1. 有内容出现时: 如果没有全屏内容、并且此内容是 PPT/老师视频 时，不动画全屏显示，否则不动画小窗显示
 2. 小窗内容关闭时: 不动画关闭
 3. 全屏内容关闭时: 不动画关闭，如果小窗存在 PPT/老师视频 时【自动】【动画】全屏，否则保留空白
 4. 双击小窗内容时: 如果有全屏内容【动画】互换，否则【动画】全屏
 事件:
 有事件发生时(有人开启摄像头): 如果对方是老师，并且本地未进行过开关对方摄像头的操作的情况下【自动】打开对方视频
 @see didUpdateVideoPlayingUser，打开老师视频时重置此参数
*/

- (void)makeObservingWhenEnteredInRoom {
    if (self.room.loginUser.isTeacher) {
        [self makeObservingForRecordingAndServerRecording];
    }
    else if (self.room.loginUser.isAssistant) {
        // nothing here
        [self makeObservingForAssistant];
    }
    else {
        if (self.room.roomInfo.roomType != BJLRoomType_1vNClass) {
            [self makeObservingFor1to1OrM];
        }
        else {
            [self makeObservingFor1toN];
        }
        [self makeObservingForSpeakingInvite];
        [self makeObservingForLamp];
        [self makeObservingForRollcall];
        [self makeObservingForNotice];
        [self makeObservingForQuiz];
        [self makeObservingForAnswerSheet];
        [self makeObservingForEvaluation];
    }
    
    [self makeObservingForPPTAndDrawing];
    [self makeObservingForFullScreen];
    [self makeObservingForProgressHUD];
    [self makeObservingForLoadingVideo];
    [self makeObservingForLikeEffect];
//    [self makeObservingForEnvelope];
    [self makeObservingForQuestion];
    [self makeObservingForLossRate];
    [self makeObservingForCountDownTimer];

    [self.chatViewController refreshMessages];
}

- (void)makeObservingForAssistant {
    bjl_weakify(self);

    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveAssistantaAuthorityChanged) observer:^BOOL{
        bjl_strongify(self);
        [self showProgressHUDWithText:@"权限已变更"];
        
        // 如果助教被收回画笔权限，此时也要更新画笔权限，防止此时助教正在使用画笔而没有被收回权限
        if (![self.room.roomVM getAssistantaAuthorityWithPainter]) {
            [self.room.drawingVM updateDrawingEnabled:NO];
        }
        return YES;
    }];
}

- (void)makeObservingForRecordingAndServerRecording {
    bjl_weakify(self);
    
    if (self.room.featureConfig.isWebRTC) {
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room.roomVM, liveStarted),
                             BJLMakeProperty(self.room.mediaVM, inLiveChannel)]
                  observer:^(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                      bjl_strongify(self);
                      if (self.room.loginUser.isAudition) {
                          return;
                      }
                      if (self.room.roomVM.liveStarted
                          && self.room.mediaVM.inLiveChannel) {
                          // 自动开启音视频
                          [self autoStartRecordingAudioAndVideo];
                      }
                  }];
    }
    else {
        [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
               filter:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return now.boolValue;
               }
             observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 // 自动开启音视频
                 [self autoStartRecordingAudioAndVideo];
                 return NO; // only once
             }];
    }
    
    __block BOOL wasRecordingAudio = YES, wasRecordingVideo = YES;
    [self bjl_kvo:BJLMakeProperty(self.room, state)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               bjl_strongify(self);
               // 断开时记录采集音视频状态
               if (old.integerValue == BJLRoomState_connected
                   && now.integerValue != BJLRoomState_connected) {
                   wasRecordingAudio = self.room.recordingVM.recordingAudio;
                   wasRecordingVideo = self.room.recordingVM.recordingVideo;
               }
               // 重连后恢复采集音视频状态
               return (old.integerValue != BJLRoomState_connected
                       && now.integerValue == BJLRoomState_connected
                       && self.room.roomVM.liveStarted
                       && (wasRecordingAudio || wasRecordingVideo)
                       && (wasRecordingAudio != self.room.recordingVM.recordingAudio
                           || wasRecordingVideo != self.room.recordingVM.recordingVideo));
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BJLError *error = [self.room.recordingVM setRecordingAudio:wasRecordingAudio
                                                         recordingVideo:wasRecordingVideo];
             if (error) {
                 [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
             }
             /*
             else {
                 [self showProgressHUDWithText:(self.room.recordingVM.recordingVideo
                                                ? @"摄像头已打开"
                                                : @"摄像头已关闭")];
             } */
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.serverRecordingVM, requestServerRecordingDidFailed:)
             observer:^BOOL(NSString *message) {
                 bjl_strongify(self);
                 [self showProgressHUDWithText:message];
                 return YES;
             }];
}

- (void)makeObservingFor1to1OrM {
    bjl_weakify(self);
    if (self.room.featureConfig.isWebRTC) {
        [self bjl_kvoMerge:@[BJLMakeProperty(self.room.roomVM, liveStarted),
                             BJLMakeProperty(self.room.mediaVM, inLiveChannel)]
                  observer:^(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                      bjl_strongify(self);
                      if (self.room.loginUser.isAudition) {
                          return;
                      }
                      if (self.room.roomVM.liveStarted && self.room.mediaVM.inLiveChannel) {
                          [self autoStartRecordingAudioAndVideo];
                      }
                  }];
    }
    else {
        [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return now.boolValue;
               }
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 [self autoStartRecordingAudioAndVideo];
                 return YES;
             }];
    }
}

- (void)makeObservingFor1toN {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingEnabled)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.loginUser.isAudition) {
                 return YES;
             }
             if (now.boolValue) {
                 if (!self.room.recordingVM.recordingAudio
                     && !self.room.recordingVM.recordingVideo) {
                     [self autoStartRecordingAudioAndVideo];
                 }
             }
             else {
                 if (self.room.recordingVM.recordingAudio
                     || self.room.recordingVM.recordingVideo) {
                     [self.room.recordingVM setRecordingAudio:NO recordingVideo:NO];
                 }
                 if (self.room.slideshowViewController.drawingEnabled) {
                     [self.room.drawingVM updateDrawingEnabled:NO];
                 }
             }
             return YES;
         }];
}

- (void)autoStartRecordingAudioAndVideo {
    // 助教不自动打开音视频
    if (self.room.loginUser.isAssistant) {
        return;
    }
    
    if (self.room.loginUser.isAudition) {
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

- (void)makeObservingForSpeakingInvite {
    __block UIAlertController *alert = nil;
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, didReceiveSpeakingInvite:)
             observer:(BJLMethodObserver)^BOOL(BOOL invite) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (alert) {
            [alert dismissViewControllerAnimated:NO completion:nil];
            alert = nil;
        }
        if (invite) {
            alert = [UIAlertController
                     bjl_lightAlertControllerWithTitle:@"老师邀请你上麦发言"
                     message:nil
                     preferredStyle:UIAlertControllerStyleAlert];
            [alert bjl_addActionWithTitle:@"同意"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                alert = nil;
                [self.room.speakingRequestVM responseSpeakingInvite:YES];
                BJLError *error = [self.room.recordingVM setRecordingAudio:YES recordingVideo:YES];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                else {
                    [self showProgressHUDWithText:(self.room.recordingVM.recordingAudio
                                                   ? @"麦克风已打开"
                                                   : @"麦克风已关闭")];
                }
            }];
            [alert bjl_addActionWithTitle:@"拒绝"
                                    style:UIAlertActionStyleDestructive
                                  handler:^(UIAlertAction * _Nonnull action) {
                bjl_strongify(self);
                alert = nil;
                [self.room.speakingRequestVM responseSpeakingInvite:NO];
                [self.room.recordingVM setRecordingAudio:NO recordingVideo:NO];
            }];
            [self presentViewController:alert animated:YES completion:nil];
        }
        return YES;
    }];
}

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
    
    // 第一次手动触发
    [self updateLamp];
}

- (void)makeObservingForRollcall {
    bjl_weakify(self);
    
    NSString * const rollcallTitleFormat = @"老师要求你在%.0f秒内响应点名";
    __block UIAlertController *rollcallAlert = nil;
    __block id<BJLObservation> observation = nil;
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRollcallWithTimeout:)
             observer:^BOOL(NSTimeInterval timeout) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 if (rollcallAlert) {
                     [rollcallAlert dismissViewControllerAnimated:NO completion:nil];
                 }
                 
                 rollcallAlert = [UIAlertController bjl_lightAlertControllerWithTitle:@"点名"
                                                                     message:[NSString stringWithFormat:rollcallTitleFormat, timeout]
                                                              preferredStyle:UIAlertControllerStyleAlert];
                 [rollcallAlert bjl_addActionWithTitle:@"答到"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action) {
                                                   bjl_strongify(self);
                                                   rollcallAlert = nil;
                                                   [observation stopObserving];
                                                   observation = nil;
                                                   [self.room.roomVM answerToRollcall];
                                               }];
                 if (self.presentedViewController) {
                     [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                 }
                 [self presentViewController:rollcallAlert animated:YES completion:nil];
                 
                 observation = [self bjl_kvo:BJLMakeProperty(self.room.roomVM, rollcallTimeRemaining)
                                    observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                                        bjl_strongify(self);
                                        rollcallAlert.message = [NSString stringWithFormat:rollcallTitleFormat, self.room.roomVM.rollcallTimeRemaining];
                                        return YES;
                                    }];
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, rollcallDidFinish)
             observer:^BOOL {
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 [observation stopObserving];
                 observation = nil;
                 [rollcallAlert dismissViewControllerAnimated:YES completion:nil];
                 rollcallAlert = nil;
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveAttentionWarning:)
             observer:^BOOL(NSString *content) {
        bjl_strongify(self);
        [self showProgressHUDWithText:content];
        return YES;
    }];
}

- (void)makeObservingForPPTAndDrawing {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, totalPageCount)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.contentView.pageCount = self.room.documentVM.totalPageCount;
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, totalPageCount)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.contentView.pageCount = self.room.documentVM.totalPageCount;
             return YES;
         }];
    // BJLMakeProperty(self.room.BJLDocumentVM, currentSlidePage)
    [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, localPageIndex)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             // self.room.BJLDocumentVM.currentSlidePage.documentPageIndex
             self.contentView.pageIndex = self.room.slideshowViewController.localPageIndex;
             if (self.room.slideshowViewController.localPageIndex != self.room.documentVM.currentSlidePage.documentPageIndex) {
                 if (!self.room.loginUser.isTeacherOrAssistant
                     && self.room.slideshowViewController.drawingEnabled) {
                     [self.room.drawingVM updateDrawingEnabled:NO];
                 }
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.slideshowViewController, drawingEnabled)
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL isHorizontal = BJLIsHorizontalUI(self);
             self.contentView.showsClearDrawingButton = now.boolValue;
             [self updateStatusBarAndTopBar];
             [self updateChatConstraintsForHorizontal:isHorizontal];
             [self updateRecordingStateViewForHorizontal:isHorizontal];
             return YES;
         }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.documentVM, allDocuments), BJLMakeProperty(self.room.documentVM, currentSlidePage), BJLMakeProperty(self.room.slideshowViewController, localPageIndex)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  NSInteger localPageIndex = self.room.slideshowViewController.localPageIndex;
                  BJLDocument *whiteboardDocument = [self.room.documentVM documentWithID:BJLBlackboardID];
                  NSInteger whiteboardPageCount = MAX(whiteboardDocument.pageInfo.pageCount, 1);
                  if (localPageIndex + 1 <= whiteboardPageCount) {
                      [self.room.slideshowViewController.pageControlButton setTitle:(whiteboardPageCount > 1 ? [NSString stringWithFormat:@"白板%td", localPageIndex + 1] : @"白板") forState:UIControlStateNormal];
                  }
                  else {
                      [self.room.slideshowViewController.pageControlButton setTitle:[NSString stringWithFormat:@"%td/%td", localPageIndex - whiteboardPageCount + 1, self.room.documentVM.totalPageCount - whiteboardPageCount] forState:UIControlStateNormal];
                  }
              }];
    
    // 设置PPT是否可绘制，page control button 是否可用
    [self bjl_kvo:BJLMakeProperty(self.contentView, content)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL isPPT = (now == self.room.slideshowViewController.view);
             if (!isPPT && self.room.slideshowViewController.drawingEnabled) {
                 [self.room.drawingVM updateDrawingEnabled:NO];
             }
             self.room.slideshowViewController.pageControlButton.enabled = isPPT;
             return YES;
         }];
}

- (void)makeObservingForFullScreen {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.previewsViewController, fullScreenItem)
         observer:^BOOL(BJLPreviewItem * _Nullable fullScreenItem, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (fullScreenItem.viewController) {
                 [self bjl_addChildViewController:fullScreenItem.viewController
                                       addSubview:^(UIView * _Nonnull parentView, UIView * _Nonnull childView) {
                                           bjl_strongify(self);
                                           [self.contentView updateWithPreviewItem:fullScreenItem];
                                       }];
             }
             else {
                 [self.contentView updateWithPreviewItem:fullScreenItem];
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.previewsViewController, numberOfItems)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.integerValue != old.integerValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL isHorizontal = BJLIsHorizontalUI(self);
             [self updatePreviewsAndContentConstraintsForHorizontal:isHorizontal];
             return YES;
         }];
    
    // self.previewsViewController.collectionView.contentSize
    [self bjl_kvo:BJLMakeProperty(self.previewsViewController.collectionView, contentSize)
           filter:^BOOL(NSValue * _Nullable now, NSValue * _Nullable old, BJLPropertyChange * _Nullable change) {
               return !CGSizeEqualToSize(now.CGSizeValue, old.CGSizeValue);
           }
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL isHorizontal = BJLIsHorizontalUI(self);
             [self updatePreviewsAndContentConstraintsForHorizontal:isHorizontal];
             return YES;
         }];
}

- (void)makeObservingForNotice {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, notice)
           filter:^BOOL(BJLNotice * _Nullable now, BJLNotice * _Nullable old, BJLPropertyChange * _Nullable change) {
//                bjl_strongify(self);
                if (now.noticeText.length || now.linkURL) {
                    return YES;
                }
                
                BOOL hasChange = NO;
                for (BJLNoticeModel *notice in now.groupNoticeList) {
                    if (notice.noticeText.length || notice.linkURL) {
                        hasChange = YES;
                        break;
                    }
                }
                return hasChange;
            }
         observer:^BOOL(BJLNotice * _Nullable notice, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self.overlayViewController showWithContentViewController:self.noticeViewController];
             return YES;
         }];
}

- (void)makeObservingForQuiz {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuizMessage:)
             observer:^BOOL(NSDictionary<NSString *, id> *message) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 BJLQuizWebViewController *quizWebViewController = [BJLQuizWebViewController
                                                                    instanceWithQuizMessage:message
                                                                    roomVM:self.room.roomVM];
                 if (quizWebViewController) {
                     quizWebViewController.closeWebViewCallback = ^{
                         bjl_strongify(self);
                         [self.overlayViewController hide];
                         self.quizWebViewController = nil;
                     };
                     quizWebViewController.sendQuizMessageCallback = ^BJLError * _Nullable(NSDictionary<NSString *, id> * _Nonnull message) {
                         bjl_strongify(self);
                         return [self.room.roomVM sendQuizMessage:message];
                     };
                     if (self.quizWebViewController) {
                         [self.overlayViewController hide];
                     }
                     self.quizWebViewController = quizWebViewController;
                     if (bjl_iPhoneXSeries()) {
                         self.overlayViewController.prefersStatusBarHidden = NO;
                         self.overlayViewController.preferredStatusBarStyle = UIStatusBarStyleDefault;
                     }
                     [self.overlayViewController showWithContentViewController:self.quizWebViewController
                                                                      horEdges:UIRectEdgeAll
                                                                       horSize:CGSizeZero
                                                                      verEdges:UIRectEdgeAll
                                                                       verSize:CGSizeZero];
                 }
                 else if (self.quizWebViewController) {
                     [self.quizWebViewController didReceiveQuizMessage:message];
                 }
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self.room, state)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.loginUser.isAudition) {
                 return YES;
             }
             if (self.room.state == BJLRoomState_connected) {
                 if (self.quizWebViewController) {
                     [self.overlayViewController hide];
                 }
                 [self.room.roomVM sendQuizMessage:[BJLQuizWebViewController quizReqMessageWithUserNumber:self.room.loginUser.number]];
             }
             return YES;
         }];
}

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
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (!self.room.featureConfig.enableEvaluation) {
            return YES;
        }
        if (now.boolValue) {
            return YES;
        }
        BJLEvaluationViewController *vc = [[BJLEvaluationViewController alloc] initWithRoom:self.room];
        [vc setCloseEvaluationCallback:^{
            bjl_strongify(self);
            [self.overlayViewController hide];
        }];
        [self.overlayViewController showWithContentViewController:vc remakeConstraintsBlock:^(BJLConstraintMaker * _Nonnull make, UIView * _Nonnull superView, BOOL isHorizontalUI, BOOL isHorizontalSize) {
            BOOL iphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
            if (iphone) {
                make.edges.equalTo(superView).insets(UIEdgeInsetsMake(10.0, 16.0, 20.0, 16.0));
            }
            else {
                if (isHorizontalUI) {
                    make.center.equalTo(superView);
                    make.width.equalTo(@540.0).priorityHigh();
                    make.height.equalTo(@600.0).priorityHigh();
                }
                else {
                    make.centerX.equalTo(superView);
                    make.centerY.equalTo(superView.bjl_bottom).multipliedBy(0.457);
                    make.width.equalTo(@540.0).priorityHigh();;
                    make.height.equalTo(@600.0).priorityHigh();;
                }
            }
        }];
        return YES;
    }];
}

- (void)makeObservingForProgressHUD {
    bjl_weakify(self);
    
    // 麦克风和摄像头权限
    __block UIAlertController *alertController = nil;
    [self.room.recordingVM setCheckMicrophoneAndCameraAccessCallback:^(BOOL microphone, BOOL camera, BOOL granted, UIAlertController * _Nullable alert) {
        bjl_strongify(self);
        if (granted) {
            return;
        }
        // 未授权时重置当前的 UI 状态
        if (microphone) {
            self.controlsViewController.micButton.selected = NO;
            self.settingsViewController.micSwitch.on = NO;
        }
        if (camera) {
            self.controlsViewController.cameraButton.selected = NO;
            self.settingsViewController.cameraSwitch.on = NO;
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
    
    __block BOOL isInitial = YES;
    [self bjl_kvo:BJLMakeProperty(self.room.serverRecordingVM, serverRecording)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self.moreViewController setServerRecordingEnabled:now.boolValue];
             BOOL isHorizontal = BJLIsHorizontalUI(self);
             [self updateRecordingStateViewForHorizontal:isHorizontal];
             if (now.boolValue) {
                 [self showProgressHUDWithText:@"已开启录课"];
             }
             else {
                 if (!isInitial) {
                     [self showProgressHUDWithText:@"已关闭录课"];
                 }
             }
             isInitial = NO;
             return YES;
         }];
    
    if (self.room.featureConfig.isWebRTC) {
        // webRTC 进入直播频道失败
        [self bjl_observe:BJLMakeMethod(self.room.mediaVM, enterLiveChannelFailed)
                 observer:^BOOL{
                     bjl_strongify(self);
                     [self showProgressHUDWithText:@"进入直播频道失败，请重试"];
                     return YES;
                 }];
        
        // webRTC 直播频道断开提示
        [self bjl_observe:BJLMakeMethod(self.room.mediaVM, didLiveChannelDisconnectWithError:)
                 observer:^BOOL(NSError *error){
                     bjl_strongify(self);
                     [self showProgressHUDWithText:@"直播频道已断开，请重试"];
                     return YES;
                 }];
        
        // webRTC 推流重试提示
        [self bjl_observe:BJLMakeMethod(self.room.recordingVM, republishing)
                 observer:^BOOL{
                     bjl_strongify(self);
                     [self showProgressHUDWithText:@"音视频推送失败，自动重试中"];
                     return YES;
                 }];
        
        // webRTC 推流重试提示
        [self bjl_observe:BJLMakeMethod(self.room.recordingVM, publishFailed)
                 observer:^BOOL{
                     bjl_strongify(self);
                     [self showProgressHUDWithText:@"音视频推送失败，请检查网络后重试"];
                     return YES;
                 }];
    }
    
    // 切换主讲
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, currentPresenter)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(BJLUser * _Nullable now, BJLUser * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return (old // 默认主讲不提示
                       && now // 老师掉线不提示
                       && old != now
                       && ![now isSameUser:old]);
           }
         observer:^BOOL(BJLUser * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             NSString *name = self.room.loginUserIsPresenter ? @"你" : now.displayName;
             [self showProgressHUDWithText:[NSString stringWithFormat:@"%@成为了主讲", name]];
             return YES;
         }];
    
    if (self.room.loginUser.isTeacherOrAssistant
        && self.room.loginUser.noGroup) {
        [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyToUserID:allowed:success:)
                   filter:(BJLMethodObserver)^BOOL(NSString *userID, BOOL allowed, BOOL success) {
                       // bjl_strongify(self);
                       return allowed && !success;
                   }
                 observer:(BJLMethodObserver)^BOOL(NSString *userID, BOOL allowed, BOOL success) {
                     bjl_strongify(self);
                     [self showProgressHUDWithText:@"发言人数已满，请先关闭其他人音视频"];
                     return YES;
                 }];
    }
    
    if (!self.room.loginUser.isTeacher) {
        [self bjl_kvo:BJLMakeProperty(self.room, switchingRoom)
               filter:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return now.boolValue;
               }
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (self.room.switchingRoom) {
                     [self showProgressHUDWithText:@"切换教室中..."];
                     [self.overlayViewController hide];
                 }
                 return YES;
             }];
        
        [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, activeUsersSynced)
               filter:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return now.boolValue;
               }
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (!self.room.onlineUsersVM.onlineTeacher) {
                     [self showProgressHUDWithText:@"老师未在教室"];
                 }
                 return YES;
             }];
        [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineTeacher)
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
               filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                   bjl_strongify(self);
                   // activeUsersSynced 为 NO 时的变化无意义
                   return self.room.onlineUsersVM.activeUsersSynced && !!old != !!now;
               }
             observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 [self showProgressHUDWithText:now ? @"老师进入教室" : @"老师离开教室"];
                 return YES;
             }];
        
        [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return old.boolValue != now.boolValue;
               }
             observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 [self showProgressHUDWithText:now.boolValue ? @"上课啦" : @"下课啦"];
                 return YES;
             }];
        
        [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingUserDidUpdate:old:)
                 observer:(BJLMethodFilter)^BOOL(BJLMediaUser * _Nullable now, BJLMediaUser * _Nullable old) {
                     bjl_strongify(self);
                     if (now.isTeacher) {
                         BOOL audioChanged = (now.audioOn != old.audioOn
                                              && now.mediaSource == BJLMediaSource_mainCamera);
                         BOOL videoChanged = (now.videoOn != old.videoOn);
                         
                         NSString *videoTitle = BJLVideoTitleWithMediaSource(now.mediaSource);
                         if (audioChanged && videoChanged) {
                             if (now.audioOn && now.videoOn) {
                                 [self showProgressHUDWithText:[NSString stringWithFormat:@"老师开启了麦克风和%@", videoTitle]];
                             }
                             else if (now.audioOn) {
                                 [self showProgressHUDWithText:@"老师开启了麦克风"];
                             }
                             else if (now.videoOn) {
                                 [self showProgressHUDWithText:[NSString stringWithFormat:@"老师开启了%@", videoTitle]];
                             }
                             else {
                                 [self showProgressHUDWithText:[NSString stringWithFormat:@"老师关闭了麦克风和%@", videoTitle]];
                             }
                         }
                         else if (audioChanged) {
                             if (now.audioOn) {
                                 [self showProgressHUDWithText:@"老师开启了麦克风"];
                             }
                             else {
                                 [self showProgressHUDWithText:@"老师关闭了麦克风"];
                             }
                         }
                         else { // videoChanged
                             if (now.videoOn
                                 || (now.mediaSource == BJLMediaSource_mediaFile
                                     && old.mediaSource != BJLMediaSource_mediaFile)) {
                                 [self showProgressHUDWithText:[NSString stringWithFormat:@"老师开启了%@", videoTitle]];
                             }
                             else {
                                 [self showProgressHUDWithText:[NSString stringWithFormat:@"老师关闭了%@", videoTitle]];
                             }
                         }
                     }
                     return YES;
                 }];
        
        [self bjl_observe:BJLMakeMethod(self.room.speakingRequestVM, speakingRequestDidReplyEnabled:isUserCancelled:user:)
                 observer:(BJLMethodObserver)^BOOL(BOOL speakingEnabled, BOOL isUserCancelled, BJLUser *user) {
                     bjl_strongify(self);
                     if ([user.ID isEqualToString:self.room.loginUser.ID]
                         && !isUserCancelled) {
                         [self showProgressHUDWithText:(speakingEnabled
                                                        ? @"老师同意发言，已进入发言状态"
                                                        : @"稍等一下，一会请你回答")];
                     }
                     return YES;
                 }];
        [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingRequestTimeRemaining)
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
               filter:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return old.doubleValue > 0.0 && timeRemaining.doubleValue <= 0.0;
               }
             observer:^BOOL(NSNumber * _Nullable timeRemaining, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 if (timeRemaining.doubleValue == 0.0) { // reset: - 1.0
                     [self showProgressHUDWithText:@"老师未同意发言，请稍后再试"];
                 }
                 return YES;
             }];
        
        // 上麦失败的提示
        [self bjl_observe:BJLMakeMethod(self.room.recordingVM, recordingDidDeny)
                 observer:^BOOL {
                     bjl_strongify(self);
                     [self showProgressHUDWithText:@"服务器拒绝发布音视频，音视频并发已达上限"];
                     return YES;
                 }];
        
        // 老师强制上麦失败的提示
        if (self.room.loginUser.isTeacher) {
            [self bjl_observe:BJLMakeMethod(self.room.recordingVM, remoteChangeRecordingDidDenyForUser:)
                     observer:^BOOL(BJLUser *user) {
                         bjl_strongify(self);
                         [self showProgressHUDWithText:[NSString stringWithFormat:@"服务器拒绝强制 %@ 发言，音视频并发已达上限", user.displayName]];
                         return YES;
                     }];
        }
        
        [self bjl_kvo:BJLMakeProperty(self.room.recordingVM, forbidAllRecordingAudio)
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return now.boolValue != old.boolValue;
               }
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 [self showProgressHUDWithText:now.boolValue ? @"老师禁止打开麦克风" : @"老师允许打开麦克风"];
                 return YES;
             }];
        
        [self bjl_observe:BJLMakeMethod(self.room.recordingVM, recordingDidRemoteChangedRecordingAudio:recordingVideo:recordingAudioChanged:recordingVideoChanged:)
                 observer:(BJLMethodObserver)^BOOL(BOOL recordingAudio, BOOL recordingVideo, BOOL recordingAudioChanged, BOOL recordingVideoChanged) {
                     bjl_strongify(self);
                     NSString *actionMessage = nil;
                     if (recordingAudioChanged && recordingVideoChanged) {
                         if (recordingAudio == recordingVideo) {
                             actionMessage = recordingAudio ? @"老师开启了你的麦克风和摄像头" : @"老师结束了你的发言"/* @"老师关闭了你的麦克风和摄像头" */;
                         }
                         else {
                             actionMessage = recordingAudio ? @"老师开启了你的麦克风" : @"老师开启了你的摄像头"; // 同时关闭了你的摄像头/麦克风
                         }
                     }
                     else if (recordingAudioChanged) {
                         actionMessage = recordingAudio ? @"老师开启了你的麦克风" : @"老师关闭了你的麦克风";
                     }
                     else if (recordingVideoChanged) {
                         actionMessage = recordingVideo ? @"老师开启了你的摄像头" : @"老师关闭了你的摄像头";
                     }
                     BOOL wasSpeakingEnabled = (recordingAudioChanged ? !recordingAudio : recordingAudio
                                                || recordingVideoChanged ? !recordingVideo : recordingVideo);
                     BOOL isSpeakingEnabled = (recordingAudio || recordingVideo);
                     if (!wasSpeakingEnabled && isSpeakingEnabled) {
                         UIAlertController *alert = [UIAlertController
                                                     bjl_lightAlertControllerWithTitle:[NSString stringWithFormat:@"%@，现在可以发言了", actionMessage]
                                                     message:nil
                                                     preferredStyle:UIAlertControllerStyleAlert];
                         [alert bjl_addActionWithTitle:@"知道了"
                                                 style:UIAlertActionStyleCancel
                                               handler:nil];
                         if (self.presentedViewController) {
                             [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                         }
                         [self presentViewController:alert
                                            animated:YES
                                          completion:nil];
                     }
                     else if (actionMessage) {
                         [self showProgressHUDWithText:actionMessage];
                         if (wasSpeakingEnabled && !isSpeakingEnabled) {
                             [self.room.drawingVM updateDrawingEnabled:NO];
                         }
                     }
                     return YES;
                 }];
        
        [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidMe)
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return now.boolValue != old.boolValue;
               }
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 [self showProgressHUDWithText:(now.boolValue
                                                ? @"你已被禁言"
                                                : @"你已被解除禁言")];
                 return YES;
             }];
        [self bjl_kvo:BJLMakeProperty(self.room.chatVM, forbidAll)
               filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                   // bjl_strongify(self);
                   return now.boolValue != old.boolValue;
               }
             observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                 bjl_strongify(self);
                 [self showProgressHUDWithText:(now.boolValue
                                                ? @"老师开启了全体禁言"
                                                : @"老师关闭了全体禁言")];
                 return YES;
             }];
        
        if (!self.room.loginUser.isTeacherOrAssistant
            && !self.room.featureConfig.disableGrantDrawing) {
            [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingGranted)
             // options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                   filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                       // bjl_strongify(self);
                       return now.boolValue != old.boolValue;
                   }
                 observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
                     bjl_strongify(self);
                     [self showProgressHUDWithText:(now.boolValue
                                                    ? @"老师开启了你的画笔权限"
                                                    : @"老师取消了你的画笔权限")];
                     return YES;
                 }];
        }
    }
}

- (void)makeObservingForLoadingVideo {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.previewsViewController, fullScreenDidStartLoadingVideo:)
             observer:(BJLMethodObserver)^BOOL(CGFloat angle) {
                 bjl_strongify(self);
                 [self updateLoadingViewHidden:NO angle:angle];
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.previewsViewController, fullScreenDidFinishLoadingVideo)
             observer:^BOOL{
                 bjl_strongify(self);
                 [self updateLoadingViewHidden:YES angle:0.0];
                 return YES;
             }];
}

- (void)makeObservingForLikeEffect {
    bjl_weakify(self);
    // 收到点赞
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveLikeForUserNumber:records:)
             observer:^BOOL(NSString *userNumber, NSDictionary<NSString *, NSNumber *> *records) {
                 bjl_strongify(self);
                 NSString *name = @"";
                 for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
                     if ([user.number isEqualToString:userNumber]) {
                         name = user.displayName;
                         break;
                     }
                 }
                 if (name.length) {
                     BJLLikeEffectViewController *vc = [[BJLLikeEffectViewController alloc] initWithName:name];
                     [self bjl_addChildViewController:vc];
                 }
                 return YES;
             }];
    /*
    // 清空点赞
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return old.boolValue != now.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self.room.roomVM.liveStarted) {
                 [self.previewsViewController clearAllLikeRecord];
             }
             return YES;
         }];
     */
}

- (void)makeObservingForEnvelope {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didStartEnvelopRainWithID:duration:)
             observer:^BOOL(NSInteger envelopID, NSInteger duration){
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 if (self.rainEffectViewController) {
                     // 只存在一个
                     [self.rainEffectViewController bjl_removeFromParentViewControllerAndSuperiew];
                     self.rainEffectViewController = nil;
                 }
                 [self.view endEditing:YES];
                 CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
                 CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                 CGFloat width = screenWidth > screenHeight ? screenWidth : screenHeight;
                 CGSize size = CGSizeMake(width, width);
                 NSInteger rainCount = 30;
                 BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
                 CGSize rainSize = iPad ? CGSizeMake(88.0, 176.0) : CGSizeMake(64.0, 128.0);
                 self.rainEffectViewController = [[BJLRainEffectViewController alloc] initWithRoom:self.room envelopeID:envelopID duration:duration];
                 [self.rainEffectViewController setupRainEffectSize:size rainImageName:nil rainCount:rainCount rainSize:rainSize];
                 [self.rainEffectViewController setOpenEnvelopeImageName:nil emptyImageName:nil size:rainSize emptySize:rainSize];
                 [self bjl_addChildViewController:self.rainEffectViewController superview:self.view];
                 [self.rainEffectViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                     make.edges.equalTo(self.view);
                 }];
                 return YES;
             }];
}

- (void)makeObservingForQuestion {
    bjl_weakify(self);
    [self bjl_observeMerge:@[BJLMakeMethod(self.room.roomVM, didPublishQuestion:),
                             BJLMakeMethod(self.room.roomVM, didReplyQuestion:)]
                  observer:^(BJLQuestion *question){
                      bjl_strongify(self);
                      BOOL enableQuestion = self.room.featureConfig.enableQuestion && [self.room.roomInfo.environmentName isEqualToString:@"pro"];
                      if (enableQuestion) {
                          // 收到新发布的问答时，没有加载过问答界面，问答界面不在主窗口，问答界面被隐藏的时候，显示红点
                          self.controlsViewController.questionRedDot.hidden = self.questionViewController.isViewLoaded && self.questionViewController.view.window && !self.questionViewController.view.hidden;
                      }
                  }];
}

- (void)updateLoadingViewHidden:(BOOL)hidden angle:(CGFloat)angle {
    if (!self.videoLoadingView) {
        return;
    }
    if (self.videoLoadingView.hidden == hidden) {
        return;
    }
    self.videoLoadingView.hidden = hidden;
    if (!self.videoLoadingView.hidden) {
        // 显示旋转动画
        [self.videoLoadingView.layer removeAllAnimations];
        [self.videoLoadingImageView.layer removeAllAnimations];
        [self startAnimation:angle];
    }
    else {
        [self.videoLoadingView.layer removeAllAnimations];
        [self.videoLoadingImageView.layer removeAllAnimations];
    }
}

- (void)startAnimation:(CGFloat)angle {
    __block float nextAngle = angle + BJLVideoLoadingRotationAngleIncrement;
    CGAffineTransform endAngle = CGAffineTransformMakeRotation(angle * (M_PI / 180.0f));
    [UIView animateWithDuration:BJLVideoLoadingRotationDuration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        if (self.videoLoadingView && !self.videoLoadingView.hidden) {
            self.videoLoadingImageView.transform = endAngle;
        }
    } completion:^(BOOL finished) {
        if (finished && !self.videoLoadingView.hidden) {
            [self startAnimation:nextAngle];
        }
    }];
}

#pragma mark - 答题器

- (void)makeObservingForAnswerSheet {
    // 老师/助教身份 不监听答题器事件
    if (self.room.loginUser.isTeacherOrAssistant) {
        return;
    }
    
    bjl_weakify(self);
    // 答题开始
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionAnswerSheet:)
             observer:^BOOL(BJLAnswerSheet *answerSheet) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 [self clearAnswerSheet];
                 self.lastAnswerSheet = [answerSheet copy];
                 self.answerSheetViewController = [[BJLAnswerSheetViewController alloc] initWithAnswerSheet:answerSheet];
                 // 答题结束回调：return YES 表示提交成功，答题器将自动关闭
                 [self.answerSheetViewController setSubmitCallback:^BOOL(BJLAnswerSheet * _Nullable result) {
                     bjl_strongify(self);
                     if (!result) {
                         return NO;
                     }
                     
                     BJLError *error = [self.room.roomVM submitQuestionAnswer:result];
                     if (error) {
                         [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                         return NO;
                     }
                     self.lastAnswerSheet = result;
                     return YES;
                 }];
                 
                 // 答题器关闭回调
                 [self.answerSheetViewController setCloseCallback:^{
                     bjl_strongify(self);
                     [self clearAnswerSheet];
                 }];
                 
                 [self showProgressHUDWithText:@"答题开始"];
                 [self showAnswerSheet];
                 return YES;
             }];
    
    // 答题结束
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveEndQuestionAnswerWithEndTime:)
             observer:(BJLMethodObserver)^BOOL(NSTimeInterval endTimeInterval) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 [self showProgressHUDWithText:@"答题已结束"];
                 [self clearAnswerSheet];
                 [self clearAnswerSheetResult];
                 
                 if (self.lastAnswerSheet && self.lastAnswerSheet.shouldShowCorrectAnswer) {
                     self.answerSheetResultViewController = [[BJLAnswerSHeetResultViewController alloc] initWithAnswerSheet:self.lastAnswerSheet];
                     
                     // 答题器结果关闭回调
                     [self.answerSheetResultViewController setCloseCallback:^{
                         bjl_strongify(self);
                         [self clearAnswerSheetResult];
                     }];
                     [self showAnswerSheetResult];
                 }
                 return YES;
             }];
    
    // 兼容撤回信令
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeQuestionAnswerWithEndTime:)
             observer:(BJLMethodObserver)^BOOL(NSTimeInterval endTimeInterval) {
                 bjl_strongify(self);
                 if (self.room.loginUser.isAudition) {
                     return YES;
                 }
                 [self showProgressHUDWithText:@"答题已结束"];
                 [self clearAnswerSheet];
                 [self clearAnswerSheetResult];
                 return YES;
             }];

    // 监听到老师不在教室，关闭答题
    [self bjl_kvo:BJLMakeProperty(self.room.onlineUsersVM, onlineTeacher)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.loginUser.isAudition) {
                 return YES;
             }
             if (!now) {
                 [self clearAnswerSheet];
             }
             return YES;
        }];
}

- (void)showAnswerSheet {
    if (!self.answerSheetViewController) {
        return;
    }
    self.overlayViewController.tapBackgroundToHide = NO;
    [self.overlayViewController showWithContentViewController:self.answerSheetViewController
                                                     horEdges:UIRectEdgeAll
                                                      horSize:CGSizeZero
                                                     verEdges:UIRectEdgeAll
                                                      verSize:CGSizeZero];
}

- (void)clearAnswerSheet {
    if (!self.answerSheetViewController) {
        return;
    }
    
    [self.overlayViewController hide];
    self.answerSheetViewController = nil;
    
    if (self.answerSheetResultViewController) {
        self.answerSheetResultViewController = nil;
    }
}

- (void)showAnswerSheetResult {
    if (!self.answerSheetResultViewController) {
        return;
    }
    
    self.overlayViewController.tapBackgroundToHide = NO;
    [self.overlayViewController showWithContentViewController:self.answerSheetResultViewController
                                                     horEdges:UIRectEdgeAll
                                                      horSize:CGSizeZero
                                                     verEdges:UIRectEdgeAll
                                                      verSize:CGSizeZero];
}

- (void)clearAnswerSheetResult {
    if (!self.answerSheetResultViewController) {
        return;
    }
    
    [self.overlayViewController hide];
    self.answerSheetResultViewController = nil;
    self.lastAnswerSheet = nil;
}

#pragma mark - 计时器

- (void)makeObservingForCountDownTimer {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveStopTimer) observer:^BOOL{
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (!self.countDownViewController) {
            return YES;
        }
        
        [self.countDownViewController bjl_removeFromParentViewControllerAndSuperiew];
        self.countDownViewController = nil;
        
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveTimerWithTotalTime:countDownTime:isDecrease:) observer:(BJLMethodObserver)^BOOL (NSInteger totalTime, NSInteger countDownTime, BOOL isDecrease){
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        if (self.countDownViewController) {
            return YES;
        }

        self.countDownViewController = [[BJLCountDownViewController alloc] initWithRoom:self.room
                                                                              totalTime:MAX(0, totalTime)
                                                                   currentCountDownTime:countDownTime
                                                                             isDecrease:isDecrease];
        
        [self.countDownViewController setCloseCallback:^(){
            bjl_strongify(self);
            if (!self.countDownViewController) {
                return;
            }
            if (self.room.loginUser.isTeacher) {
                BJLError *error = [self.room.roomVM requestStopTimer];
                if (error) {
                    [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                }
                return;
            }

            [self.countDownViewController bjl_removeFromParentViewControllerAndSuperiew];
            self.countDownViewController = nil;
        }];

        [self.countDownViewController setErrorCallback:^(NSString * message){
            bjl_strongify(self);
            if (message.length) {
                [self showProgressHUDWithText:message];
            }
        }];
        
        [self.countDownViewController setPublishCountDownTimerCallback:^(NSInteger totalTime, NSInteger currentCountDownTime, BOOL isDecrease) {
            bjl_strongify(self);
            BJLError *error = [self.room.roomVM requestPublishTimerWithTotalTime:totalTime countDownTime:currentCountDownTime isDecrease:isDecrease];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                return NO;
            }
            return YES;
        }];
        [self.countDownViewController setPauseCountDownTimerCallback:^{
            bjl_strongify(self);
            BJLError *error = [self.room.roomVM requestPauseTimer];
            if (error) {
                [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
                return NO;
            }
            return YES;
        }];
        [self bjl_addChildViewController:self.countDownViewController superview:self.timerView];
        [self.countDownViewController.view bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.timerView);
        }];
        return YES;
    }];

}
#pragma mark - weak network

- (void)makeObservingForLossRate {
    self.lossRateDictionary = [NSMutableDictionary new];
    self.presenterLossRateDictionary = [NSMutableDictionary new];
    [self restartLossRateObservingTimer];
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, mediaLossRateDidUpdateWithUser:videoLossRate:audioLossRate:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat videoLossRate, CGFloat audioLossRate){
                 bjl_strongify(self);
                 // 目前只统计所有用户主摄流的丢包
                 if (user.mediaSource != BJLMediaSource_mainCamera) {
                     return YES;
                 }
                 
                 // 记录每个用户不同时间的丢包率数据
                 NSString *userKey = [self userLossRateKeyWithUserID:user.ID mediaSource:user.mediaSource];
                 CGFloat packageLossRate = MIN(MAX(0.0, videoLossRate), 100.0);
                 
                 // 尝试舍弃丢包100%的情况, 防止webrtc正常网络下偶现丢包100%, 导致app弹框强提示. 如果网络实际丢包持续到达100%, 那么上层信令服务器应该已经断开了
                 if(packageLossRate == 100) {
                     return YES;
                 }
                 
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

    [self bjl_observe:BJLMakeMethod(self.room, roomWillExitWithError:)
             observer:^BOOL{
                 bjl_strongify(self);
                 [self stopLossRateObservingTimer];
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
        /* 是否是弱网
         每个用户单独计算M秒内平均丢包率：
         自己上行有丢包时, 在自己的界面提示/直播间界面提示;
         自己下行有丢包时, ((有上行丢包&下行丢包低于上行2倍) || 无上行)->提示自己网络差, (有上行&&上行无丢包) || 下行丢包高于上行丢包2倍 -> 对方网络差
         */
        NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];

        NSString *userKey = [self userLossRateKeyWithUserID:self.room.loginUser.ID mediaSource:BJLMediaSource_mainCamera];
        NSMutableArray<NSDictionary *> *loginUserLossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
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
            [self.lossRateDictionary bjl_setObject:loginUserLossRateArray forKey:userKey];
        }
        BJLNetworkStatus loginUserLossRateStatus = [self netWorkStatusWithLossRate:loginUserLossRate];

        BOOL hasUpLink = self.room.recordingVM.recordingAudio || self.room.recordingVM.recordingVideo;
        BOOL hasUpPackageLoss = hasUpLink && loginUserLossRateStatus != BJLNetworkStatus_normal;

        //判断当前自己下行是否有丢包
        for (NSString *userKey in [self.lossRateDictionary.allKeys copy]) {
            NSString *userID = [self userIDForUserLossRateKey:userKey];
            if([userID isEqualToString:self.room.loginUser.ID]) {
                continue;
            }
            NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
            NSInteger count = lossRateArray.count;
            
            if (count > 0) {
                CGFloat totalLossRate = 0.0f;
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
                // 超过边界认为是弱网
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
                        loginUserLossRateStatus = status;
                        [self updateNetWorkStatus:loginUserLossRateStatus userID:self.room.loginUser.ID];
                        break;
                    }
                    else if((BJLNetworkStatus_normal != status && BJLNetworkStatus_normal != presenterLossRateStatus && lossRate <= presenterLossRate * 2 )) {
//                        主讲窗口
                        [self updateNetWorkStatus:loginUserLossRateStatus userID:userID];
                    }
                }
                else if((status != BJLNetworkStatus_normal && !hasUpLink)
                   || (hasUpPackageLoss && lossRate <= loginUserLossRate * 2 && status != BJLNetworkStatus_normal)) {
                    loginUserLossRateStatus = hasUpPackageLoss ? loginUserLossRateStatus : status;
                    [self updateNetWorkStatus:loginUserLossRateStatus userID:self.room.loginUser.ID];
                    break;
                }
                else if((status != BJLNetworkStatus_normal && !hasUpPackageLoss)
                       || (status != BJLNetworkStatus_normal && loginUserLossRateStatus != BJLNetworkStatus_normal && lossRate > loginUserLossRate * 2)) {
                        // 他人窗口提示弱网
                    [self updateNetWorkStatus:loginUserLossRateStatus userID:userID];
                }
            }
        }
    }];
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

- (void)updateNetWorkStatus:(BJLNetworkStatus)status userID:(NSString *)userID {
    if(self.contentView.item.type == BJLPreviewsType_recording
       && [self.contentView.item.loginUser.ID isEqualToString:userID]) {
        [self.contentView updateViewWithNetWorkLossRateStatus:status];
    }
    else if(self.contentView.item.type == BJLPreviewsType_playing
            && [self.contentView.item.playingUser.ID isEqualToString:userID]
            && self.contentView.item.playingUser.mediaSource == BJLMediaSource_mainCamera) {
        [self.contentView updateViewWithNetWorkLossRateStatus:status];
    }

    if(status == BJLNetworkStatus_Bad_level4 || status == BJLNetworkStatus_Bad_level5) {
        [self showProgressHUDWithText:@"您的网络情况极差"];
    }
    
    /*
     由于目前丢包率不稳定, 容易瞬时达到峰值, 暂时先注释掉弹框提示
    if(status == BJLNetworkStatus_Bad_level5) {
        UIAlertController *alert = [UIAlertController
                                    bjl_lightAlertControllerWithTitle:@"提示"
                                    message:@"哎呀，您的网络开小差了，检测网络后重新进入教室"
                                    preferredStyle:UIAlertControllerStyleAlert];
        bjl_weakify(self);
        [alert bjl_addActionWithTitle:@"好的"
                                style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * _Nonnull action) {
                                  bjl_strongify(self);
                                  [self exit];
                              }];
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self presentViewController:alert animated:YES completion:nil];
    }
     */
}

- (NSString *)userLossRateKeyWithUserID:(NSString *)userID mediaSource:(BJLMediaSource)mediaSource {
    return [NSString stringWithFormat:@"%@-%td", userID, mediaSource];
}

- (BJLMediaSource)mediaSourceForUserLossRateKey:(NSString *)key {
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


@end

NS_ASSUME_NONNULL_END
