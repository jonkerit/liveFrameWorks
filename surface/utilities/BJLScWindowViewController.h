//
//  BJLScWindowViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-18.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveBase/BJLiveBase.h>

#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLSWindowState) {
    BJLSWindowState_closed,
    BJLSWindowState_windowed,
    // BJLWindowState_minimized,
    BJLSWindowState_maximized,
    BJLSWindowState_fullscreen
};

@interface BJLScWindowViewController : UIViewController

@property (nonatomic, readonly) BJLSWindowState state;

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
