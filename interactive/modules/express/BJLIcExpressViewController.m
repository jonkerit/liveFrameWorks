//
//  BJLIcExpressViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/8/15.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#define _jsExpressReportList "emotionReport"

static NSString * const jsInjection = @
"(function() {\n"
"    var bridge = this.bridge = this.bridge || {};\n"
"    bridge.send = function(message) {\n"
"        switch(message.key) {\n"
"            case '" _jsExpressReportList "':\n"
"                window.webkit.messageHandlers." _jsExpressReportList ".postMessage(message.value);\n"
"                break;\n"
"            default:\n"
"                break;\n"
"        }\n"
"    }\n"
#if DEBUG
"    bridge.send({name: 'log', data: 'injected'});\n"
#endif
"})();\n";

static NSString *cellReuseIdentifier = @"expressReportUser";

#import "BJLIcExpressViewController.h"
#import "BJLIcAppearance.h"
#import "BJLIcExpressUserTableViewCell.h"
#import "BJLIcExpress.h"

@interface BJLIcExpressViewController () <WKNavigationDelegate, UITableViewDelegate, UITableViewDataSource, WKScriptMessageHandler>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) NSURLRequest *request;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) UIView *contentView;

@property (nonatomic) UIView *topView;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *shareButton;
@property (nonatomic) UIView *bottomView;
@property (nonatomic) UIButton *prevButton, *nextButton;
@property (nonatomic) UIButton *userNameButton;

@property (nonatomic) NSArray<BJLIcExpress *> *expressList;
@property (nonatomic) BOOL pageLoaded;
@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL enableShareCurrentUser;
@property (nonatomic) UIView *overlayView;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *tableViewLabel;
@property (nonatomic) UIButton *closeTableViewButton;
@property (nonatomic) UITableView *tableView;

@end

@implementation BJLIcExpressViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithConfiguration:({
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsInjection
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                       forMainFrameOnly:YES];
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        configuration.userContentController = [WKUserContentController new];
        [configuration.userContentController addUserScript:userScript];
        [configuration.userContentController addScriptMessageHandler:self.wtfScriptMessageHandler
                                                                name:@(_jsExpressReportList)];
        configuration;
    })];
    if (self) {
        self.room = room;
        self.index = 0;
        self.pageLoaded = NO;
        self.enableShareCurrentUser = NO;
        [self makeObserving];
    }
    return self;
}

- (void)dealloc {
    [self stopTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif
    [self makeSubviewsAndConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self loadWebView];
}

#pragma mark - subview

- (void)makeSubviewsAndConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    self.contentView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.userInteractionEnabled = YES;
        view;
    });
    [self.view addSubview:self.contentView];
    if (iPhone) {
        [self.contentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.view);
        }];
    }
    else {
        self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        [self.contentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.top.bottom.equalTo(self.view);
            make.width.equalTo(self.contentView.bjl_height).multipliedBy(9.0/16.0);
        }];
    }
    
    [self.webView bjl_removeAllConstraints];
    [self.webView removeFromSuperview];
    [self.contentView addSubview:self.webView];
    [self.webView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView);
    }];
    
    self.topView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#3D4D69" alpha:0.3];
        view;
    });
    [self.contentView addSubview:self.topView];
    [self.topView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.top.equalTo(self.contentView);
        make.height.equalTo(@40.0);
    }];
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label;
    });
    [self.topView addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.topView);
        make.height.equalTo(@22.0);
    }];
    self.closeButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"window_close"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.topView addSubview:self.closeButton];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView.bjl_safeAreaLayoutGuide ?: self.contentView).offset(4.0);
        make.centerY.equalTo(self.topView);
        make.height.width.equalTo(@32.0);
    }];
    self.shareButton = ({
        UIButton *button = [UIButton new];
        button.hidden = YES;
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"express_share"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.topView addSubview:self.shareButton];
    [self.shareButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.contentView.bjl_safeAreaLayoutGuide ?: self.contentView).offset(4.0);
        make.centerY.equalTo(self.topView);
        make.width.height.equalTo(@40.0);
    }];
    if (self.room.loginUser.isTeacherOrAssistant) {
        self.bottomView = ({
            UIView *view = [UIView new];
            view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
            view;
        });
        [self.contentView addSubview:self.bottomView];
        [self.bottomView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.bottom.equalTo(self.contentView);
            make.height.equalTo(@40.0);
        }];
        self.prevButton = ({
            UIButton *button = [UIButton new];
            button.enabled = NO;
            button.backgroundColor = [UIColor clearColor];
            [button setImage:[UIImage bjlic_imageNamed:@"window_prevpage_black"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(prevReport) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.bottomView addSubview:self.prevButton];
        [self.prevButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.contentView.bjl_safeAreaLayoutGuide ?: self.contentView).offset(16.0);
            make.centerY.equalTo(self.bottomView);
            make.width.height.equalTo(@24.0);
        }];
        self.nextButton = ({
            UIButton *button = [UIButton new];
            button.enabled = NO;
            button.backgroundColor = [UIColor clearColor];
            [button setImage:[UIImage bjlic_imageNamed:@"window_nextpage_black"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(nextReport) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.bottomView addSubview:self.nextButton];
        [self.nextButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.equalTo(self.contentView.bjl_safeAreaLayoutGuide ?: self.contentView).offset(-16.0);
            make.centerY.equalTo(self.bottomView);
            make.width.height.equalTo(@24.0);
        }];
        self.userNameButton = ({
            UIButton *button = [UIButton new];
            button.backgroundColor = [UIColor clearColor];
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            button.titleLabel.font = [UIFont systemFontOfSize:14.0];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(showOverlayView) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self.bottomView addSubview:self.userNameButton];
        [self.userNameButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.equalTo(self.bottomView);
            make.left.equalTo(self.prevButton.bjl_right);
            make.right.equalTo(self.nextButton.bjl_left);
        }];
    }
    [self updateSubviews];
}

- (void)showOverlayView {
    if (self.overlayView) {
        self.overlayView.hidden = NO;
        self.containerView.hidden = NO;
        [self.tableView reloadData];
        return;
    }
    // 如果没有数据反馈，列表仅展示当前用户
    if (self.expressList.count <= 0) {
        self.expressList = @[[self expressWithLoginUser]];
    }
    self.overlayView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#3D4D69" alpha:0.3];
        view.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOverlayView)];
        [view addGestureRecognizer:tapGesture];
        view;
    });
    [self.contentView addSubview:self.overlayView];
    [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.contentView);
    }];
    self.containerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view;
    });
    [self.contentView addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self.overlayView);
        make.height.equalTo(self.overlayView).multipliedBy(0.667);
    }];
    self.tableViewLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont boldSystemFontOfSize:14.0];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"选择学生";
        label;
    });
    [self.containerView addSubview:self.tableViewLabel];
    [self.tableViewLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(13.0);
        make.height.equalTo(@25.0);
    }];
    self.closeTableViewButton = ({
        UIButton *button = [BJLImageButton new];
        button.backgroundColor = [UIColor clearColor];
        [button addTarget:self action:@selector(hideOverlayView) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage bjlic_imageNamed:@"express_close"] forState:UIControlStateNormal];
        button;
    });
    [self.containerView addSubview:self.closeTableViewButton];
    [self.closeTableViewButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.containerView).offset(5.0);
        make.right.equalTo(self.containerView).offset(-10.0);
        make.width.height.equalTo(@32.0);
    }];
    self.tableView = ({
        UITableView *tableView = [UITableView new];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 42.0;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        [tableView registerClass:[BJLIcExpressUserTableViewCell class] forCellReuseIdentifier:cellReuseIdentifier];
        tableView;
    });
    [self.containerView addSubview:self.tableView];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.tableViewLabel.bjl_bottom);
        make.bottom.left.right.equalTo(self.containerView);
    }];
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, liveStarted)
         observer:^BOOL(NSNumber * _Nullable value, NSNumber * _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             // 从上课状态转变成下课状态
             if ([oldValue boolValue] && ![value boolValue]) {
                 // 老师触发生成报告
                 if (self.room.loginUser.isTeacher) {
                     [self.room.roomVM generateExpressReportWithCompletion:^(NSString * _Nullable ID, BJLError * _Nullable error) {
                         bjl_strongify(self);
                         if (error) {
                             if (self.showErrorMessageCallback) {
                                 self.showErrorMessageCallback(error.localizedFailureReason ?: error.localizedDescription);
                             }
                         }
                         else {
                             [self startTimer];
                         }
                     }];
                 }
                 else {
                     [self startTimer];
                 }
             }
             else if ([value boolValue]) {
                 [self stopTimer];
                 [self close];
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, index)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateSubviews];
             return YES;
         }];
}

#pragma mark - action

- (void)loadWebView {
    NSString *usrNumber = nil;
    if (self.expressList.count <= 0 || self.index > self.expressList.count - 1 ) {
        usrNumber = self.room.loginUser.number;
    }
    else {
        usrNumber = [self.expressList bjl_objectAtIndex:self.index].userNumber;
    }
    self.request = [self.room.roomVM expressReportRequestWithUserNumber:usrNumber];
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    if (self.request) {
        [self.webView stopLoading];
        [self.webView loadRequest:self.request];
    }
}

- (void)close {
    if (self.closeCallback) {
        self.closeCallback();
    }
}

- (void)share {
    if (self.shareCallback) {
        BJLIcExpress *express = [self.expressList bjl_objectAtIndex:self.index];
        self.shareCallback(self.request.URL.absoluteString, express.urlString, express.userName);
    }
}

- (void)updateSubviews {
    NSString *userName = nil;
    NSString *title = nil;
    BJLUserRole userRole = BJLUserRole_student;
    BJLIcExpress *express = [self.expressList bjl_objectAtIndex:self.index];
    if (express && ![express.userNumber isEqualToString:self.room.loginUser.number]) {
        userName = express.userName;
        title = @"TA的课程报告";
        userRole = express.userRole;
    }
    else {
        userName = self.room.loginUser.displayName;
        title = @"我的课程报告";
        userRole = self.room.loginUser.role;
    }
    switch (userRole) {
        case BJLUserRole_teacher:
            userName = [userName stringByAppendingString:@"（老师）"];
            break;
            
        case BJLUserRole_assistant:
            userName = [userName stringByAppendingString:@"（助教）"];
            break;
            
        default:
            break;
    }
    self.titleLabel.text = title;
    [self.userNameButton setTitle:userName forState:UIControlStateNormal];
    self.prevButton.enabled = self.index > 0 && self.expressList.count > 0;
    self.nextButton.enabled = self.index < self.expressList.count - 1 && self.expressList.count > 0;
    // 未设置分享回调不分享，没有 usernumber 数据不分享，当前登录用户没有报告不分享
    NSString *userNumber = [self.expressList bjl_objectAtIndex:self.index].userNumber;
    BOOL disableShare = !self.shareCallback
                        || !userNumber.length
                        || (!self.enableShareCurrentUser
                            && [userNumber isEqualToString:self.room.loginUser.number]);
    self.shareButton.hidden = disableShare;
}

- (void)hideOverlayView {
    self.overlayView.hidden = YES;
    self.containerView.hidden = YES;
}

- (void)prevReport {
    if (self.index <= 0 || self.expressList.count <=0) {
        return;
    }
    self.index --;
    [self loadWebView];
}

- (void)nextReport {
    if (self.index >= self.expressList.count - 1 || self.expressList.count <= 0) {
        return;
    }
    self.index ++;
    [self loadWebView];
}

#pragma mark - timer

- (void)startTimer {
    [self stopTimer];
    bjl_weakify(self);
    self.timer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        [self requestExpressExportProgress];
    }];
}

- (void)requestExpressExportProgress {
    bjl_weakify(self);
    [self.room.roomVM requestExpressReportProgressWithCompletion:^(BJLTaskStatus status, BJLError * _Nullable error) {
        bjl_strongify(self);
        switch (status) {
            case BJLTaskStatus_unknow:
            case BJLTaskStatus_failed:
            case BJLTaskStatus_timeOut: {
                if (self.showErrorMessageCallback) {
                    self.showErrorMessageCallback(@"表情报告生成失败");
                }
                [self stopTimer];
            }
                break;
                
            case BJLTaskStatus_processing: {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self startTimer];
                });
            }
                break;
                
            case BJLTaskStatus_finished: {
                if (self.showExpressExportCallback) {
                    self.showExpressExportCallback();
                }
            }
                break;
                
            default:
                break;
        }
    }];
}

- (void)stopTimer {
    if (self.timer || [self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - <WKNavigationDelegate>

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

#pragma mark - <WKScriptMessageHandler>

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"[express] %@.postMessage(%@)", message.name, message.body);
    
    if (message.webView != self.webView) {
        return;
    }
    
    
    /** UI 设计描述
     学生：教室内报告生成后，当前页面学生只允许查看本人“报告” 学生端本人没有生成报告 页面显示“表情空页面” 且不可分享
     老师：老师端可查看其他学生表情报告 翻页查看 本人和学生的有效的 表情报告 即：如果学生没有合适的表情 则在老师端不显示此学生
     老师端本人没有生成报告 显示“表情空页面” 且不可分享（方案二： 也可以不显示老师本人）
     助教：助教本人不提供表情报告 可翻页查看 老师和学生的有效的 表情报告 即：如果老师/学生没有合适的表情 则在助教端暂不显示
     */
    if ([message.name isEqualToString:@(_jsExpressReportList)] && !self.pageLoaded) {
        self.pageLoaded = YES;
        NSDictionary *list = [bjl_as(message.body, NSDictionary) bjl_dictionaryForKey:@"list"];
        NSMutableArray *array = [NSMutableArray new];
        for (NSString *key in list.allKeys) {
            NSArray *userDetail = [list bjl_arrayForKey:key];
            BJLIcExpress *express = [BJLIcExpress bjlyy_modelWithJSON:userDetail.firstObject];
            [array bjl_addObject:express];
            if ([express.userNumber isEqualToString:self.room.loginUser.number]) {
                self.enableShareCurrentUser = YES;
                self->_index = array.count - 1;
            }
        }
        // 如果自己的表情报告为空，需要增加自己的表情报告的空白页面到第一位，索引为0
        if (!self.enableShareCurrentUser) {
            // 助教没有报告， 但是需要加载 webview 才能获取数据，无法不显示报告页面，因此其他用户数据为空时加载空白页面，否则加载列表中第一个用户的表情报告
            if (self.room.loginUser.isAssistant && array.count > 0) {
                self.expressList = array;
                [self loadWebView];
            }
            else {
                [array bjl_insertObject:[self expressWithLoginUser] atIndex:0];
                self.expressList = array;
            }
        }
        else {
            self.expressList = array;
        }
        [self updateSubviews];
        return;
    }
}

- (BJLIcExpress *)expressWithLoginUser {
    BJLIcExpress *express = [BJLIcExpress new];
    express.userName = self.room.loginUser.displayName;
    express.userNumber = self.room.loginUser.number;
    express.userRole = self.room.loginUser.role;
    return express;
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.expressList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcExpressUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell updateWithName:[self.expressList bjl_objectAtIndex:indexPath.row].userName selected:(self.index == indexPath.row)];
    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.index = indexPath.row;
    [tableView reloadData];
    [self loadWebView];
    [self hideOverlayView];
}

#pragma mark - UIViewControllerRotation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone
            ? UIInterfaceOrientationMaskPortrait
            : UIInterfaceOrientationMaskAll);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone
            ? UIInterfaceOrientationPortrait
            : [UIApplication sharedApplication].statusBarOrientation);
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
