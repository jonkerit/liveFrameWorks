//
//  BJLIcQuizWindowViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/8/30.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcQuizWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

#define jsLog           "log"
#define jsWebView       "webview"
#define jsWebViewClose      "close"
#define jsMessage       "message"

static NSString * const jsInjection = @
"(function() {\n"
"    var bjlapp = this.bjlapp = this.bjlapp || {};\n"
"    // APP implementation\n"
"    bjlapp.log = function(log) {\n"
"        window.webkit.messageHandlers." jsLog ".postMessage(log);\n"
"    };\n"
"    bjlapp.close = function() {\n"
"        window.webkit.messageHandlers." jsWebView ".postMessage('" jsWebViewClose "');\n"
"    };\n"
"    bjlapp.sendMessage = function(json) {\n"
"        window.webkit.messageHandlers." jsMessage ".postMessage(json);\n"
"    };\n"
"    // H5 implementation\n"
"    bjlapp.receivedMessage = bjlapp.receivedMessage || function(json) {\n"
"        // abstract\n"
"    };\n"
#if DEBUG
"    bjlapp.log('injected');\n"
#endif
"})();\n";

@interface BJLIcWTFScriptMessageHandler : NSObject <WKScriptMessageHandler, WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> handler;
@end
@implementation BJLIcWTFScriptMessageHandler
+ (instancetype)weakifyHandler:(id<WKScriptMessageHandler>)handler {
    BJLIcWTFScriptMessageHandler *wrapper = [self new];
    wrapper.handler = handler;
    return wrapper;
}
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([self.handler respondsToSelector:_cmd]) {
        [self.handler userContentController:userContentController didReceiveScriptMessage:message];
    }
}
@end

@interface BJLIcQuizWindowViewController ()<WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic) BOOL closable;
@property (nonatomic) BOOL finishLoading;
@property (nonatomic) NSURLRequest *request;
@property (nonatomic, nullable) NSMutableArray<NSDictionary<NSString *, id> *> *messages;

@property (nonatomic) WKWebView *webView;
@property (nonatomic) UIView *progressView;
@property (nonatomic) UIButton *reloadButton;

@end

@implementation BJLIcQuizWindowViewController

+ (nullable instancetype)instanceWithRoom:(BJLRoom *)room quizMessage:(NSDictionary<NSString *, id> *)message {
    NSString *messageType = [message bjl_stringForKey:@"message_type"];
    
    BOOL isQuizStart = [messageType isEqualToString:@"quiz_start"];
    BOOL isQuizResponse = [messageType isEqualToString:@"quiz_res"];
    BOOL isQuizSolution = [messageType isEqualToString:@"quiz_solution"];
    if (!isQuizStart && !isQuizResponse && !isQuizSolution) {
        return nil;
    }
    
    NSString *quizID = [message bjl_stringForKey:@"quiz_id"];
    BOOL quizEnd = [message bjl_boolForKey:@"end_flag"];
    BOOL quizDid = [message bjl_dictionaryForKey:@"solution"].count > 0;
    if (isQuizResponse
        && (!quizID.length || quizEnd || quizDid)) {
        return nil;
    }
    
    NSURLRequest *request = [room.roomVM quizRequestWithID:quizID error:nil];
    if (!request) {
        return nil;
    }
    
    BOOL closable = !isQuizStart || ![message bjl_boolForKey:@"force_join"];
    
    return [[BJLIcQuizWindowViewController alloc] initWithMessage:message
                                                     request:request
                                                    closable:closable];
}

+ (NSDictionary *)quizReqMessageWithUserNumber:(NSString *)userNumber {
    return @{@"message_type": @"quiz_req",
             @"user_number":  userNumber ?: @""};
}

#pragma mark -

- (instancetype)initWithMessage:(NSDictionary<NSString *, id> *)message
                        request:(NSURLRequest *)request
                       closable:(BOOL)closable {
    if (self = [super init]) {
        self.request = request;
        self.closable = closable;
        self.finishLoading = NO;
        self.messages = [NSMutableArray new];
        [self.messages bjl_addObject:message];
        [self prepareToOpen];
    }
    return self;
}

- (void)prepareToOpen {
    self.caption = @"测验";
    
    self.fixedAspectRatio = 0.0;
    CGFloat relativeWidth = 0.6;
    CGFloat relativeHeight = [self relativeHeightWithRelativeWidth:0.6 width:720.0 height:424.0];
    self.relativeRect = [self rectInBounds:CGRectMake(0.2, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
    self.minWindowHeight = 160.0;
    self.minWindowWidth = 360.0;
    [self setWindowGesturesEnabled:YES];
    [self setWindowInterfaceEnabled:YES];
    self.topBarBackgroundViewHidden = NO;
    self.bottomBarBackgroundViewHidden = NO;
    self.resizeHandleImageViewHidden = YES;
    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.closeButtonHidden = NO;
    self.doubleTapToMaximize = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.forgroundView.hidden = YES;
    // top bar
    [self.topBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(32.0));
    }];
    
    [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(32.0));
    }];
    
    self.reloadButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"window_refresh_enable"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(loadWebView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.topBar addSubview:self.reloadButton];
    [self.reloadButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.topBar);
        make.right.equalTo(self.topBar.closeButton.bjl_left);
        make.width.equalTo(self.reloadButton.bjl_height);
    }];
    
    self.webView = ({
        BJLIcWTFScriptMessageHandler *handler = [BJLIcWTFScriptMessageHandler weakifyHandler:self];
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:({
            WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsInjection
                                                              injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                           forMainFrameOnly:YES];
            WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
            configuration.userContentController = [WKUserContentController new];
            [configuration.userContentController addUserScript:userScript];
            [configuration.userContentController addScriptMessageHandler:handler
                                                                    name:@(jsLog)];
            [configuration.userContentController addScriptMessageHandler:handler
                                                                    name:@(jsWebView)];
            [configuration.userContentController addScriptMessageHandler:handler
                                                                    name:@(jsMessage)];
            configuration;
        })];
        webView.navigationDelegate = self;
        webView.backgroundColor = [UIColor blackColor];
        webView.scrollView.backgroundColor = [UIColor clearColor];
        webView.opaque = NO;
        webView.scrollView.bounces = NO;
        webView;
    });
    [self setContentViewController:nil contentView:self.webView];
    [self.contentView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.topBar.bjl_bottom);
        make.bottom.equalTo(self.bottomBar.bjl_top);
        make.left.right.equalTo(self.view);
    }];
    
    // 小班课测验要求全部强制
    [self updateCloseButtonHidden:YES];
    [self loadWebView];
}

- (void)loadWebView {
    self.finishLoading = NO;
    [self.webView stopLoading];
    [self.webView loadRequest:self.request];
}

- (void)updateCloseButtonHidden:(BOOL)hidden {
    self.reloadButton.hidden = hidden;
    self.closeButtonHidden = hidden;
}

- (void)close {
    [self closeWithoutRequest];
}

- (void)closeWithoutRequest {
    if (self.closeButtonHidden) {
        [super closeWithoutRequest];
    }
    else {
        if (self.closeQuizCallback) {
            self.closeQuizCallback();
        }
    }
}

#pragma mark -

- (void)didReceiveQuizMessage:(NSDictionary<NSString *, id> *)message {
    // 支持刷新，因此将保留所有信令
    [self.messages bjl_addObject:message];
    if (self.finishLoading) {
        [self forwardQuizMessage:message];
    }
}

- (void)forwardQuizMessage:(NSDictionary<NSString *, id> *)message {
    NSString *messageType = [message bjl_stringForKey:@"message_type"];
    if ([messageType isEqualToString:@"quiz_solution"]) {
        [self updateCloseButtonHidden:NO];
    }
    NSString *js = [NSString stringWithFormat:@"bjlapp.receivedMessage(%@)", ({
        NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:NULL];
        NSString *json = data.length ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        bjl_return json;
    })];
    // bjl_weakify(self);
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        // bjl_strongify(self);
        NSLog(@"[quiz] return: %@ || %@", result, error);
    }];
}

#pragma mark - loading state

- (void)didFinishLoading {
    [self.progressView removeFromSuperview];
    
    NSArray<NSDictionary<NSString *, id> *> *messages = [self.messages copy];
    //self.messages = nil;
    
    for (NSDictionary<NSString *, id> *message in messages) {
        [self forwardQuizMessage:message];
    }
}

#pragma mark - <WKNavigationDelegate>

#if DEBUG
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if (completionHandler) {
        NSURLCredential *credential = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}
#endif

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    self.finishLoading = YES;
    [self didFinishLoading];
}

#pragma mark - <WKScriptMessageHandler>

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"[quiz] %@.postMessage(%@)", message.name, message.body);
    
    if (message.webView != self.webView) {
        return;
    }
    
    if ([message.name isEqualToString:@(jsMessage)]) {
        NSDictionary *json = bjl_as(message.body, NSDictionary);
        if (self.sendQuizMessageCallback) self.sendQuizMessageCallback(json);
        return;
    }
    
    if ([message.name isEqualToString:@(jsWebView)]) {
        NSString *action = message.body;
        if ([action isEqualToString:@(jsWebViewClose)]) {
            if (self.closeWebViewCallback) self.closeWebViewCallback();
        }
        return;
    }
}
@end
