//
//  BJLScRoomViewController+private.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController.h"
#import "BJLScRoomViewController+constraints.h"
#import "BJLScRoomViewController+observing.h"
#import "BJLScRoomViewController+actions.h"
#import "BJLScAppearance.h"
#import "BJLScTopBarViewController.h"
#import "BJLScVideosViewController.h"
#import "BJLScMediaInfoView.h"
#import "BJLScVideoPlaceholderView.h"
#import "BJLScOverlayViewController.h"
#import "BJLScPPTManagerViewController.h"
#import "BJLScPPTQuickSlideViewController.h"
#import "BJLScToolView.h"
#import "BJLScSegmentViewController.h"
#import "BJLScUserViewController.h"
#import "BJLScChatViewController.h"
#import "BJLScSettingsViewController.h"
#import "BJLScNoticeViewController.h"
#import "BJLScNoticeEditViewController.h"
#import "BJLScSpeakRequestUsersViewController.h"
#import "BJLScChatInputViewController.h"
#import "BJLScQuestionInputViewController.h"
#import "BJLAnnularProgressView.h"
#import "BJLScLoadingViewController.h"
#import "BJLRainEffectViewController.h"
#import "BJLScQuizWebViewController.h"
#import "BJLScAnswerSheetViewController.h"
#import "BJLScAnswerSheetResultViewController.h"
#import "BJLScCountDownViewController.h"
#import "BJLScEvaluationViewController.h"
#import "BJLScCountDownEditViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScRoomViewController ()

@property (nonatomic) CGRect keyboardFrame;
@property (nonatomic, nullable) BJLProgressHUD *prevHUD;
@property (nonatomic, nullable) BJLAFNetworkReachabilityManager *reachability;
@property (nonatomic) NSMutableSet *autoPlayVideoBlacklist;
@property (nonatomic) BJLScWindowType majorWindowType; // 大屏可以是任意类型
@property (nonatomic) BJLScWindowType minorWindowType; // 小屏只能是 BJLScWindowType_ppt 或 BJLScWindowType_teacherVideo
@property (nonatomic, readonly) BOOL is1V1Class;

@property (nonatomic) UIView *containerView;
@property (nonatomic) UIView *topBarView;
@property (nonatomic) UIView *majorContentView, *minorContentView, *secondMinorContentView;
@property (nonatomic) UIView *videosView;
@property (nonatomic) UIView *segmentView;
@property (nonatomic) BJLHitTestView *toolView;
@property (nonatomic) BJLHitTestView *lampView;// 跑马灯
@property (nonatomic) BJLHitTestView *imageViewLayer;// 聊天图片
@property (nonatomic) BJLHitTestView *timerLayer;// 计时器工具放在其他教具下层
@property (nonatomic) BJLHitTestView *teachAidLayer;// 答题器之类工具
@property (nonatomic) BJLHitTestView *overlayView;// 设置，公告之类的1/2页面
@property (nonatomic) BJLHitTestView *loadingLayer; // 保持在最上层

@property (nonatomic) BJLScTopBarViewController *topBarViewController;
@property (nonatomic) BJLScVideosViewController *videosViewController;
@property (nonatomic, nullable) BJLScMediaInfoView *teacherMediaInfoView, *teacherExtraMediaInfoView, *secondMinorMediaInfoView;
@property (nonatomic) BJLScVideoPlaceholderView *teacherVideoPlaceholderView, *secondMinorVideoPlaceholderView;
@property (nonatomic) BJLScSegmentViewController *segmentViewController;
@property (nonatomic) BJLScPPTManagerViewController *pptManagerViewController;
@property (nonatomic) BJLScPPTQuickSlideViewController *pptQuickSlideViewController;
@property (nonatomic) BJLScOverlayViewController *overlayViewController;
@property (nonatomic) BJLScToolView *documentToolView;
@property (nonatomic) UIButton *handUpButton, *videoButton, *audioButton;
@property (nonatomic) UIButton *noticeButton, *questionButton, *changeScreenButton, *opertionScreenBtn;
@property (nonatomic) BOOL controlsHidden, documentToolHidden, questionRedDotHidden; // 状态和视图实际的状态保持一致
@property (nonatomic) UILabel *userSpeakRequestRedDot, *questionRedDot;
@property (nonatomic) BJLAnnularProgressView *handProgressView;
@property (nonatomic) UIButton *liveStartButton;

@property (nonatomic) BJLScLoadingViewController *loadingViewController;
@property (nonatomic) BJLScSettingsViewController *settingsViewController;
@property (nonatomic) BJLScNoticeViewController *noticeViewController;
@property (nonatomic) BJLScNoticeEditViewController *noticeEditViewController;
@property (nonatomic) BJLScQuestionViewController *questionViewController;
@property (nonatomic) BJLScSpeakRequestUsersViewController *speakRequestUsersViewController;
@property (nonatomic) BJLScChatInputViewController *chatInputViewController;
@property (nonatomic) BJLScQuestionInputViewController *questionInputViewController;

@property (nonatomic, nullable) BJLRainEffectViewController *rainEffectViewController;
@property (nonatomic, nullable) BJLScQuizWebViewController *quizWebViewController;
@property (nonatomic, nullable) BJLScAnswerSheetViewController *answerSheetViewController;
@property (nonatomic, nullable) BJLScAnswerSheetResultViewController *answerSheetResultViewController;
@property (nonatomic, nullable) BJLAnswerSheet *lastAnswerSheet;

@property (nonatomic, nullable) BJLScCountDownViewController *countDownViewController;
@property (nonatomic, nullable) BJLScCountDownEditViewController *countDownEditViewController;

@property (nonatomic, nullable) BJLScEvaluationViewController *evaluationViewController;

// only for 1v1
@property (nonatomic) UIView *seperatorView;
@property (nonatomic) BJLScChatViewController *chatViewController;
@property (nonatomic) UIButton *chatButton;
@property (nonatomic) UILabel *chatRedDot;

- (void)autoStartRecordingAudioAndVideoForce:(BOOL)force;
- (void)updateVideosConstraintsWithCurrentPlayingUsers;
- (void)showProgressHUDWithText:(NSString *)text;
- (void)roomDidExitWithError:(BJLError *)error;
- (NSString *)videoKeyForUser:(BJLMediaUser *)user;

@end

NS_ASSUME_NONNULL_END
