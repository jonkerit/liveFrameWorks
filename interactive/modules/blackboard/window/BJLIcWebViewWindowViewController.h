//
//  BJLIcWebViewWindowViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcWebViewWindowLayout) {
    BJLIcWebViewWindowLayout_normal,
    BJLIcWebViewWindowLayout_unpublish,
    BJLIcWebViewWindowLayout_publish,
};

@interface BJLIcWebViewWindowViewController : BJLIcWindowViewController

@property (nonatomic, nullable) void (^publishWebViewCallback)(NSString * _Nullable urlString, BOOL publish, BOOL close);
@property (nonatomic, nullable) void (^closeWebViewCallback)(void);
@property (nonatomic, nullable) void (^keyboardFrameChangeCallback)(CGRect keyboardFrame);

- (instancetype)initWithURLString:(nullable NSString *)urlString layout:(BJLIcWebViewWindowLayout)layout;
- (void)hideKeyboardView;
- (void)closeWebView;
- (void)remakeConstraintsWithLayout:(BJLIcWebViewWindowLayout)layout;

@end

NS_ASSUME_NONNULL_END
