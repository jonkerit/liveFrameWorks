//
//  BJLIcRoomViewController+actions.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import "BJLIcRoomViewController.h"

#import "BJLIcStatusBarViewController.h"
#import "BJLIcToolbarViewController.h"

#import "BJLIcBlackboardLayoutViewController.h"
#import "BJLIcVideosGridLayoutViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcRoomViewController (actions)

- (void)makeActions;
#if DEBUG
- (void)makeDebugActions;
#endif

// 小黑板
- (void)requsetAddWritingBoard;
// 打开网页
- (void)openWebView;
// 计时器
- (void)openCountDown;
// 答题器
- (void)openQuestionAnswer;
// 抢答器
- (void)openQuestionResponder;
// 切换到画廊布局
- (void)switchToGalleryLayout;
// 切换板书布局
- (void)switchToBlackboardLayout;
- (void)enterCoursewareMode;
- (BOOL)updateRecordingAudio:(BOOL)on;
- (BOOL)updateRecordingVideo:(BOOL)on;
- (void)startCloudRecordingAfterCheckState;
- (BOOL)updateForbidSpeakRequest:(BOOL)forbid;
- (BOOL)updateRecordingAudio:(BOOL)audio recordingVideo:(BOOL)video;

@end

NS_ASSUME_NONNULL_END
