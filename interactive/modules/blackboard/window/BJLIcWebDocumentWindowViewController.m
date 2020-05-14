//
//  BJLIcWebDocumentWindowViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2019/10/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWebDocumentWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcWebViewWindowViewController+protected.h"
#import "BJLIcAppearance.h"

#define _jsDoc "bjy_h5_doc"

static NSString * const jsInjection = @
"(function() {\n"
"    var bridge = this.bridge = this.bridge || {};\n"
"    bridge.send = function(message) {\n"
"        if (message.exception) {\n"
"            window.webkit.messageHandlers." _jsDoc ".postMessage(message.exception);\n"
"        }\n"
"        else if (message.value) {\n"
"            window.webkit.messageHandlers." _jsDoc ".postMessage(message.value);\n"
"        }\n"
"    }\n"
#if DEBUG
"    bridge.send({name: 'log', data: 'injected'});\n"
#endif
"})();\n";

@interface BJLIcWebDocumentWindowViewController () <WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic, readonly) NSString *documentID;

@end

@implementation BJLIcWebDocumentWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room webDocumentID:(NSString *)documentID {
    self = [super init];
    if (self) {
        BJLDocument *document = [room.documentVM webDocumentWithID:documentID];
        self->_room = room;
        self->_documentID = documentID;
        self.urlString = document.webDocumentURL;
        self.caption = document.fileName;
    }
    return self;
}

#pragma mark - override methods

- (void)makeObserving {
    [super makeObserving];
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
           filter:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
               return !!value;
           }
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL isTeacherOrAssistant = self.room.loginUser.isTeacherOrAssistant;
             self.layout = isTeacherOrAssistant ? BJLIcWebViewWindowLayout_publish : BJLIcWebViewWindowLayout_normal;
             [self prepareToOpen];
             [self setWindowGesturesEnabled:isTeacherOrAssistant];
             self.maximizeButtonHidden = !isTeacherOrAssistant;
             self.fullscreenButtonHidden = !isTeacherOrAssistant;
             if (isTeacherOrAssistant) {
                 self.webViewController.webView.userInteractionEnabled = YES;
             }
             else {
                 [self makeObservingForAuthority];
             }
             return YES;
        }];
    
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, allWebDocumentsDidOverwrite:)
             observer:^BOOL(NSArray<BJLDocument *> *allWebDocuments) {
                 bjl_strongify(self);
                 if (![self.room.documentVM webDocumentWithID:self.documentID]) {
                     [self close];
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didDeleteDocument:)
             observer:^BOOL(BJLDocument *document) {
                 bjl_strongify(self);
                 if ([self.documentID isEqualToString:document.documentID]) {
                     [self close];
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didReceiveWebDocumentMessage:documentID:isCache:)
             observer:(BJLMethodObserver)^BOOL(NSDictionary *message, NSString *documentID, BOOL isCache) {
                 bjl_strongify(self);
                 if ([documentID isEqualToString:self.documentID]) {
                     [self jsCallWithMessage:@{@"name" : @(_jsDoc),
                                               @"id" : documentID ?: @"",
                                               @"getCache" : @(isCache),
                                               @"value" : message ?: @{}}];
                 }
                 return YES;
             }];
}

- (void)makeObservingForAuthority {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, authorizedPPT)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
         bjl_strongify(self);
         self.webViewController.webView.userInteractionEnabled = self.room.documentVM.authorizedPPT;
         return YES;
    }];
}

- (void)setWindowGesturesEnabled:(BOOL)enabled {
    [super setWindowGesturesEnabled:enabled];
    self.topBar.hidden = NO;
}

- (void)open {
    [super open];
    [self requestUpdateWithAction:BJLWindowsUpdateAction_open];
}

- (void)close {
    if (self.webDocumentWindowCloseCallback) {
        self.webDocumentWindowCloseCallback(self.documentID);
    }
    [super close];
}

- (void)closeWithoutRequest {
    if (self.webDocumentWindowCloseCallback) {
        self.webDocumentWindowCloseCallback(self.documentID);
    }
    [super closeWithoutRequest];
}

- (void)fullscreen {
    [super fullscreen];
    [self requestUpdateWithAction:BJLWindowsUpdateAction_fullScreen];
}

- (WKWebViewConfiguration *)defaultConfiguration {
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsInjection
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                   forMainFrameOnly:YES];
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = [WKUserContentController new];
    configuration.allowsInlineMediaPlayback = YES;
    [configuration.userContentController addUserScript:userScript];
    [configuration.userContentController addScriptMessageHandler:[BJLWTFScriptMessageHandler weakifyHandler:self]
                                                            name:@(_jsDoc)];
    return configuration;
}

#pragma mark - <webview delegate>

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self hideProgressView];
    [self.room.documentVM requestWebDocumentMessageCache];
}

#pragma mark - <WKScriptMessageHandler>

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (message.webView != self.webViewController.webView) {
        return;
    }
    
    if ([message.name isEqualToString:@(_jsDoc)]) {
        NSDictionary *json = bjl_as(message.body, NSDictionary);
        if (json) {
            [self.room.documentVM sendWebDocumentMessage:json documentID:self.documentID];
        }
        return;
    }
}

- (void)jsCallWithMessage:(NSDictionary *)message {
    NSString *js = [NSString stringWithFormat:@"bridge.receive(%@)", ({
        NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:NULL];
        NSString *json = data.length ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        bjl_return json;
    })];
    [self.webViewController.webView evaluateJavaScript:js completionHandler:nil];
}

@end
