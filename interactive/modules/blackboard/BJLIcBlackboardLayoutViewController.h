//
//  BJLIcBlackboardLayoutViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcUserMediaInfoView.h"
#import "BJLIcVideoWindowViewController.h"
#import "BJLIcWebViewWindowViewController.h"
#import "BJLIcWebDocumentWindowViewController.h"
#import "BJLIcCountDownWindowViewController.h"
#import "BJLIcQuestionResponderWindowViewController.h"
#import "BJLIcStudentQuestionResponderViewController.h"
#import "BJLIcQuestionAnswerViewController.h"
#import "BJLIcStudentQuestionAnswerWindowViewController.h"
#import "BJLIcQuizWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcBlackboardLayoutViewController : UIViewController

@property (nonatomic, readonly) UIView *blackboardLayer, *videosLayer;
@property (nonatomic, readonly) NSArray<BJLWindowDisplayInfo *> *documentWindowDisplayInfos;
@property (nonatomic, readonly) NSArray<BJLWindowDisplayInfo *> *webDocumentWindowDisplayInfos;
@property (nonatomic, readonly) NSArray<BJLWindowDisplayInfo *> *videoWindowDisplayInfos;
@property (nonatomic, nullable) BJLIcUserMediaInfoView *(^updateTeacherMediaInfoViewCallback)(BOOL leaveSeat, NSString *mediaID);
@property (nonatomic, nullable) void (^receiveLikeCallback)(BJLUser *user, UIButton *button);
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);
@property (nonatomic, nullable) void (^updateVideoCallback)(BJLMediaUser *user, BOOL on);
@property (nonatomic, nullable) BOOL (^blockUserCallback)(BJLUser *user);
@property (nonatomic, nullable) void (^webviewControllerKeyboardFrameChangeCallback)(CGRect keyboardFrame, UIView *overlayView);
// 关闭网页
@property (nonatomic, nullable) void (^closeWebviewControllerCallback)(void);
// 关闭测验
@property (nonatomic, nullable) void (^closeQuizControllerCallback)(void);
@property (nonatomic, nullable) void (^cancelQuizControllerCallback)(void);
// 小黑板输入时间回调
@property (nonatomic, nullable) void (^showWritingBoardTimeInputViewControllerCallBack)(void);
// 关闭发布中的答题器二次确认回调
@property (nonatomic, nullable) void (^closeQuestionAnswerControllerCallback)(void);
// 抢答器成功抢答的动画回调
@property (nonatomic, nullable) void (^responderSuccessCallback)(BJLUser *user, UIButton *button);

// 网页
@property (nonatomic, nullable, weak) BJLIcWebViewWindowViewController *webViewWindowViewController;
// 测验
@property (nonatomic, nullable, weak) BJLIcQuizWindowViewController *quizViewController;
// 倒计时
@property (nonatomic, nullable, weak) BJLIcCountDownWindowViewController *countDownViewController;
// 老师和助教的抢答器窗口
@property (nonatomic, nullable, weak) BJLIcQuestionResponderWindowViewController *questionResponderViewController;
// 学生的抢答器窗口
@property (nonatomic, nullable, weak) BJLIcStudentQuestionResponderViewController *studentResponderViewController;
// 老师和助教答题器窗口
@property (nonatomic, nullable, weak) BJLIcQuestionAnswerViewController *questionAnswerWindowViewController;
// 学生答题器窗口
@property (nonatomic, nullable, weak) BJLIcStudentQuestionAnswerWindowViewController *studentQuestionAnswerWindowViewController;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)setFullscreenParentViewController:(UIViewController *)parentViewController
                                superview:(nullable UIView *)superview;

- (__kindof UIViewController *)displayDocumentWindowWithID:(NSString *)documentID
                                             requestUpdate:(BOOL)requestUpdate;

- (BJLIcWebDocumentWindowViewController *)displayWebDocumentWindowWithID:(NSString *)documentID
                                                           requestUpdate:(BOOL)requestUpdate;

- (BJLIcVideoWindowViewController *)displayVideoWindowWithVideoView:(BJLIcUserMediaInfoView *)videoView
                                                      requestUpdate:(BOOL)requestUpdate;

- (void)closeDisplayingVideoWindowWithMediaID:(NSString *)mediaID requestUpdate:(BOOL)requestUpdate;
- (void)closeDisplayingVideoWindowsForUser:(BJLUser *)user requestUpdate:(BOOL)requestUpdate;
- (void)closeDisplayingVideoWindowsWithRequestUpdate:(BOOL)requestUpdate;

// 切换全屏文档窗口
- (void)switchFullScreenDocumentWindowWithID:(NSString *)documentID isWebDocument:(BOOL)isWebDocument;

// 切换最大化文档窗口
- (void)switchMaximizedDocumentWindowWithID:(NSString *)documentID isWebDocument:(BOOL)isWebDocument;

- (void)addImageShapeToBlackboardWithURL:(NSString *)imageURL
                               imageSize:(CGSize)imageSize;

- (void)changeDocumentWithDocumentID:(NSString *)documentID pageIndex:(NSInteger)pageIndex;

- (void)tryToHideWebViewKeyboardView;

- (void)openWebView;

- (void)closeWebViewController;

- (void)closeQuizController;

#pragma mark - writingBoard

/** 作答中的老师窗口, 关闭时要同时发收回小黑板信令 */
- (void)closeWritingBoardWithGatherRequest;

/** 老师小黑板窗口时间输入的回调事件 */
- (void)setWritingBoardTime:(NSString *)text;

#pragma mark -
/** 打开计时器 */
- (void)openCountDownTimer;

/** 撤回计时器 */
- (void)closeCountDownController;

/** 打开答题器 */
- (void)openQuestionAnswer;

/** 关闭答题器 */
- (void)closeQuestionAnswerController;

/** 打开抢答器 */
- (void)openQuestionResponder;

/** 撤回抢答器 */
- (void)closeQuestionResponderController;

/** 断网时，销毁学生的计时器和抢答器*/
- (void)destoryCountDownAndResponder;

@end

NS_ASSUME_NONNULL_END
