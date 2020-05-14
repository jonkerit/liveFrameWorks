//
//  BJLIcWindowViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-18.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveBase/BJLiveBase.h>

#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLWindowState) {
    BJLWindowState_closed,
    BJLWindowState_windowed,
    // BJLWindowState_minimized,
    BJLWindowState_maximized,
    BJLWindowState_fullscreen
};

@interface BJLIcWindowViewController : UIViewController

@property (nonatomic, readonly) BJLWindowState state;

@property (nonatomic, nullable, copy) void(^windowUpdateCallback)(NSString *action, CGRect relativeRect);
@property (nonatomic, nullable, copy) void (^singleTapGestureCallback)(CGPoint point);

- (void)setWindowedParentViewController:(UIViewController *)parentViewController
                              superview:(nullable UIView *)superview; // parentViewController.view

- (void)setFullscreenParentViewController:(UIViewController *)parentViewController
                                superview:(nullable UIView *)superview; // parentViewController.view

- (void)open;       // windowed
// - (void)minimize;   // minimized
- (void)maximize;   // maximized
- (void)fullscreen; // fullscreen
- (void)restore;    // windowed || maximized
- (void)close;      // closed
- (void)updateWithRelativeRect:(CGRect)relativeRect;
- (void)bringToFront;

- (void)openWithoutRequest;
- (void)maximizeWithoutRequest;
- (void)fullScreenWithoutRequest;
- (void)restoreWithoutRequest;
- (void)closeWithoutRequest;
- (void)bringToFrontWithoutRequest;
- (void)sendToBackWithoutRequest;

@end

NS_ASSUME_NONNULL_END
