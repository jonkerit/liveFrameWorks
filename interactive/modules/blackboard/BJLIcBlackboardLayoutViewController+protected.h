//
//  BJLIcBlackboardLayoutViewController+protected.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcBlackboardLayoutViewController.h"
#import "BJLIcUserVideoListViewController.h"
#import "BJLIcVideosGridLayoutViewController.h"
#import "BJLIcAppearance.h"
#import "BJLAppearance.h"
#import "BJLIcLaserPointView.h"
#import "BJLIcDocumentWindowViewController.h"
#import "BJLIcVideoWindowViewController.h"
#import "BJLIcWritingBoradWindowViewController.h"
#import "BJLIcWebViewWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController () <UIScrollViewDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic, readwrite) UIView *blackboardView;
@property (nonatomic) UIButton *prevStepButton, *nextStepButton;
@property (nonatomic, weak) UIViewController *fullscreenParentViewController;
@property (nonatomic, weak) UIView *fullscreenSuperview;
@property (nonatomic) UIView *documentWindowsView;
@property (nonatomic) UIView *webDocumentWindowsView;
@property (nonatomic) UIView *webviewWindowsView;
@property (nonatomic) BJLIcLaserPointView *laserPointView;
@property (nonatomic) UIPanGestureRecognizer *touchMoveGesture;

#pragma mark - document

@property (nonatomic) UILabel *pageNumberLabel;
@property (nonatomic) NSMutableDictionary<NSString *, BJLIcDocumentWindowViewController *> *displayingDocumentWindows;
@property (nonatomic, readwrite) NSArray<BJLWindowDisplayInfo *> *documentWindowDisplayInfos;
@property (nonatomic) NSMutableArray<BJLWindowDisplayInfo *> *mutableDocumentWindowDisplayInfos;
@property (nonatomic, nullable) BJLIcDocumentWindowViewController *topDocumentWindowController; // 屏幕最表层的文档窗口，用于添加激光笔视图
@property (nonatomic, nullable) UIButton *pptRemarkInfoButton;

@property (nonatomic) NSMutableDictionary<NSString *, BJLIcWebDocumentWindowViewController *> *displayingWebDocumentWindows;
@property (nonatomic, readwrite) NSArray<BJLWindowDisplayInfo *> *webDocumentWindowDisplayInfos;
@property (nonatomic) NSMutableArray<BJLWindowDisplayInfo *> *mutableWebDocumentWindowDisplayInfos;

- (void)closeDisplayingDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate;
- (void)closeDisplayingDocumentWindowsWithRequestUpdate:(BOOL)requestUpdate;

- (void)closeDisplayingWebDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate;
- (void)closeDisplayingWebDocumentWindowsWithRequestUpdate:(BOOL)requestUpdate;

- (BJLIcWebViewWindowViewController *)displayWebViewWindowWithURLString:(nullable NSString *)urlString layout:(BJLIcWebViewWindowLayout)layout;

#pragma mark - video

@property (nonatomic) UIButton *audioFileButton;
@property (nonatomic) UIView *videoWindowsView;
@property (nonatomic) UIView *alwaysMaximizeVideoWindowsView;
@property (nonatomic) BJLIcUserVideoListViewController *videoListViewController;
@property (nonatomic, nullable) BJLIcVideosGridLayoutViewController *videosGridViewController;
@property (nonatomic) NSMutableDictionary<NSString *, BJLIcVideoWindowViewController *> *displayingVideoWindows;
@property (nonatomic, readwrite) NSArray<BJLWindowDisplayInfo *> *videoWindowDisplayInfos;
@property (nonatomic) NSMutableArray<BJLWindowDisplayInfo *> *mutableVideoWindowDisplayInfos;

#pragma mark - writingBoard

@property (nonatomic) UIView *writingBoardWindowsView;
/** 用户自己的作答窗口, 或者老师的出题窗口, 由于信息不用共享, 所以此窗口信息不会被包含在下面的窗口信息array中 */
@property (nonatomic, nullable) BJLIcWritingBoradWindowViewController *writingBoardViewController;
@property (nonatomic) NSMutableDictionary<NSString *, BJLIcWritingBoradWindowViewController *> *displayingWritingBoardWindows;
@property (nonatomic) NSArray<BJLWindowDisplayInfo *> *writingBoardWindowDisplayInfos;
@property (nonatomic) NSMutableArray<BJLWindowDisplayInfo *> *mutableWritingBoardWindowDisplayInfos;

- (__kindof UIViewController *)displayWritingBoardWindowWith:(BJLWritingBoard *)writingBoard
                                                  userNumber:(NSString *)userNumber
                                               requestUpdate:(BOOL)requestUpdate;

- (void)closeDisplayingWritingBoardWindowWithID:(NSString *)documentID
                                      pageIndex:(NSInteger)pageIndex
                                     userNumber:(NSString *)userNumber
                                  requestUpdate:(BOOL)requestUpdate;

- (void)closeDisplayingWritingBoardWindowsWithRequestUpdate:(BOOL)requestUpdate;

#pragma mark -

// 答题器，抢答器，倒计时 view，第一/二套模板中层级均为最高
@property (nonatomic) UIView *responderWindowView;

/** 老师/助教/学生打开倒计时 */
- (__kindof UIViewController *)displayCountDownWindowWithTime:(NSTimeInterval)time
                                                       layout:(BJLIcCountDownWindowLayout)layout;

//本次课节所有抢答记录
@property (nonatomic, nullable) NSArray<NSDictionary *> *questionResponderList;

/** 老师/助教打开一个抢答器窗口 */
- (nullable __kindof UIViewController *)displayQuestionResponderWindowWithLayout:(BJLIcQuestionResponderWindowLayout)layout;

/** 学生打开抢答器页面 */
- (nullable __kindof UIViewController *)displayQuestionResponderWindowWithCountDownTime:(NSInteger)time;

/** 老师/助教打开答题器 */
- (__kindof UIViewController *)displayQuestionAnswerWindowWithAnswerSheet:(BJLAnswerSheet *)anwserSheet
                                                                   layout:(BJLIcQuestionAnswerWindowLayout)layout;

/** 学生打开答题器页面 */
- (__kindof UIViewController *)displayQuestionAnswerWindowWithAnswerSheet:(BJLAnswerSheet *)anwserSheet;

@end

NS_ASSUME_NONNULL_END
