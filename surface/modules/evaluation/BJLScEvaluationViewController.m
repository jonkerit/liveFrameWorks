//
//  BJLScEvaluationViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScEvaluationViewController.h"
#import "BJLScAppearance.h"

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

@interface BJLScEvaluationViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (nonatomic) NSURLRequest *request;
@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic) UIView *progressView;
@property (nonatomic) UIButton *reloadButton, *closeButton;

@end

@implementation BJLScEvaluationViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithConfiguration:({
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsInjection
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                       forMainFrameOnly:YES];
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        configuration.userContentController = [WKUserContentController new];
        [configuration.userContentController addUserScript:userScript];
        [configuration.userContentController addScriptMessageHandler:self.wtfScriptMessageHandler
                                                                name:@(jsLog)];
        [configuration.userContentController addScriptMessageHandler:self.wtfScriptMessageHandler
                                                                name:@(jsWebView)];
        [configuration.userContentController addScriptMessageHandler:self.wtfScriptMessageHandler
                                                                name:@(jsMessage)];
        configuration;
    })];
    if (self) {
        self.room = room;
        self.request = [self.room.roomVM evaluationRequest];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.cornerRadius = 8.0;
    self.view.layer.masksToBounds = YES;
    
    self.userAgentSuffix = [BJLUserAgent defaultInstance].sdkUserAgent;
    
    self.progressView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_blueBrandColor];
        view;
    });
    
    self.reloadButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"加载失败，点击重试" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_lightGrayTextColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor whiteColor];
        button;
    });
    
    self.closeButton = ({
        UIButton *button = [BJLButton makeTextButtonDestructive:NO];
        [button setTitle:@"关闭" forState:UIControlStateNormal];
        button;
    });
    
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.webView, estimatedProgress)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.progressView.superview) {
                 [self.progressView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                     make.left.top.equalTo(self.view);
                     make.width.equalTo(self.view).multipliedBy(self.webView.estimatedProgress);
                     make.height.equalTo(@(BJLOnePixel));
                 }];
             }
             return YES;
         }];
    
    [self.reloadButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [self.webView stopLoading];
        [self.webView loadRequest:self.request];
    }];
    
    [self.closeButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        UIAlertController *alert = [UIAlertController bjl_lightAlertControllerWithTitle:@"提示"
                                                                       message:@"确认关闭课后评价？"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert bjl_addActionWithTitle:@"确认"
                                style:UIAlertActionStyleDestructive
                              handler:^(UIAlertAction * _Nonnull action) {
                                  bjl_strongify(self);
                                  [self.webView stopLoading];
                                  if (self.closeEvaluationCallback) self.closeEvaluationCallback();
                              }];
        [alert bjl_addActionWithTitle:@"取消"
                                style:UIAlertActionStyleCancel
                              handler:nil];
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
    NSLog(@"[evalution] request: %@", self.request.URL);
    [self.webView loadRequest:self.request];
}

#pragma mark -

- (void)forwardQuizMessage:(NSDictionary<NSString *, id> *)message {
    NSString *js = [NSString stringWithFormat:@"bjlapp.receivedMessage(%@)", ({
        NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:NULL];
        NSString *json = data.length ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        bjl_return json;
    })];
    NSLog(@"[evalution] %@", js);
    // bjl_weakify(self);
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        // bjl_strongify(self);
        NSLog(@"[evalution] return: %@ || %@", result, error);
    }];
}

#pragma mark - loading state

- (void)didStartLoading {
    [self.view addSubview:self.progressView];
    [self.progressView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(self.webView.estimatedProgress);
        make.height.equalTo(@(BJLOnePixel));
    }];
    
    [self.reloadButton removeFromSuperview];
}

- (void)didFailLoading {
    [self.progressView removeFromSuperview];
    
    [self.view addSubview:self.reloadButton];
    [self.reloadButton bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)didFinishLoading {
    [self.progressView removeFromSuperview];
}

#pragma mark - <WKNavigationDelegate>

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"[evalution] didStartProvisionalNavigation: %@", navigation);
    [self didStartLoading];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"[evalution] didFailProvisionalNavigation: %@ || %@", navigation, error);
    [self didFailLoading];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"[evalution] didFailNavigation: %@ || %@", navigation, error);
    [self didFailLoading];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"[evalution] didFinishNavigation: %@", navigation);
    [self didFinishLoading];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    else {
        if (navigationAction.targetFrame == nil) {
            [webView loadRequest:navigationAction.request];
        }
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        disposition = NSURLSessionAuthChallengeUseCredential;
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark - <WKUIDelegate>

#pragma mark - <WKScriptMessageHandler>

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"[evalution] %@.postMessage(%@)", message.name, message.body);
    
    if (message.webView != self.webView) {
        return;
    }
    
    if ([message.name isEqualToString:@(jsWebView)]) {
        NSString *action = message.body;
        if ([action isEqualToString:@(jsWebViewClose)]) {
            if (self.closeEvaluationCallback) self.closeEvaluationCallback();
        }
        return;
    }
}

@end
