//
//  BJLIcWebViewWindowViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase+UIKit.h>

#import "BJLIcWebViewWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcWebViewWindowViewController+protected.h"
#import "BJLIcAppearance.h"

@implementation BJLIcWebViewWindowViewController

- (instancetype)initWithURLString:(NSString *)urlString layout:(BJLIcWebViewWindowLayout)layout {
    if (self = [super init]) {
        self.layout = layout;
        self.urlString = urlString;
        self.caption = @"网页";
        [self prepareToOpen];
    }
    return self;
}

- (void)prepareToOpen {
    self.fixedAspectRatio = 0.0;
    CGFloat relativeWidth = 0.6;
    CGFloat relativeHeight = [self relativeHeightWithRelativeWidth:0.6 width:720.0 height:424.0];
    self.relativeRect = [self rectInBounds:CGRectMake(0.2, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
    self.minWindowHeight = 160.0;
    self.minWindowWidth = 160.0;
    [self setWindowGesturesEnabled:YES];
    [self setWindowInterfaceEnabled:YES];
    if (self.layout == BJLIcWebViewWindowLayout_normal) {
        self.topBarBackgroundViewHidden = NO;
        self.bottomBarBackgroundViewHidden = YES;
        self.resizeHandleImageViewHidden = YES;
        self.maximizeButtonHidden = NO;
        self.fullscreenButtonHidden = NO;
        self.closeButtonHidden = YES;
        self.doubleTapToMaximize = NO;
    }
    else {
        self.topBarBackgroundViewHidden = NO;
        self.bottomBarBackgroundViewHidden = NO;
        self.resizeHandleImageViewHidden = YES;
        self.maximizeButtonHidden = NO;
        self.fullscreenButtonHidden = NO;
        self.closeButtonHidden = NO;
        self.doubleTapToMaximize = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviews];
    [self makeObserving];
    self.forgroundView.userInteractionEnabled = NO;
    [self loadWebView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 仅用于通知上一层是否也要显示一个 overlay 来隐藏键盘，无论上层有没有，控制器内始终会显示一个 overlay
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self hideKeyboardView];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidChangeFrameNotification
                                                  object:nil];
}

- (void)keyboardChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    CGRect keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
    self.webViewFirstResponder = [self.webViewController.webView bjl_firstResponder];
    if (self.webViewFirstResponder && self.keyboardFrameChangeCallback) {
        self.keyboardFrameChangeCallback(keyboardFrame);
    }
    if ([self.searchTextField isFirstResponder] && self.keyboardFrameChangeCallback) {
        self.keyboardFrameChangeCallback(keyboardFrame);
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.controlsView bjlic_drawBorderWidth:1.0 borderColor:[UIColor colorWithWhite:1.0 alpha:0.3] position:BJLIcRectPosition_top | BJLIcRectPosition_bottom];
}

- (void)makeSubviews {
    
    UITapGestureRecognizer *tapGesture = ({
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardView)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture;
    });
    
    // top bar
    [self.topBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
    }];
    
    // overlay
    self.overlayView = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = YES;
        view.backgroundColor = [UIColor clearColor];
        [view addGestureRecognizer:tapGesture];
        view.accessibilityLabel = BJLKeypath(self, overlayView);
        view;
    });
    
    // controls View
    self.controlsView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, controlsView);
        view;
    });
    [self.view addSubview:self.controlsView];
    [self.controlsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.topBar.bjl_bottom);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
    }];
    
    self.refreshButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, refreshButton);
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"window_refresh_enable"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"window_refresh_disable"] forState:UIControlStateDisabled];
        [button addTarget:self action:@selector(loadWebView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.controlsView addSubview:self.refreshButton];
    [self.refreshButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.controlsView);
        make.left.equalTo(self.view);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].buttonSize));
    }];
    
    self.searchContainerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, searchContainerView);
        view.layer.cornerRadius = 16.0;
        view.layer.masksToBounds = YES;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.controlsView addSubview:self.searchContainerView];
    [self.searchContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.refreshButton.bjl_right).offset(8.0);
        make.right.equalTo(self.view.bjl_right).offset(-12.0);
        make.centerY.equalTo(self.controlsView);
        make.height.equalTo(@32.0);
    }];
    
    self.searchButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, searchButton);
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"window_search"] forState:UIControlStateNormal];
        button;
    });
    [self.searchContainerView addSubview:self.searchButton];
    [self.searchButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.bottom.top.equalTo(self.searchContainerView);
        make.width.equalTo(self.searchButton.bjl_height);
    }];

    self.searchTextField = ({
        UIButton *clearTextButton = ({
            UIButton *button = [UIButton new];
            button.frame = CGRectMake(0, 0, 32.0, 32.0);
            [button setImage:[UIImage bjlic_imageNamed:@"window_cleartext"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        UITextField *textField = [UITextField new];
        textField.accessibilityLabel = BJLKeypath(self, searchTextField);
        textField.backgroundColor = [UIColor clearColor];
        NSAttributedString *messageAttributedText = [[NSAttributedString alloc] initWithString:@"请输入网页地址"
                                                                                    attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                                                                                 NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.3]}];
        textField.attributedPlaceholder = messageAttributedText;
        textField.textColor = [UIColor whiteColor];
        textField.returnKeyType = UIReturnKeyGo;
        textField.rightView = clearTextButton;
        textField.rightViewMode = UITextFieldViewModeWhileEditing;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.font = [UIFont systemFontOfSize:14.0];
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.enablesReturnKeyAutomatically = YES;
        textField.delegate = self;
        textField;
    });
    [self.searchContainerView addSubview:self.searchTextField];
    [self.searchTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.searchButton.bjl_right);
        make.top.bottom.right.equalTo(self.searchContainerView);
    }];
    
    // web view
    self.webViewController = ({
        BJLWebViewController *webViewViewController = [[BJLWebViewController alloc] initWithConfiguration:[self defaultConfiguration]];
        webViewViewController.webView.navigationDelegate = self;
        webViewViewController.view.hidden = YES;
        webViewViewController;
    });
    [self setContentViewController:self.webViewController contentView:nil];
    
    self.progressView = ({
        UIProgressView *progressView = [UIProgressView new];
        progressView.trackTintColor = [UIColor clearColor];
        progressView.progressTintColor = [UIColor blueColor];
        progressView.accessibilityLabel = BJLKeypath(self, progressView);
        progressView;
    });
    [self.webViewController.view addSubview:self.progressView];
    [self.progressView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.webViewController.view);
        make.height.equalTo(@2.0);
    }];
    
    // empty view
    self.webPageEmptyView = ({
        UIScrollView *view = [UIScrollView new];
        view.backgroundColor = [UIColor clearColor];
        view.showsVerticalScrollIndicator = NO;
        view.showsHorizontalScrollIndicator = NO;
        view.accessibilityLabel = BJLKeypath(self, webPageEmptyView);
        view;
    });
    [self.view addSubview:self.webPageEmptyView];
    [self.webPageEmptyView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.webViewController.view);
        make.bottom.equalTo(self.bottomBar.bjl_top);
    }];
    
    self.emptyContainerView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, emptyContainerView);
        view;
    });
    [self.webPageEmptyView addSubview:self.emptyContainerView];
    [self.emptyContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.webPageEmptyView);
        make.left.right.equalTo(@[self.view, self.webPageEmptyView]);
    }];
    
     self.emptyImageView = ({
        UIImageView *imageView = [UIImageView new];
         imageView.accessibilityLabel = BJLKeypath(self, emptyImageView);
        imageView.image = [UIImage bjlic_imageNamed:@"window_webpage_empty"];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.emptyContainerView addSubview:self.emptyImageView];
    
    self.emptyLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, emptyLabel);
        label.backgroundColor = [UIColor clearColor];
        label.text = @"还没有打开网页";
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.emptyContainerView addSubview:self.emptyLabel];

    
    self.failedTipLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, failedTipLabel);
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        label.numberOfLines = 2;
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 4.0;
        paragraphStyle.paragraphSpacing = 4.0;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSAttributedString *messageAttributedText = [[NSAttributedString alloc] initWithString:@"哎呀，该网页无法访问"
                                                                                attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                                                                             NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                                             NSParagraphStyleAttributeName : paragraphStyle}];
        NSAttributedString *tipAttributedText = [[NSAttributedString alloc] initWithString:@"\n请检查地址是否正确"
                                                                                attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12.0],
                                                                                             NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.5],
                                                                                             NSParagraphStyleAttributeName : paragraphStyle}];
        [attributedText appendAttributedString:messageAttributedText];
        [attributedText appendAttributedString:tipAttributedText];
        label.attributedText = attributedText;
        label;
    });
    [self.emptyContainerView addSubview:self.failedTipLabel];
    
    self.reloadButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, reloadButton);
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        [button setTitle:@"重新加载" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(loadWebView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.emptyContainerView addSubview:self.reloadButton];
    
    // bottom bar
    [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(40.0));
    }];
    
    self.publishButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, publishButton);
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"发布" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"收回" forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(updateWebViewPublish) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.bottomBar addSubview:self.publishButton];
    
    self.tipLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, tipLabel);
        label.text = @"发布后学生才可查看网页哦～";
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont systemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentRight;
        label;
    });
    [self.bottomBar addSubview:self.tipLabel];
    
    [self remakeConstraintsWithLayout:self.layout];

}

- (void)remakeConstraintsWithLayout:(BJLIcWebViewWindowLayout)layout {
    [self hideKeyboardView];
    switch (layout) {
        case BJLIcWebViewWindowLayout_normal: {
            self.controlsView.hidden = YES;
            self.tipLabel.hidden = YES;
            
            [self.webViewController.view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.equalTo(self.topBar.bjl_bottom);
                make.left.bottom.right.equalTo(self.view);
            }];
            [self.publishButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.bottomBar).offset(-12.0);
                make.top.equalTo(self.bottomBar).inset(8.0);
                make.width.equalTo(@80.0);
                make.height.equalTo(@0.0);
            }];
            [self.tipLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.publishButton.bjl_left).offset(-12.0);
                make.bottom.equalTo(self.bottomBar);
                make.height.equalTo(@0.0);
                make.left.greaterThanOrEqualTo(self.bottomBar);
            }];
            [self updateWebEmptyView:YES];
            return;
        }
            
        case BJLIcWebViewWindowLayout_unpublish: {
            self.controlsView.hidden = NO;
            self.publishButton.selected = NO;
            self.tipLabel.hidden = NO;
            
            [self.webViewController.view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.equalTo(self.controlsView.bjl_bottom);
                make.bottom.equalTo(self.bottomBar.bjl_top);
                make.left.right.equalTo(self.view);
            }];
            [self.publishButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.bottomBar).offset(-12.0);
                make.top.bottom.equalTo(self.bottomBar).inset(8.0);
                make.width.equalTo(@80.0);
            }];
            [self.tipLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.publishButton.bjl_left).offset(-12.0);
                make.top.bottom.equalTo(self.bottomBar);
                make.left.greaterThanOrEqualTo(self.bottomBar);
            }];
            [self updateWebEmptyView:NO];
            return;
        }
            
        case BJLIcWebViewWindowLayout_publish: {
            self.controlsView.hidden = YES;
            self.publishButton.selected = YES;
            self.tipLabel.hidden = YES;
            
            [self.webViewController.view bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.equalTo(self.topBar.bjl_bottom);
                make.bottom.equalTo(self.bottomBar.bjl_top);
                make.left.right.equalTo(self.view);
            }];
            [self.publishButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.bottomBar).offset(-12.0);
                make.top.bottom.equalTo(self.bottomBar).inset(8.0);
                make.width.equalTo(@80.0);
            }];
            [self.tipLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.publishButton.bjl_left).offset(-12.0);
                make.top.bottom.equalTo(self.bottomBar);
                make.left.greaterThanOrEqualTo(self.bottomBar);
            }];
            [self updateWebEmptyView:NO];
            return;
        }
            
        default:
            return;
    }
}

- (void)loadWebView {
    NSString *urlString = [self.urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    if (urlString.length) {
        NSURL *url = nil;
        BOOL needInsertProxy = YES;
        for (NSString *string in @[@"https://", @"http://", @"ftp://"]) {
            if ([[string commonPrefixWithString:urlString options:NSCaseInsensitiveSearch] compare:string options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                needInsertProxy = NO;
            }
        }
        // 默认添加 https
        if (needInsertProxy) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", urlString]];
        }
        else {
            url = [NSURL URLWithString:urlString];
        }
        [self.progressView setProgress:0.0 animated:NO];
        [self.webViewController.webView loadRequest:[[NSURLRequest alloc] initWithURL:url]];
        self.webViewController.view.hidden = NO;
        self.webPageEmptyView.hidden = YES;
    }
    else {
        [self.webViewController.webView stopLoading];
        self.webPageEmptyView.hidden = NO;
        self.webViewController.view.hidden = YES;
    }
}

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.webViewController.webView, estimatedProgress)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.progressView.hidden = NO;
             [self.progressView setProgress:[value doubleValue] animated:YES];
             return YES;
         }];
}

- (void)hideKeyboardView {
    if ([self.searchTextField isFirstResponder]) {
        [self.searchTextField resignFirstResponder];
    }
    else if ([self.webViewFirstResponder isFirstResponder]) {
        [self.webViewFirstResponder resignFirstResponder];
    }
    self.webPageEmptyView.userInteractionEnabled = YES;
    if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
        [self.overlayView removeFromSuperview];
    }
}

- (void)clearText {
    self.publishButton.enabled = NO;
    self.searchTextField.text = nil;
    self.urlString = nil;
}

- (void)hideWebView {
    self.webPageEmptyView.hidden = NO;
    [self.webViewController.webView stopLoading];
    self.webPageEmptyView.hidden = NO;
    self.webViewController.view.hidden = YES;
    [self hideProgressView];
}

- (void)hideProgressView {
    self.progressView.hidden = YES;
    [self.progressView setProgress:0.0 animated:NO];
}

- (void)updateWebViewPublish {
    BOOL publish = !self.publishButton.isSelected;
    if (self.publishWebViewCallback) {
        self.publishWebViewCallback(self.urlString, publish, NO);
    }
    if (publish) {
        [self remakeConstraintsWithLayout:BJLIcWebViewWindowLayout_publish];

        UIViewController *viewController = ({
            UIViewController *viewController = [[UIViewController alloc] init];
            viewController.view.backgroundColor = [UIColor clearColor];
            viewController.modalPresentationStyle = UIModalPresentationPopover;
            viewController.preferredContentSize = CGSizeMake(320.0, 40.0);
            viewController.popoverPresentationController.backgroundColor = [UIColor blackColor];
            viewController.popoverPresentationController.delegate = self;
            viewController.popoverPresentationController.sourceView = self.publishButton;
            viewController.popoverPresentationController.sourceRect = self.publishButton.bounds;
            viewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
            viewController;
        });
        UILabel *label = ({
            UILabel *label = [UILabel new];
            label.text = @"页面已发布给学生，访问其他页面请先收回";
            label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
            label.font = [UIFont systemFontOfSize:14.0];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
        [viewController.view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(viewController.view.bjl_safeAreaLayoutGuide ?: viewController.view);
        }];
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self presentViewController:viewController animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [viewController bjl_dismissAnimated:YES completion:nil];
        });
        self.tipViewController = viewController;
    }
    else {
        [self remakeConstraintsWithLayout:BJLIcWebViewWindowLayout_unpublish];
    }
}

- (void)updateWebEmptyView:(BOOL)loadFailed {
    if (loadFailed) {
        self.emptyLabel.hidden = YES;
        self.failedTipLabel.hidden = NO;
        self.reloadButton.hidden = NO;
        
        [self.emptyLabel removeFromSuperview];
        [self.emptyImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.emptyContainerView).offset(52.0);
            make.centerX.equalTo(self.webPageEmptyView);
            make.height.width.equalTo(@64.0);
        }];
        [self.failedTipLabel removeFromSuperview];
        [self.webPageEmptyView addSubview:self.failedTipLabel];
        [self.failedTipLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.emptyImageView);
            make.top.equalTo(self.emptyImageView.bjl_bottom).offset(12.0);
            make.height.equalTo(@40.0);
        }];
        [self.reloadButton removeFromSuperview];
        [self.webPageEmptyView addSubview:self.reloadButton];
        [self.reloadButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.emptyImageView);
            make.top.equalTo(self.failedTipLabel.bjl_bottom).offset(25.0);
            make.width.equalTo(@120.0);
            make.height.equalTo(@32.0);
            make.bottom.equalTo(self.emptyContainerView).offset(-80.0);
        }];
    }
    else {
        self.emptyLabel.hidden = NO;
        self.failedTipLabel.hidden = YES;
        self.reloadButton.hidden = YES;
        
        [self.failedTipLabel removeFromSuperview];
        [self.reloadButton removeFromSuperview];
        [self.emptyImageView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.emptyContainerView).offset(96.0);
            make.centerX.equalTo(self.webPageEmptyView);
            make.height.width.equalTo(@64.0);
        }];
        [self.emptyLabel removeFromSuperview];
        [self.webPageEmptyView addSubview:self.emptyLabel];
        [self.emptyLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(self.emptyImageView);
            make.top.equalTo(self.emptyImageView.bjl_bottom).offset(12.0);
            make.height.equalTo(@20.0);
            make.bottom.equalTo(self.emptyContainerView).offset(-124.0);
        }];
    }
}

#pragma mark - override

- (void)close {
    BOOL publish = self.publishButton.isSelected;
    if (publish) {
        if (self.closeWebViewCallback) {
            self.closeWebViewCallback();
        }
    }
    else {
        [self closeWebView];
    }
    [super close];
}

- (void)closeWebView {
    BOOL publish = self.publishButton.isSelected;
    if (self.publishWebViewCallback && publish) {
        self.publishWebViewCallback(nil, NO, YES);
    }
}

- (void)open {
    [self openWithoutRequest];
}

- (void)fullscreen {
    [self fullScreenWithoutRequest];
}

#pragma mark - webview delegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self hideProgressView];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self hideWebView];
    [self updateWebEmptyView:YES];
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
        self.urlString = webView.URL.absoluteString;
        self.searchTextField.text = self.urlString;
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self hideWebView];
    [self updateWebEmptyView:YES];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [self hideWebView];
    [self updateWebEmptyView:YES];
}

#pragma mark - textField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.searchTextField) {
        self.webPageEmptyView.userInteractionEnabled = NO;
        [self.view insertSubview:self.overlayView aboveSubview:self.forgroundView];
        [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.view);
        }];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ((textField == self.searchTextField) && [string isEqualToString:@"\n"]) {
        self.urlString = self.searchTextField.text;
        self.publishButton.enabled = self.urlString.length;
        [self hideKeyboardView];
        [self loadWebView];
        return NO;
    }
    return YES;
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - protected

- (WKWebViewConfiguration *)defaultConfiguration {
    return [WKWebViewConfiguration new];
}

@end
