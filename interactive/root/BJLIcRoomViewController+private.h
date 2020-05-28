//
//  BJLIcRoomViewController+private.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLAFNetworking.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcRoomViewController.h"

#import "BJLIcStatusBarViewController.h"
#import "BJLIcToolbarViewController.h"

#import "BJLIcBlackboardLayoutViewController.h"
#import "BJLIcVideosGridLayoutViewController.h"
#import "BJLIcLoadingViewController.h"
#import "BJLLikeEffectViewController.h"

#import "BJLIcToolboxViewController.h"
#import "BJLIcChatViewController.h"
#import "BJLIcUserViewController.h"
#import "BJLIcPromptViewController.h"

#import "BJLIcDocumentFileManagerViewController.h"
#import "BJLIcTeachingAidViewController.h"
#import "BJLIcDocumentFileDisplayListView.h"
#import "BJLIcUserOperateView.h"
#import "BJLAnnularProgressView.h"
#import "BJLIcExpressViewController.h"
#import "BJLIcEvaluationViewController.h"

NS_ASSUME_NONNULL_BEGIN

/*
typedef NS_ENUM(NSInteger, BJLIntClassViewLayer) {
    BJLIntClassViewLayer_layout,        // status bar + toolbar + blackboard/videosGrid
    BJLIntClassViewLayer_widget,        // users/chats + toolbox
    BJLIntClassViewLayer_settings,      // settings
    BJLIntClassViewLayer_fullscreen,    // fullscreen image/text
    BJLIntClassViewLayer_popovers       // menu, hud, loading, ...
};

typedef NS_ENUM(NSInteger, BJLIntClassLayoutType) {
    BJLIntClassLayoutType_blackboard,   // BJLIcBlackboardLayoutViewController
    BJLIntClassLayoutType_videosGrid    // BJLIcVideosGridLayoutViewController
};

typedef NS_ENUM(NSInteger, BJLIntClassBlackboardLayer) {
    BJLIntClassBlackboardLayer_blackboard,  // shapes, images
    BJLIntClassBlackboardLayer_documents,   // documents/max-document
    BJLIntClassBlackboardLayer_videos       // videos/max-video
}; // */

@interface BJLIcRoomViewController ()

@property (nonatomic) BJLRoomLayout currentRoomLayout;
@property (nonatomic, readonly) NSMutableSet *autoPlayVideoBlacklist;

@property (nonatomic, readonly) UIImageView *backgroundImageView; //配置小班课背景图片
@property (nonatomic, readonly) UIView *loadingLayer;
@property (nonatomic, nullable) UIView *overlayView;
@property (nonatomic, readonly) UIView *layoutLayer;
@property (nonatomic, readonly) UIView *lampView;

@property (nonatomic, readonly) UIView *statusBar, *toolbar, *layoutContainer;
@property (nonatomic, readonly) UIView *blackboardLayer, *videosLayer;
@property (nonatomic, readonly) BJLIcStatusBarViewController *statusBarViewController;
@property (nonatomic, readonly) BJLIcToolbarViewController *toolbarViewController;
@property (nonatomic, readonly) BJLIcBlackboardLayoutViewController *blackboardLayoutViewController;
@property (nonatomic, readonly) BJLIcVideosGridLayoutViewController *videosGridLayoutViewController;
@property (nonatomic, readonly) BJLIcLoadingViewController *loadingViewController;

@property (nonatomic, readonly) UIView *widgetLayer;
@property (nonatomic, readonly) UIView *widgetContainer, *toolbox;
@property (nonatomic, readonly) BJLIcToolboxViewController *toolboxViewController;
@property (nonatomic, readonly) BJLIcChatViewController *chatViewController;
@property (nonatomic, readonly) BJLIcUserViewController *userViewController;
@property (nonatomic, readonly) BJLIcPromptViewController *promptViewController;

@property (nonatomic, readonly) UIView *settingsLayer;

@property (nonatomic, readonly) UIView *fullscreenLayer;
@property (nonatomic, readonly) UIView *fullscreenToolboxLayer;
@property (nonatomic, readonly) BJLIcDocumentFileManagerViewController *documentFileManagerViewController;
@property (nonatomic, nullable) UIViewController *fileDisplayListViewController;
@property (nonatomic, readonly) BJLIcDocumentFileDisplayListView *documentFileDisplayListView;
@property (nonatomic, readonly) BJLIcTeachingAidViewController *teachingAidViewController;
@property (nonatomic, readonly) BJLIcExpressViewController *expressViewController;

@property (nonatomic, readonly) UIView *popoversLayer;
@property (nonatomic, nullable) BJLIcPopoverViewController *popoverViewController; // 用于关闭未点击但是需要关闭的弹窗

@property (nonatomic, nullable) BJLAFNetworkReachabilityManager *reachabilityManager;
@property (nonatomic) BOOL hasReload;
@property (nonatomic) BOOL recordingAudioBeforeReload, recordingVideoBeforeReload;

#pragma mark - speak in fullscreen

@property (nonatomic) UIButton *requestSpeakinFullScreenButton;

@property (nonatomic) BJLAnnularProgressView *speakRequestProgressView;

#pragma mark - weak network

// < userNumber, < time, loss rate > >
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *lossRateDictionary;
//主讲人丢包率
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *presenterLossRateDictionary;

@property (nonatomic, nullable) NSTimer *lossRateObservingTimer;
@property (nonatomic) BOOL hasShowVeryBadAlert;

- (void)showProgressHUDWithText:(NSString *)text;
- (void)clean;
- (void)exit;
- (void)dismissWithError:(nullable BJLError *)error;

@end

NS_ASSUME_NONNULL_END
