//
//  BJLIcWebViewWindowViewController+protected.h
//  BJLiveUI
//
//  Created by HuangJie on 2019/10/28.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWebViewWindowViewController.h"

#ifndef BJLIcWebViewWindowViewController_protected_h
#define BJLIcWebViewWindowViewController_protected_h

@interface BJLIcWebViewWindowViewController () <WKNavigationDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic) NSString *urlString;
@property (nonatomic) BJLIcWebViewWindowLayout layout;

@property (nonatomic) BJLWebViewController *webViewController;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) UIView *controlsView;
@property (nonatomic) UIButton *refreshButton, *searchButton, *publishButton, *reloadButton;
@property (nonatomic) UIView *webPageEmptyView, *emptyContainerView, *emptyImageView, *overlayView, *searchContainerView;
@property (nonatomic) UITextField *searchTextField;
@property (nonatomic) UILabel *tipLabel, *emptyLabel, *failedTipLabel;
@property (nonatomic) UIViewController *tipViewController;
@property (nonatomic, weak) UIView *webViewFirstResponder;

- (void)prepareToOpen;
- (void)makeObserving;
- (void)hideProgressView;
- (WKWebViewConfiguration *)defaultConfiguration;

@end

#endif /* BJLIcWebViewWindowViewController_protected_h */
