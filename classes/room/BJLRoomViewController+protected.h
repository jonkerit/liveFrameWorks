//
//  BJLRoomViewController+protected.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-01-19.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLAuthorization.h>

#import "BJLViewControllerImports.h"
#import "BJLRoomViewController.h"
#import "BJLRoomViewController+constraints.h"
#import "BJLRoomViewController+actions.h"
#import "BJLRoomViewController+observing.h"

#import "BJLContentView.h"
#import "BJLTopBarView.h"
#import "BJLPreviewsViewController.h"
#import "BJLControlsViewController.h"
#import "BJLChatViewController.h"
#import "BJLQuestionViewController.h"
#import "BJLUserListViewController.h"
#import "BJLPPTManageViewController.h"
#import "BJLPPTQuickSlideViewController.h"
#import "BJLChatInputViewController.h"
#import "BJLMoreViewController.h"
#import "BJLNoticeViewController.h"
#import "BJLNoticeEditViewController.h"
#import "BJLSettingsViewController.h"

#import "BJLImageViewController.h"
#import "BJLOverlayViewController.h"
#import "BJLLoadingViewController.h"

#import "BJLQuizWebViewController.h"
#import "BJLAnswerSheetViewController.h"
#import "BJLRainEffectViewController.h"
#import "BJLAnswerSHeetResultViewController.h"
#import "BJLUsersViewController.h"
#import "BJLCountDownViewController.h"
#import "BJLEvaluationViewController.h"

@class BJLAnswerSheet;

NS_ASSUME_NONNULL_BEGIN

/**
 @see /wiki/design.md
 */
@interface BJLRoomViewController () {
    BOOL _chatHidden, _controlsHidden;
}

@property (nonatomic, readonly) BJLContentView *contentView;
@property (nonatomic, readonly) UIView *backgroundView;
@property (nonatomic, readonly) BJLPreviewsViewController *previewsViewController;
@property (nonatomic, readonly) BJLControlsViewController *controlsViewController; // with chatVC and buttonsVC
@property (nonatomic, readonly) BJLChatInputViewController *chatInputViewController;
@property (nonatomic, readonly) UIButton *recordingStateView;
@property (nonatomic, readonly) BJLTopBarView *topBarView;
@property (nonatomic, readonly) BJLHitTestView *timerView;

@property (nonatomic, readonly) BJLUserListViewController *onlineGroupUsersViewController;
@property (nonatomic, readonly) BJLUsersViewController *onlineUsersViewController;
@property (nonatomic, readonly) BJLPPTManageViewController *pptManageViewController;
@property (nonatomic, readonly) BJLPPTQuickSlideViewController *pptQuickSlideViewController;

@property (nonatomic, readonly) BJLChatViewController *chatViewController;
@property (nonatomic, readonly) BJLQuestionViewController *questionViewController;

@property (nonatomic, readonly) BJLMoreViewController *moreViewController;
@property (nonatomic, readonly) BJLNoticeViewController *noticeViewController;
@property (nonatomic, readonly) BJLNoticeEditViewController *noticeEditViewController;
@property (nonatomic, readonly) BJLSettingsViewController *settingsViewController;

@property (nonatomic, readonly) BJLImageViewController *imageViewController;
@property (nonatomic, readonly) BJLOverlayViewController *overlayViewController;
@property (nonatomic, readonly) BJLLoadingViewController *loadingViewController;

@property (nonatomic, readonly) UIView *videoLoadingView;
@property (nonatomic, readonly) UIImageView *videoLoadingImageView;

@property (nonatomic, nullable) BJLQuizWebViewController *quizWebViewController;
@property (nonatomic, nullable) BJLAnswerSheetViewController *answerSheetViewController;
@property (nonatomic, nullable) BJLAnswerSHeetResultViewController *answerSheetResultViewController;
@property (nonatomic, nullable) BJLRainEffectViewController *rainEffectViewController;
@property (nonatomic, nullable) BJLCountDownViewController *countDownViewController;

@property (nonatomic, readonly) BOOL chatHidden, controlsHidden, previewBackgroundImageHidden; // NON-KVO
@property (nonatomic) BOOL contentAnimating;
@property (nonatomic) BOOL didUpdateVideoPlayingUser;
@property (nonatomic) UIScreenEdgePanGestureRecognizer *showGesture;
@property (nonatomic) UIPanGestureRecognizer *hideGesture;

@property (nonatomic, nullable) BJLAnswerSheet *lastAnswerSheet;

#pragma mark - weak network

// < userNumber, < time, loss rate > >
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *lossRateDictionary;
//主讲人丢包率
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *presenterLossRateDictionary;

@property (nonatomic, nullable) NSTimer *lossRateObservingTimer;

- (void)showProgressHUDWithText:(NSString *)text;
- (void)updateNetWorkTipHUDHidden:(BOOL)hidden;
- (void)updateLamp;

- (void)askToExit; // user wants exit
- (void)roomDidExitWithError:(BJLError *)error; // room did exit
- (void)dismissWithError:(nullable BJLError *)error; // do exit

@end

NS_ASSUME_NONNULL_END
