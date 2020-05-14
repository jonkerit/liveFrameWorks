//
//  BJLIcBlackboardLayoutViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcBlackboardLayoutViewController.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"
#import "BJLIcBlackboardLayoutViewController+document.h"
#import "BJLIcBlackboardLayoutViewController+video.h"
#import "BJLIcBlackboardLayoutViewController+WritingBoard.h"
#import "BJLIcWritingBoradWindowViewController+protected.h"
#import "BJLIcBlackboardLayoutViewController+padUserVideoUpside.h"
#import "BJLIcBlackboardLayoutViewController+padUserVideoDownside.h"
#import "BJLIcBlackboardLayoutViewController+pad1to1.h"
#import "BJLIcBlackboardLayoutViewController+question.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcBlackboardLayoutViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    
    [self makeSubviews];
    [self makeObserving];
    [self makeCallbacksForVideo];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent) {
        [self remakeConstraints];
    }
}

#pragma mark - subviews

- (void)makeSubviews {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        [self makePad1to1Subviews];
        [self setupPad1to1BlackboardView];
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self makePadUserVideoDownsideSubviews];
        [self setupPadUserVideoDownsideBlackboardView];
    }
    else {
        [self makePadUserVideoUpsideSubviews];
        [self setupPadUserVideoUpsideBlackboardView];
    }
    [self setupTouchMoveGesture];
}

- (void)remakeConstraints {
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        [self remakePad1to1ContainerViewConstraints];
    }
    else if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self remakePadUserVideoDownsideContainerViewConstraints];
    }
    else {
        [self remakePadUserVideoUpsideContainerViewConstraints];
    }
}

#pragma mark - observers

- (void)makeObserving {
    [self makeObserversForVideo];
    [self makeObserverForDocument];
    [self makeObserversForWritingBoard];
    [self makeObeservingForQuestion];
    [self makeObserversForWebPage];
    [self makeObserversForQuiz];

    if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
        [self makePadUserVideoDownsideObserving];
    }
    else {
        [self makePadUserVideoUpsideObserving];
    }
}

- (BJLObservable)setFullscreenParentViewController:(UIViewController *)parentViewController
                                superview:(nullable UIView *)superview {
    self.fullscreenParentViewController = parentViewController;
    self.fullscreenSuperview = superview;
    BJLMethodNotify((UIViewController *, UIView *), parentViewController, superview);
}

#pragma mark - document window

- (void)closeWritingBoardWithGatherRequest {
    if (self.room.loginUser.isTeacher
       && self.writingBoardViewController
       && self.writingBoardViewController.writingBoard.status == BJLIcWriteBoardStatus_teacherPublished
       && self.writingBoardViewController.writingBoard.isActive) {
        [self.writingBoardViewController publishWithOperate:BJLWritingBoardPublishOperate_end restrictionTimeString:nil];
    }
}

- (void)setWritingBoardTime:(NSString *)text {
    if (self.room.loginUser.isTeacher && self.writingBoardViewController) {
        [self.writingBoardViewController inputTimeString:text];
    }
}

- (BJLIcDocumentWindowViewController *)displayDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate {
    BJLIcDocumentWindowViewController *documentWindow = [self.displayingDocumentWindows bjl_objectForKey:documentID
                                                                                                   class:[BJLIcDocumentWindowViewController class]];
    if (documentWindow) {
        // 已存在, 置顶
        [documentWindow bringToFront];
        return documentWindow;
    }
    
    // open
    documentWindow = [[BJLIcDocumentWindowViewController alloc] initWithRoom:self.room documentID:documentID];
    [documentWindow setWindowedParentViewController:self superview:self.documentWindowsView];
    [documentWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                            superview:self.fullscreenSuperview];
    
    bjl_weakify(self, documentWindow);
    // 关闭窗口，移除窗口相关数据
    [documentWindow setDocumentWindowCloseCallback:^(NSString * _Nonnull documentID) {
        bjl_strongify(self);
        [self.displayingDocumentWindows removeObjectForKey:documentID];
        for (BJLWindowDisplayInfo *displayInfo in [self.mutableDocumentWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:documentID]) {
                [self.mutableDocumentWindowDisplayInfos removeObject:displayInfo];
            }
        }
        self.documentWindowDisplayInfos = self.mutableDocumentWindowDisplayInfos;
    }];
    
    // 窗口位置更新
    [documentWindow setWindowUpdateCallback:^(NSString * _Nonnull action, CGRect relativeRect) {
        bjl_strongify(self);
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.mutableDocumentWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:documentID]) {
                oldDisplayInfo = displayInfo;
                [self.mutableDocumentWindowDisplayInfos removeObject:displayInfo];
                break;
            }
        }
        if (![action isEqualToString:BJLWindowsUpdateAction_close]) {
            BOOL shouldKeepFullScreen = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                           && ![action isEqualToString:BJLWindowsUpdateAction_maximize]);
            BOOL shouldCKeepMaximize = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                         && ![action isEqualToString:BJLWindowsUpdateAction_fullScreen]);
            BJLWindowDisplayInfo *newDisplayInfo = ({
                BJLWindowDisplayInfo *info = [[BJLWindowDisplayInfo alloc] init];
                info.ID = documentID;
                info.x = CGRectGetMinX(relativeRect);
                info.y = CGRectGetMinY(relativeRect);
                info.width = CGRectGetWidth(relativeRect);
                info.height = CGRectGetHeight(relativeRect);
                info.isFullScreen = ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]
                                     || (oldDisplayInfo.isFullScreen && shouldKeepFullScreen));
                info.isMaximized = ([action isEqualToString:BJLWindowsUpdateAction_maximize]
                                    || (oldDisplayInfo.isMaximized && shouldCKeepMaximize));
                info;
            });
            [self.mutableDocumentWindowDisplayInfos bjl_addObject:newDisplayInfo];
        }
        self.documentWindowDisplayInfos = self.mutableDocumentWindowDisplayInfos;
        
        if (self.room.loginUser.isTeacherOrAssistant) {
            [self.room.documentVM updateDocumentWindowWithID:documentID
                                                      action:action
                                                displayInfos:self.documentWindowDisplayInfos];
        }
    }];
    
    [self bjl_observe:BJLMakeMethod(self, setFullscreenParentViewController:superview:)
             observer:^BOOL{
                 bjl_strongify(self, documentWindow);
                 [documentWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                                         superview:self.fullscreenSuperview];
                 return YES;
             }];
    
    if (requestUpdate) {
        [documentWindow open];
    }
    else {
        [documentWindow openWithoutRequest];
    }
    [self.displayingDocumentWindows bjl_setObject:documentWindow forKey:documentID];
    return documentWindow;
}

- (void)changeDocumentWithDocumentID:(NSString *)documentID pageIndex:(NSInteger)pageIndex {
    [self.room.documentVM requestTurnToDocumentID:documentID pageIndex:pageIndex];
}

- (void)switchFullScreenDocumentWindowWithID:(NSString *)documentID isWebDocument:(BOOL)isWebDocument {
    [self restoreFullScreenAndMaximizedDocumentWindows];
    BJLIcWindowViewController *documentWindow = (isWebDocument
                                                 ? [self.displayingWebDocumentWindows bjl_objectForKey:documentID]
                                                 : [self.displayingDocumentWindows bjl_objectForKey:documentID]);
    [documentWindow bringToFront];
    [documentWindow fullscreen];
}

- (void)switchMaximizedDocumentWindowWithID:(NSString *)documentID isWebDocument:(BOOL)isWebDocument {
    [self restoreFullScreenAndMaximizedDocumentWindows];
    BJLIcWindowViewController *documentWindow = (isWebDocument
                                                 ? [self.displayingWebDocumentWindows bjl_objectForKey:documentID]
                                                 : [self.displayingDocumentWindows bjl_objectForKey:documentID]);
    [documentWindow bringToFront];
    [documentWindow maximize];
}

- (void)restoreFullScreenAndMaximizedDocumentWindows {
    // 普通文档
    for (BJLWindowDisplayInfo *displayInfo in [self.documentWindowDisplayInfos copy]) {
        if (displayInfo.isFullScreen || displayInfo.isMaximized) {
            BJLIcDocumentWindowViewController *window = [self.displayingDocumentWindows bjl_objectForKey:displayInfo.ID
                                                                                                   class:[BJLIcDocumentWindowViewController class]];
            [window restore];
        }
    }
    
    // web 文档
    for (BJLWindowDisplayInfo *displayInfo in [self.webDocumentWindowDisplayInfos copy]) {
        if (displayInfo.isFullScreen || displayInfo.isMaximized) {
            BJLIcWebDocumentWindowViewController *window = [self.displayingWebDocumentWindows bjl_objectForKey:displayInfo.ID
                                                                                                         class:[BJLIcWebDocumentWindowViewController class]];
            [window restore];
        }
    }
}

- (void)closeDisplayingDocumentWindowsWithRequestUpdate:(BOOL)requestUpdate {
    [[self.displayingDocumentWindows copy] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        BJLIcDocumentWindowViewController *window = bjl_as(obj, BJLIcDocumentWindowViewController);
        if (requestUpdate) {
            [window close];
        }
        else {
            [window closeWithoutRequest];
        }
    }];
}

- (void)closeDisplayingDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate {
    BJLIcDocumentWindowViewController *window = bjl_as([self.displayingDocumentWindows objectForKey:documentID], BJLIcDocumentWindowViewController);
    if (requestUpdate) {
        [window close];
    }
    else {
        [window closeWithoutRequest];
    }
}

- (void)addImageShapeToBlackboardWithURL:(NSString *)imageURL
                               imageSize:(CGSize)imageSize {
    [self.room.drawingVM addImageShapeWithURL:imageURL
                                relativeFrame:[self relativeFrameForImageWithSize:imageSize]
                                 toDocumentID:BJLBlackboardID
                                    pageIndex:0
                               isWritingBoard:NO];
}

- (CGRect)relativeFrameForImageWithSize:(CGSize)imageSize {
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    if (width <= 0.0
        || height <= 0.0) {
        return CGRectZero;
    }
    
    CGSize blackboardSize = bjl_set(self.blackboardView.bounds.size, {
        set.height *= self.room.documentVM.blackboardContentPages;
    });
    if (blackboardSize.width <= 0.0
        || blackboardSize.height <= 0.0) {
        return CGRectZero;
    }
    
    CGSize layoutSize = bjl_set(blackboardSize, {
        set.width -= 24.0;
        set.height -= 24.0;
    });
    
    CGFloat ratio = width / height;
    if (width > layoutSize.width) {
        width = layoutSize.width;
        height = width / ratio;
    }
    if (height > layoutSize.height) {
        height = layoutSize.width;
        width = height *ratio;
    }
    
    return CGRectMake(12.0 / blackboardSize.width,
                      12.0 / blackboardSize.height,
                      width / blackboardSize.width,
                      height / blackboardSize.height);
}

#pragma mark - web document window

- (BJLIcWebDocumentWindowViewController *)displayWebDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate {
    BJLIcWebDocumentWindowViewController *webDocumentWindow = [self.displayingWebDocumentWindows bjl_objectForKey:documentID
                                                                                                            class:[BJLIcWebDocumentWindowViewController class]];
    if (webDocumentWindow) {
        // 已存在, 置顶
        [webDocumentWindow bringToFront];
        return webDocumentWindow;
    }
    
    if (self.displayingWebDocumentWindows.count > 0
        && self.showErrorMessageCallback) {
        self.showErrorMessageCallback(@"教室内只能同时打开一个网页文档");
        return self.displayingWebDocumentWindows.allValues.firstObject;
    }
    
    // open
    webDocumentWindow = [[BJLIcWebDocumentWindowViewController alloc] initWithRoom:self.room webDocumentID:documentID];
    [webDocumentWindow setWindowedParentViewController:self superview:self.webDocumentWindowsView];
    [webDocumentWindow setFullscreenParentViewController:self.fullscreenParentViewController superview:self.fullscreenSuperview];
    
    bjl_weakify(self, webDocumentWindow);
    // 关闭窗口, 移除窗口相关数据
    [webDocumentWindow setWebDocumentWindowCloseCallback:^(NSString * _Nonnull documentID) {
        bjl_strongify(self);
        [self.displayingWebDocumentWindows removeObjectForKey:documentID];
        for (BJLWindowDisplayInfo *displayInfo in [self.mutableWebDocumentWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:documentID]) {
                [self.mutableWebDocumentWindowDisplayInfos removeObject:displayInfo];
            }
        }
        self.webDocumentWindowDisplayInfos = self.mutableWebDocumentWindowDisplayInfos;
    }];
    
    // 窗口位置更新
    [webDocumentWindow setWindowUpdateCallback:^(NSString * _Nonnull action, CGRect relativeRect) {
        bjl_strongify(self);
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.mutableWebDocumentWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:documentID]) {
                oldDisplayInfo = displayInfo;
                [self.mutableWebDocumentWindowDisplayInfos removeObject:displayInfo];
                break;
            }
        }
        if (![action isEqualToString:BJLWindowsUpdateAction_close]) {
            BOOL shouldKeepFullScreen = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                           && ![action isEqualToString:BJLWindowsUpdateAction_maximize]);
            BOOL shouldCKeepMaximize = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                         && ![action isEqualToString:BJLWindowsUpdateAction_fullScreen]);
            BJLWindowDisplayInfo *newDisplayInfo = ({
                BJLWindowDisplayInfo *info = [[BJLWindowDisplayInfo alloc] init];
                info.ID = documentID;
                info.x = CGRectGetMinX(relativeRect);
                info.y = CGRectGetMinY(relativeRect);
                info.width = CGRectGetWidth(relativeRect);
                info.height = CGRectGetHeight(relativeRect);
                info.isFullScreen = ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]
                                     || (oldDisplayInfo.isFullScreen && shouldKeepFullScreen));
                info.isMaximized = ([action isEqualToString:BJLWindowsUpdateAction_maximize]
                                    || (oldDisplayInfo.isMaximized && shouldCKeepMaximize));
                info;
            });
            [self.mutableWebDocumentWindowDisplayInfos bjl_addObject:newDisplayInfo];
        }
        self.webDocumentWindowDisplayInfos = self.mutableWebDocumentWindowDisplayInfos;
        if (self.room.loginUser.isTeacherOrAssistant) {
            [self.room.documentVM updateWebDocumentWindowWithID:documentID
                                                         action:action
                                                   displayInfos:self.webDocumentWindowDisplayInfos];
        }
    }];
    
    [self bjl_observe:BJLMakeMethod(self, setFullscreenParentViewController:superview:)
             observer:^BOOL{
                 bjl_strongify(self, webDocumentWindow);
                 [webDocumentWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                                            superview:self.fullscreenSuperview];
                 return YES;
             }];
    
    if (requestUpdate) {
        [webDocumentWindow open];
    }
    else {
        [webDocumentWindow openWithoutRequest];
    }
    [self.displayingWebDocumentWindows bjl_setObject:webDocumentWindow forKey:documentID];
    
    return webDocumentWindow;
}

- (void)closeDisplayingWebDocumentWindowsWithRequestUpdate:(BOOL)requestUpdate {
    [[self.displayingWebDocumentWindows copy] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        BJLIcWebDocumentWindowViewController *window = bjl_as(obj, BJLIcWebDocumentWindowViewController);
        if (requestUpdate) {
            [window close];
        }
        else {
            [window closeWithoutRequest];
        }
    }];
}

- (void)closeDisplayingWebDocumentWindowWithID:(NSString *)documentID requestUpdate:(BOOL)requestUpdate {
    BJLIcWebDocumentWindowViewController *window = bjl_as([self.displayingWebDocumentWindows objectForKey:documentID], BJLIcWebDocumentWindowViewController);
    if (requestUpdate) {
        [window close];
    }
    else {
        [window closeWithoutRequest];
    }
}

#pragma mark - webview

- (void)makeObserversForWebPage {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didUpdateWebPageWithURLString:open:isCache:)
             observer:(BJLMethodObserver)^BOOL(NSString *urlString, BOOL open, BOOL isCache) {
                 bjl_strongify(self);
                 if (open) {
                     if (self.webViewWindowViewController) {
                         [self.webViewWindowViewController closeWithoutRequest];
                         self.webViewWindowViewController = nil;
                     }
                     // open 时无条件打开，仅老师有发布权限
                     if (self.room.loginUser.isTeacher) {
                         self.webViewWindowViewController = [self displayWebViewWindowWithURLString:urlString layout:BJLIcWebViewWindowLayout_publish];
                     }
                     else {
                         self.webViewWindowViewController = [self displayWebViewWindowWithURLString:urlString layout:BJLIcWebViewWindowLayout_normal];
                     }
                 }
                 else {
                     if (self.room.loginUser.isTeacher) {
                         // 关闭时，不存在网页页面时，收到的如果是缓存，不处理
                         if (!self.webViewWindowViewController) {
                             if (!isCache) {
                                 self.webViewWindowViewController = [self displayWebViewWindowWithURLString:urlString layout:BJLIcWebViewWindowLayout_unpublish];
                             }
                         }
                         else {
                             // 如果在存在窗口的时候收到了取消发布网页的请求，变成未发布状态
                             [self.webViewWindowViewController remakeConstraintsWithLayout:BJLIcWebViewWindowLayout_unpublish];
                         }
                     }
                     else {
                         // 学生和助教无条件关闭
                         if (self.webViewWindowViewController) {
                             [self.webViewWindowViewController closeWithoutRequest];
                             self.webViewWindowViewController = nil;
                         }
                     }
                 }
                 return YES;
             }];
}

- (void)tryToHideWebViewKeyboardView {
    if (self.webViewWindowViewController) {
        [self.webViewWindowViewController hideKeyboardView];
    }
    
    // 倒计时页面同网页共用一个方法, 此处可以不用写
    if (self.countDownViewController) {
        [self.countDownViewController hideKeyboardView];
    }
    
    if (self.questionResponderViewController) {
        [self.questionResponderViewController hideKeyboardView];
    }
    
    if (self.questionAnswerWindowViewController) {
        [self.questionAnswerWindowViewController hideKeyboardView];
    }
}

- (BJLIcWebViewWindowViewController *)displayWebViewWindowWithURLString:(nullable NSString *)urlString layout:(BJLIcWebViewWindowLayout)layout {
    BJLIcWebViewWindowViewController *webviewWindow = [[BJLIcWebViewWindowViewController alloc] initWithURLString:urlString layout:layout];
    if (self.room.loginUser.isTeacherOrAssistant) {
        bjl_weakify(self);
        [webviewWindow setPublishWebViewCallback:^(NSString * _Nullable urlString, BOOL publish, BOOL close) {
            bjl_strongify(self);
            if (close) {
                self.webViewWindowViewController = nil;
            }
            [self.room.roomVM updateWebPageWithURLString:urlString open:publish];
        }];
    }
    if (self.webviewControllerKeyboardFrameChangeCallback) {
        bjl_weakify(self);
        [webviewWindow setKeyboardFrameChangeCallback:^(CGRect keyboardFrame) {
            bjl_strongify(self);
            self.webviewControllerKeyboardFrameChangeCallback(keyboardFrame, self.documentWindowsView);
        }];
    }
    if (self.closeWebviewControllerCallback) {
        bjl_weakify(self);
        [webviewWindow setCloseWebViewCallback:^{
            bjl_strongify(self);
            self.closeWebviewControllerCallback();
        }];
    }
    
    [webviewWindow setWindowedParentViewController:self superview:self.webviewWindowsView];
    [webviewWindow setFullscreenParentViewController:self.fullscreenParentViewController superview:self.fullscreenSuperview];
    [webviewWindow openWithoutRequest];
    return webviewWindow;
}

- (void)closeWebViewController {
    if (self.webViewWindowViewController) {
        [self.webViewWindowViewController closeWebView];
    }
}

- (void)openWebView {
    if (self.room.loginUser.isTeacher && !self.webViewWindowViewController) {
        self.webViewWindowViewController = [self displayWebViewWindowWithURLString:nil layout:BJLIcWebViewWindowLayout_unpublish];
    }
    else if (self.webViewWindowViewController) {
        [self.webViewWindowViewController bringToFront];
    }
}

#pragma mark - quiz

- (void)makeObserversForQuiz {
    bjl_weakify(self);
    if (self.room.loginUser.isTeacher) {
        return;
    }
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuizMessage:)
             observer:^BOOL(NSDictionary<NSString *, id> *message) {
                 bjl_strongify(self);
        BJLIcQuizWindowViewController *window = [BJLIcQuizWindowViewController instanceWithRoom:self.room quizMessage:message];
        if (window) {
            if (self.quizViewController) {
                if   (self.cancelQuizControllerCallback) {
                    self.cancelQuizControllerCallback();
                }
                [self.quizViewController updateCloseButtonHidden:YES];
                [self.quizViewController closeWithoutRequest];
                self.quizViewController = nil;
            }
            self.quizViewController = window;
            self.quizViewController.closeWebViewCallback = ^{
                bjl_strongify(self);
                [self.quizViewController closeWithoutRequest];
                self.quizViewController = nil;
            };
            self.quizViewController.closeQuizCallback = ^{
                bjl_strongify(self);
                if (self.closeQuizControllerCallback) {
                    self.closeQuizControllerCallback();
                }
            };
            self.quizViewController.sendQuizMessageCallback = ^BJLError * _Nullable(NSDictionary<NSString *, id> * _Nonnull message) {
                bjl_strongify(self);
                return [self.room.roomVM sendQuizMessage:message];
            };
            [window setWindowedParentViewController:self superview:self.responderWindowView];
            [window openWithoutRequest];
        }
        else if(self.quizViewController) {
            [self.quizViewController didReceiveQuizMessage:message];
        }
        return YES;
    }];
        
    [self bjl_kvo:BJLMakeProperty(self.room, state)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.state == BJLRoomState_connected) {
                 if (self.quizViewController) {
                     [self.quizViewController closeWithoutRequest];
                 }
                 [self.room.roomVM sendQuizMessage:[BJLIcQuizWindowViewController quizReqMessageWithUserNumber:self.room.loginUser.number]];
             }
             return YES;
         }];
}

- (void)closeQuizController {
    if (self.quizViewController) {
        [self.quizViewController updateCloseButtonHidden:YES];
        [self.quizViewController closeWithoutRequest];
        self.quizViewController = nil;
    }
}

#pragma mark - topWindowView

- (void)openCountDownTimer {
    if (self.room.loginUser.isTeacher && !self.countDownViewController) {
        self.countDownViewController = [self displayCountDownWindowWithTime:0 layout:BJLIcCountDownWindowLayout_unpublish];
    }
    else if (self.countDownViewController) {
        [self.countDownViewController bringToFront];
    }
}

- (void)closeCountDownController {
    if (self.countDownViewController) {
        [self.countDownViewController closeCountDown];
    }
}

- (void)openQuestionAnswer {
    if (self.room.loginUser.isTeacher && !self.questionAnswerWindowViewController) {
        BJLAnswerSheet *answerSheet = [[BJLAnswerSheet alloc] initWithAnswerType:BJLAnswerSheetType_Choosen];
        self.questionAnswerWindowViewController = [self displayQuestionAnswerWindowWithAnswerSheet:answerSheet layout:BJLIcQuestionAnswerWindowLayout_normal];
    }
    else if (self.questionAnswerWindowViewController) {
        [self.questionAnswerWindowViewController bringToFront];
    }
}

- (void)closeQuestionAnswerController {
    if (self.questionAnswerWindowViewController) {
        [self.questionAnswerWindowViewController closeQuestionAnswer];
    }
}

- (void)openQuestionResponder {
    if (self.room.loginUser.isTeacher && !self.questionResponderViewController) {
        self.questionResponderViewController = [self displayQuestionResponderWindowWithLayout:BJLIcQuestionResponderWindowLayout_normal];
    }
    else if (self.questionResponderViewController) {
        [self.questionResponderViewController bringToFront];
    }
}

- (void)closeQuestionResponderController {
    if (self.questionResponderViewController) {
        [self.questionResponderViewController closeQuestionResponder];
    }
}

- (void)destoryCountDownAndResponder {
    if (!self.room.loginUser.isStudent) {
        return;
    }
    
    if (self.countDownViewController) {
        [self.countDownViewController closeWithoutRequest];
    }
    
    if (self.studentResponderViewController) {
        [self.studentResponderViewController hide];
    }
}

- (__kindof UIViewController *)displayCountDownWindowWithTime:(NSTimeInterval)time
                                                       layout:(BJLIcCountDownWindowLayout)layout {
    BJLIcCountDownWindowViewController *countDownViewController = [[BJLIcCountDownWindowViewController alloc] initWithRoom:self.room countDownTime:time layout:layout];
    
    if (self.room.loginUser.isTeacher || self.room.loginUser.isAssistant) {
        bjl_weakify(self);
        [countDownViewController setPublishCountDownTimerCallback:^BOOL(NSTimeInterval time, BOOL publish, BOOL close) {
            bjl_strongify(self);
            BJLError *error = [self.room.roomVM requestUpdateCountDownTimerWithTime:time open:publish];
            
            if (error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                return NO;
            }

            if (close) {
                self.countDownViewController = nil;
            }
            return YES;
        }];
        
        [countDownViewController setRevokeCountDownTimerCallback:^BOOL{
            bjl_strongify(self);
            BJLError *error = [self.room.roomVM requestRevokeCountDownTimer];
            if (error) {
                self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                return NO;
            }
            return YES;
        }];
        
        [countDownViewController setCloseCountDownTimerCallback:^{
            bjl_strongify(self);
            [self closeCountDownController];
        }];
        
        [countDownViewController setErrorCallback:^(NSString *message){
            bjl_strongify(self);
            if (self.showErrorMessageCallback) {
                self.showErrorMessageCallback(message);
            }
        }];
        
        [countDownViewController setKeyboardFrameChangeCallback:^(CGRect keyboardFrame) {
            bjl_strongify(self);
            self.webviewControllerKeyboardFrameChangeCallback(keyboardFrame, self.responderWindowView);
        }];
    }
    
    [countDownViewController setWindowedParentViewController:self superview:self.responderWindowView];
    [countDownViewController openWithoutRequest];
    return countDownViewController;
}

- (nullable __kindof UIViewController * )displayQuestionResponderWindowWithLayout:(BJLIcQuestionResponderWindowLayout)layout {
    if (self.room.loginUser.isStudent) {
        return nil;
    }

    BJLIcQuestionResponderWindowViewController *questionResponderWindow = [[BJLIcQuestionResponderWindowViewController alloc] initWithRoom:self.room layout:layout historeQuestionList:self.questionResponderList];
    
    bjl_weakify(self);
    [questionResponderWindow setPublishQuestionResponderCallback:^BOOL(NSTimeInterval time) {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestPublishQuestionResponderWithTime:time];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        return YES;
    }];
    
    [questionResponderWindow setEndQuestionResponderCallback:^BOOL(BOOL close) {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM endQuestionResponderWithShouldCloseWindow:close];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        
        if (close) {
            self.questionResponderViewController = nil;
        }
        return YES;
    }];
    
    [questionResponderWindow setRevokeQuestionResponderCallback:^BOOL{
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestRevokeQuestionResponder];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        return YES;
    }];
    
    [questionResponderWindow setCloseQuestionResponderCallback:^{
        bjl_strongify(self);
        [self closeQuestionResponderController];
    }];
    
    [questionResponderWindow setCloseCallback:^ {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestCloseQuestionResponder];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
        }
    }];
    
    [questionResponderWindow setErrorCallback:^(NSString *message){
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    
    [questionResponderWindow setKeyboardFrameChangeCallback:^(CGRect keyboardFrame) {
        bjl_strongify(self);
        if (self.webviewControllerKeyboardFrameChangeCallback) {
            self.webviewControllerKeyboardFrameChangeCallback(keyboardFrame, self.responderWindowView);
        }
    }];
    
    [questionResponderWindow setResponderSuccessCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.receiveLikeCallback) {
            self.receiveLikeCallback(user, button);
        }
    }];

    [questionResponderWindow setWindowedParentViewController:self superview:self.responderWindowView];
    [questionResponderWindow openWithoutRequest];
    return questionResponderWindow;
}

- (nullable __kindof UIViewController *)displayQuestionResponderWindowWithCountDownTime:(NSInteger)time {
    if (!self.room.loginUser.isStudent) {
        return nil;
    }
    BJLIcStudentQuestionResponderViewController *responderVC = [[BJLIcStudentQuestionResponderViewController alloc] initWithRoom:self.room countDownTime:time];
    
    bjl_weakify(self);
    [responderVC setErrorCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    [responderVC setResponderCallback:^{
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM submitQuestionResponder];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        return YES;
    }];
    [responderVC setResponderSuccessCallback:^(BJLUser * _Nonnull user, UIButton * _Nonnull button) {
        bjl_strongify(self);
        if (self.receiveLikeCallback) {
            self.receiveLikeCallback(user, button);
        }
    }];
    
    [responderVC setHiddenCallback:^void {
        bjl_strongify(self);
        self.studentResponderViewController = nil;
    }];
    
    [self bjl_addChildViewController:responderVC superview:self.responderWindowView];
    [responderVC.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.responderWindowView);
    }];
    return responderVC;
}

- (__kindof UIViewController *)displayQuestionAnswerWindowWithAnswerSheet:(BJLAnswerSheet *)answerSheet
                                                                   layout:(BJLIcQuestionAnswerWindowLayout)layout {
    BJLIcQuestionAnswerViewController *questionAnswerWindow = [[BJLIcQuestionAnswerViewController alloc] initWithRoom:self.room
                                                                                                          answerSheet:answerSheet
                                                                                                               layout:layout];
    
    bjl_weakify(self);
    [questionAnswerWindow setPublishQuestionAnswerCallback:^(BJLAnswerSheet *answerSheet) {
        bjl_strongify(self);
        [self.room.roomVM requestPublishQuestionAnswerSheet:answerSheet];
    }];
    
    [questionAnswerWindow setEndQuestionAnswerCallback:^(BOOL close){
        bjl_strongify(self);
        [self.room.roomVM requestEndQuestionAnswerWithShouldSyncCloseWindow:close];
        
        if (close) {
            self.questionAnswerWindowViewController = nil;
        }
    }];

    [questionAnswerWindow setRevokeQuestionAnswerCallback:^{
        bjl_strongify(self);
        [self.room.roomVM requestRevokeQuestionAnswer];
    }];

    [questionAnswerWindow setCloseQuestionAnswerCallback:^{
        bjl_strongify(self);
        if (self.closeQuestionAnswerControllerCallback) {
            self.closeQuestionAnswerControllerCallback();
        }
    }];

    [questionAnswerWindow setRequestQuestionDetailCallback:^BOOL(NSString * _Nonnull ID) {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestQuestionAnswerDetailInfoWithAnswerSheetID:ID];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        return YES;
    }];
    
    [questionAnswerWindow setCloseCallback:^{
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM requestCloseQuestionAnswer];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
        }
    }];

    [questionAnswerWindow setErrorCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    
    [questionAnswerWindow setKeyboardFrameChangeCallback:^(CGRect keyboardFrame) {
        bjl_strongify(self);
        if (self.webviewControllerKeyboardFrameChangeCallback) {
            self.webviewControllerKeyboardFrameChangeCallback(keyboardFrame, self.responderWindowView);
        }
    }];
    
    [questionAnswerWindow setWindowedParentViewController:self superview:self.responderWindowView];
    [questionAnswerWindow openWithoutRequest];
    return questionAnswerWindow;
}

- (__kindof UIViewController *)displayQuestionAnswerWindowWithAnswerSheet:(BJLAnswerSheet *)anwserSheet {
    BJLIcStudentQuestionAnswerWindowViewController *studentQuestionAnswerWindow = [[BJLIcStudentQuestionAnswerWindowViewController alloc] initWithRoom:self.room answerSheet:anwserSheet];
    
    bjl_weakify(self);
    [studentQuestionAnswerWindow setErrorCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];

    [studentQuestionAnswerWindow setSubmitCallback:^BOOL(BJLAnswerSheet * _Nonnull answerSheet) {
        bjl_strongify(self);
        BJLError *error = [self.room.roomVM submitQuestionAnswer:answerSheet];
        if (error) {
            self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
            return NO;
        }
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"提交成功");
        }
        return YES;
    }];
    
    [studentQuestionAnswerWindow setWindowedParentViewController:self superview:self.responderWindowView];
    [studentQuestionAnswerWindow openWithoutRequest];
    return studentQuestionAnswerWindow;
}

#pragma mark - writingboard

- (__kindof UIViewController *)displayWritingBoardWindowWith:(BJLWritingBoard *)writingBoard
                                                  userNumber:(NSString *)userNumber
                                               requestUpdate:(BOOL)requestUpdate {
    /** 小黑板窗口的key 使用documentID-pageIndex-userNumber */
    
    NSString *key = [self keyForWritingBoard:writingBoard.boardID
                                   pageIndex:writingBoard.pageIndex
                                  userNumber:userNumber];
    
    BJLIcWritingBoradWindowViewController *boardWindow = [self.displayingWritingBoardWindows bjl_objectForKey:key class:[BJLIcWritingBoradWindowViewController class]];
    
    if (boardWindow) {
        //已存在, 则置顶
        [boardWindow bringToFront];
        return boardWindow;
    }
    
    //open
    boardWindow = [[BJLIcWritingBoradWindowViewController alloc] initWithRoom:self.room
                                                                 writingBoard:writingBoard
                                                                   userNumber:userNumber];
    
    [boardWindow setWindowedParentViewController:self superview:self.writingBoardWindowsView];
    [boardWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                         superview:self.fullscreenSuperview];
    
    bjl_weakify(self, boardWindow);
    [boardWindow setTeacherwillRenameWritingBoardCallback:^(BJLWritingBoard * _Nonnull writingBoard, NSString * _Nonnull layerID, NSString * _Nonnull name, CGRect relativeRect) {
        bjl_strongify(self);
        
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.writingBoardWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:layerID]) {
                oldDisplayInfo = displayInfo;
                break;
            }
        }
        if (oldDisplayInfo) {
            [self.mutableWritingBoardWindowDisplayInfos removeObject:oldDisplayInfo];
        }
        
        BJLWindowDisplayInfo *newDisplayInfo = ({
            BJLWindowDisplayInfo *info = [[BJLWindowDisplayInfo alloc] init];
            info.ID = layerID;
            info.x = CGRectGetMinX(relativeRect);
            info.y = CGRectGetMinY(relativeRect);
            info.width = CGRectGetWidth(relativeRect);
            info.height = CGRectGetHeight(relativeRect);
            info.name = name;
            info;
        });
        
        [self.mutableWritingBoardWindowDisplayInfos bjl_addObject:newDisplayInfo];
        self.writingBoardWindowDisplayInfos = self.mutableWritingBoardWindowDisplayInfos;
        
        if (self.room.loginUser.isTeacher && layerID) {
            [self.room.documentVM updateWritingBoardWindow:writingBoard
                                                userNumber:layerID
                                                    action:BJLWindowsUpdateAction_rename
                                              displayInfos:self.writingBoardWindowDisplayInfos];
        }
        
    }];
    
    [boardWindow setWritingBoardWindowCloseCallback:^(NSString *boardID, NSInteger pageIndex, NSString *layerID) {
        NSString *key = [self keyForWritingBoard:boardID pageIndex:pageIndex userNumber:layerID];
        
        bjl_strongify(self);
        [self.displayingWritingBoardWindows removeObjectForKey:key];
        
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.writingBoardWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:layerID]) {
                oldDisplayInfo = displayInfo;
                break;
            }
        }
        if (oldDisplayInfo) {
            [self.mutableWritingBoardWindowDisplayInfos removeObject:oldDisplayInfo];
        }
        self.writingBoardWindowDisplayInfos = self.mutableWritingBoardWindowDisplayInfos;
        
        if (self.writingBoardViewController && self.room.loginUser.isTeacher) {
            [self.writingBoardViewController addParticipatedUserLayer:layerID];
        }
    }];
    
    [boardWindow setWindowUpdateCallback:^(NSString * _Nonnull action, CGRect relativeRect) {
        bjl_strongify(self, boardWindow);
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.writingBoardWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:userNumber]) {
                oldDisplayInfo = displayInfo;
                break;
            }
        }
        if (oldDisplayInfo) {
            [self.mutableWritingBoardWindowDisplayInfos removeObject:oldDisplayInfo];
        }
        if (![action isEqualToString:BJLWindowsUpdateAction_close]) {
            BOOL shouldKeepFullScreen = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                         && ![action isEqualToString:BJLWindowsUpdateAction_maximize]);
            BOOL shouldCKeepMaximize = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                        && ![action isEqualToString:BJLWindowsUpdateAction_fullScreen]);
            
            BJLWindowDisplayInfo *newDisplayInfo = ({
                BJLWindowDisplayInfo *info = [[BJLWindowDisplayInfo alloc] init];
                info.ID = userNumber;
                info.x = CGRectGetMinX(relativeRect);
                info.y = CGRectGetMinY(relativeRect);
                info.width = CGRectGetWidth(relativeRect);
                info.height = CGRectGetHeight(relativeRect);
                info.isFullScreen = ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]
                                     || (oldDisplayInfo.isFullScreen && shouldKeepFullScreen));
                info.isMaximized = ([action isEqualToString:BJLWindowsUpdateAction_maximize]
                                    || (oldDisplayInfo.isMaximized && shouldCKeepMaximize));
                info.name = boardWindow.writingBoard.userName;
                info;
            });
            [self.mutableWritingBoardWindowDisplayInfos bjl_addObject:newDisplayInfo];
        }
        self.writingBoardWindowDisplayInfos = self.mutableWritingBoardWindowDisplayInfos;
        
        //老师移动分享的他人的小黑板窗口,需要同步
        if (self.room.loginUser.isTeacher && userNumber) {
            [self.room.documentVM updateWritingBoardWindow:boardWindow.writingBoard
                                                userNumber:userNumber
                                                    action:action
                                              displayInfos:self.writingBoardWindowDisplayInfos];
        }
    }];
    
    [self bjl_observe:BJLMakeMethod(self, setFullscreenParentViewController:superview:)
             observer:^BOOL{
                 bjl_strongify(self, boardWindow);
                 [boardWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                                      superview:self.fullscreenSuperview];
                 return YES;
             }];
    
    if (requestUpdate) {
        [boardWindow open];
    }
    else {
        [boardWindow openWithoutRequest];
    }
    [self.displayingWritingBoardWindows setObject:boardWindow forKey:key];
    
    return boardWindow;
}

- (void)closeDisplayingWritingBoardWindowsWithRequestUpdate:(BOOL)requestUpdate {
    [[self.displayingWritingBoardWindows copy] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (requestUpdate) {
            [bjl_as(obj, BJLIcWritingBoradWindowViewController) closeWritingBoard];
        }
        else {
            [bjl_as(obj, BJLIcWritingBoradWindowViewController) closeWithoutRequest];
        }
    }];
}

- (void)closeDisplayingWritingBoardWindowWithID:(NSString *)documentID
                                      pageIndex:(NSInteger)pageIndex
                                     userNumber:(NSString *)userNumber
                                  requestUpdate:(BOOL)requestUpdate {
    NSString *key = [self keyForWritingBoard:documentID pageIndex:pageIndex userNumber:userNumber];
    BJLIcWritingBoradWindowViewController *window = bjl_as([self.displayingWritingBoardWindows objectForKey:key], BJLIcWritingBoradWindowViewController);
    if (requestUpdate) {
        [window closeWritingBoard];
    }
    else {
        [window closeWithoutRequest];
    }
}

#pragma mark - video window

- (void)closeDisplayingVideoWindowsWithRequestUpdate:(BOOL)requestUpdate {
    [[self.displayingVideoWindows copy] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (requestUpdate) {
            [bjl_as(obj, BJLIcVideoWindowViewController) close];
        }
        else {
            [bjl_as(obj, BJLIcVideoWindowViewController) closeWithoutRequest];
        }
    }];
}

- (void)closeDisplayingVideoWindowWithMediaID:(NSString *)mediaID requestUpdate:(BOOL)requestUpdate {
    BJLIcVideoWindowViewController *window = bjl_as([self.displayingVideoWindows objectForKey:mediaID], BJLIcVideoWindowViewController);
    if (requestUpdate) {
        [window close];
    }
    else {
        [window closeWithoutRequest];
    }
}

- (void)closeDisplayingVideoWindowsForUser:(BJLUser *)user requestUpdate:(BOOL)requestUpdate {
    [[self.displayingVideoWindows copy] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull mediaID, BJLIcVideoWindowViewController * _Nonnull window, BOOL * _Nonnull stop) {
        BJLUser *disPlayingUser = window.videoView.user;
        if ([user isSameUser:disPlayingUser]) {
            if (requestUpdate) {
                [window close];
            }
            else {
                [window closeWithoutRequest];
            }
        }
    }];
}

- (BJLIcVideoWindowViewController *)displayVideoWindowWithVideoView:(BJLIcUserMediaInfoView *)videoView
                                                      requestUpdate:(BOOL)requestUpdate  {
    NSString *mediaID = videoView.mediaID;
    BJLIcVideoWindowViewController *videoWindow = [self.displayingVideoWindows bjl_objectForKey:mediaID
                                                                                          class:[BJLIcVideoWindowViewController class]];
    if (videoWindow) {
        // 已存在, 置顶
        [videoWindow bringToFrontWithoutRequest];
        return videoWindow;
    }
    // 切换为大流
    if (BJLIcTemplateType_1v1 != self.room.roomInfo.interactiveClassTemplateType) {
        [self.room.playingVM switchVideoDefinitionWithUser:videoView.user useLowDefinition:NO];
    }
    
    
    videoWindow = [[BJLIcVideoWindowViewController alloc] initWithRoom:self.room
                                                               mediaID:videoView.mediaID];
    [videoWindow setWindowedParentViewController:self superview:self.videoWindowsView];
    [videoWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                         superview:self.fullscreenSuperview];
    videoWindow.videoView = videoView;
    [videoView updateParentViewController:videoWindow];
    bjl_weakify(self, videoWindow, videoView);
    [videoView setShowErrorMessageCallback:^(NSString * _Nonnull message) {
        bjl_strongify(self);
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(message);
        }
    }];
    [videoView setUpdateVideoCallback:^(BJLMediaUser * _Nonnull user, BOOL on) {
        bjl_strongify(self);
        if (self.updateVideoCallback) {
            self.updateVideoCallback(user, on);
        }
    }];
    [videoView setBlockUserCallback:^BOOL(BJLUser * _Nonnull user) {
        bjl_strongify(self);
        if (self.blockUserCallback) {
            return self.blockUserCallback(user);
        }
        return NO;
    }];
    [videoWindow setSingleTapGestureCallback:^(CGPoint point) {
        bjl_strongify(videoView);
        [videoView handleSingleTapGesture:point];
    }];
    [videoWindow setVideoWindowCloseCallback:^(NSString *mediaID) {
        bjl_strongify(self);
        [self.displayingVideoWindows bjl_removeObjectForKey:mediaID];
        BJLIcUserMediaInfoView *view = nil;
        if (BJLIcTemplateType_userVideoDownside == self.room.roomInfo.interactiveClassTemplateType) {
            if (self.updateTeacherMediaInfoViewCallback) {
                view = self.updateTeacherMediaInfoViewCallback(NO, mediaID);
            }
        }
        if (!view) {
            [self.videoListViewController sendUserBackToSeatWithMediaID:mediaID];
        }
    }];
    
    [videoWindow setWindowUpdateCallback:^(NSString * _Nonnull action, CGRect relativeRect) {
        bjl_strongify(self);
        BJLWindowDisplayInfo *oldDisplayInfo;
        for (BJLWindowDisplayInfo *displayInfo in [self.videoWindowDisplayInfos copy]) {
            if ([displayInfo.ID isEqualToString:mediaID]) {
                oldDisplayInfo = displayInfo;
                break;
            }
        }
        if (oldDisplayInfo) {
            [self.mutableVideoWindowDisplayInfos removeObject:oldDisplayInfo];
        }
        if (![action isEqualToString:BJLWindowsUpdateAction_close]) {
            BOOL shouldKeepFullScreen = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                         && ![action isEqualToString:BJLWindowsUpdateAction_maximize]);
            BOOL shouldCKeepMaximize = (![action isEqualToString:BJLWindowsUpdateAction_restore]
                                        && ![action isEqualToString:BJLWindowsUpdateAction_fullScreen]);
            BJLWindowDisplayInfo *newDisplayInfo = ({
                BJLWindowDisplayInfo *info = [[BJLWindowDisplayInfo alloc] init];
                info.ID = mediaID;
                info.x = CGRectGetMinX(relativeRect);
                info.y = CGRectGetMinY(relativeRect);
                info.width = CGRectGetWidth(relativeRect);
                info.height = CGRectGetHeight(relativeRect);
                info.isFullScreen = ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]
                                     || (oldDisplayInfo.isFullScreen && shouldKeepFullScreen));
                info.isMaximized = ([action isEqualToString:BJLWindowsUpdateAction_maximize]
                                    || (oldDisplayInfo.isMaximized && shouldCKeepMaximize));
                info;
            });
            [self.mutableVideoWindowDisplayInfos bjl_addObject:newDisplayInfo];
        }
        
        self.videoWindowDisplayInfos = self.mutableVideoWindowDisplayInfos;
        [self.room.playingVM updateVideoWindowWithMediaID:mediaID
                                                   action:action
                                             displayInfos:self.videoWindowDisplayInfos];
    }];
    
    [self bjl_observe:BJLMakeMethod(self, setFullscreenParentViewController:superview:)
             observer:^BOOL{
                 bjl_strongify(self, videoWindow);
                 [videoWindow setFullscreenParentViewController:self.fullscreenParentViewController
                                                      superview:self.fullscreenSuperview];
                 return YES;
             }];
    
    if (requestUpdate) {
        [videoWindow open];
    }
    else {
        [videoWindow openWithoutRequest];
    }
    [self.displayingVideoWindows bjl_setObject:videoWindow forKey:mediaID];
    return videoWindow;
}

#pragma mark - touch move

- (void)setupTouchMoveGesture {
    bjl_weakify(self);
    __block BJLIcUserMediaInfoView *touchMovingVideoView;
    __block CGRect transformOriginFrame = CGRectZero;
    UIPanGestureRecognizer *panGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if (gesture.state == UIGestureRecognizerStateBegan) {
            BJLIcUserMediaInfoView *videoView = [self.videoListViewController mediaInfoViewWithPanGesture:gesture];
            if (videoView) {
                CGRect originFrame = [self.view convertRect:videoView.frame fromView:videoView.superview];
                [videoView removeFromSuperview];
                
                [self.view addSubview:videoView];
                // 视图放大为 1.1 倍，同时保持不超出边界
                CGFloat sizeScale = 1.1;
                transformOriginFrame = bjl_set(originFrame, {
                    set.origin.x -= set.size.width * (sizeScale - 1.0) / 2.0;
                    set.origin.y -= set.size.height * (sizeScale - 1.0) / 2.0;
                    set.size.width *= sizeScale;
                    set.size.height *= sizeScale;
                    
                    set.origin.x = MIN(MAX(0.0, set.origin.x), CGRectGetMaxX(self.view.bounds));
                    set.origin.y = MIN(MAX(0.0, set.origin.y), CGRectGetMaxY(self.view.bounds));
                });
                // !!!: 这里设置初始 frame 再添加自动布局，防止 UIGestureRecognizerStateChanged 触发过快（使用 Apple Pencil 点击）时，自动布局没有完成
                videoView.frame = transformOriginFrame;
                
                [videoView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                    make.left.equalTo(self.view).offset(videoView.frame.origin.x).priorityHigh();
                    make.top.equalTo(self.view).offset(videoView.frame.origin.y).priorityHigh();
                    make.size.equal.sizeOffset(videoView.frame.size);
                    // 边界限制
                    make.top.left.greaterThanOrEqualTo(self.view);
                    make.bottom.right.lessThanOrEqualTo(self.view);
                }];
                
                touchMovingVideoView = videoView;
            }
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [gesture translationInView:gesture.view];
            
            // 更新偏移量
            CGFloat offsetX = transformOriginFrame.origin.x  + translation.x;
            CGFloat offsetY = transformOriginFrame.origin.y  + translation.y;
            
            // 修改当前 contentView 的位置
            [touchMovingVideoView bjl_updateConstraints:^(BJLConstraintMaker *make) {
                make.left.equalTo(self.view).offset(offsetX).priorityHigh();
                make.top.equalTo(self.view).offset(offsetY).priorityHigh();
            }];
        }
        else if (gesture.state == UIGestureRecognizerStateEnded) {
            if (touchMovingVideoView) {
                CGPoint center = [self.view convertPoint:touchMovingVideoView.center toView:self.videoListViewController.view];
                if ([self.videoListViewController.view pointInside:center withEvent:nil]) {
                    // 拖动后视图中心点仍未超出列表范围，将视图放回原位置
                    [self.videoListViewController sendUserBackToSeatWithMediaID:touchMovingVideoView.mediaID];
                }
                else {
                    [self displayVideoWindowWithVideoView:touchMovingVideoView requestUpdate:YES];
                }
            }
            touchMovingVideoView = nil;
            transformOriginFrame = CGRectZero;
        }
        else if (gesture.state == UIGestureRecognizerStateCancelled) {
            [self.videoListViewController sendUserBackToSeatWithMediaID:touchMovingVideoView.mediaID];
            touchMovingVideoView = nil;
            transformOriginFrame = CGRectZero;
        }
    }];
    panGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:panGesture];
    self.touchMoveGesture = panGesture;
    // 只有老师才可以把学生视频窗口拖到黑板区
    self.touchMoveGesture.enabled = self.room.loginUser.isTeacher;
}

#pragma mark - getters

@synthesize blackboardLayer = _blackboardLayer;
- (UIView *)blackboardLayer {
    if (!_blackboardLayer) {
        _blackboardLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, blackboardLayer);
            view.clipsToBounds = YES;
            [self.view addSubview:view];
            bjl_return view;
        });
    }
    return _blackboardLayer;
}

@synthesize videosLayer = _videosLayer;
- (UIView *)videosLayer {
    if (!_videosLayer) {
        _videosLayer = ({
            UIView *view = [BJLHitTestView new];
            view.accessibilityLabel = BJLKeypath(self, videosLayer);
            view.clipsToBounds = YES;
            [self.view addSubview:view];
            bjl_return view;
        });
    }
    return _videosLayer;
}

- (NSMutableDictionary<NSString *, BJLIcVideoWindowViewController *> *)displayingVideoWindows {
    if (!_displayingVideoWindows) {
        _displayingVideoWindows = [NSMutableDictionary dictionary];
    }
    return _displayingVideoWindows;
}

- (NSArray<BJLWindowDisplayInfo *> *)videoWindowDisplayInfos {
    if (!_videoWindowDisplayInfos) {
        _videoWindowDisplayInfos = [NSArray array];
    }
    return _videoWindowDisplayInfos;
}

- (NSMutableArray<BJLWindowDisplayInfo *> *)mutableVideoWindowDisplayInfos {
    if (!_mutableVideoWindowDisplayInfos) {
        _mutableVideoWindowDisplayInfos = [NSMutableArray array];
    }
    return _mutableVideoWindowDisplayInfos;
}

- (NSMutableDictionary<NSString *, BJLIcDocumentWindowViewController *> *)displayingDocumentWindows {
    if (!_displayingDocumentWindows) {
        _displayingDocumentWindows = [NSMutableDictionary dictionary];
    }
    return _displayingDocumentWindows;
}

- (NSMutableDictionary<NSString *,BJLIcWebDocumentWindowViewController *> *)displayingWebDocumentWindows {
    if (!_displayingWebDocumentWindows) {
        _displayingWebDocumentWindows = [NSMutableDictionary dictionary];
    }
    return _displayingWebDocumentWindows;
}

- (NSArray<BJLWindowDisplayInfo *> *)documentWindowDisplayInfos {
    if (!_documentWindowDisplayInfos) {
        _documentWindowDisplayInfos = [NSArray array];
    }
    return _documentWindowDisplayInfos;
}

- (NSMutableArray<BJLWindowDisplayInfo *> *)mutableDocumentWindowDisplayInfos {
    if (!_mutableDocumentWindowDisplayInfos) {
        _mutableDocumentWindowDisplayInfos = [NSMutableArray array];
    }
    return _mutableDocumentWindowDisplayInfos;
}

- (NSArray<BJLWindowDisplayInfo *> *)webDocumentWindowDisplayInfos {
    if (!_webDocumentWindowDisplayInfos) {
        _webDocumentWindowDisplayInfos = [NSArray array];
    }
    return _webDocumentWindowDisplayInfos;
}

- (NSMutableArray<BJLWindowDisplayInfo *> *)mutableWebDocumentWindowDisplayInfos {
    if (!_mutableWebDocumentWindowDisplayInfos) {
        _mutableWebDocumentWindowDisplayInfos = [NSMutableArray array];
    }
    return _mutableWebDocumentWindowDisplayInfos;
}

- (NSMutableDictionary <NSString *, BJLIcWritingBoradWindowViewController *> *)displayingWritingBoardWindows {
    if (!_displayingWritingBoardWindows) {
        _displayingWritingBoardWindows = [NSMutableDictionary dictionary];
    }
    return _displayingWritingBoardWindows;
}

- (NSArray<BJLWindowDisplayInfo *> *)writingBoardWindowDisplayInfos {
    if (!_writingBoardWindowDisplayInfos) {
        _writingBoardWindowDisplayInfos = [NSArray array];
    }
    return _writingBoardWindowDisplayInfos;
}

- (NSMutableArray<BJLWindowDisplayInfo *> *)mutableWritingBoardWindowDisplayInfos {
    if (!_mutableWritingBoardWindowDisplayInfos) {
        _mutableWritingBoardWindowDisplayInfos = [NSMutableArray array];
    }
    return _mutableWritingBoardWindowDisplayInfos;
}

@end

NS_ASSUME_NONNULL_END
