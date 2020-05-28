//
//  BJLIcWindowViewController+protected.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-19.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

#import "BJLIcWindowTopBar.h"
#import "BJLIcWindowBottomBar.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT const CGPoint BJLPointNull;

@interface BJLIcWindowViewController () {
    CGRect _tempFrame;
}

#pragma mark - protected

// contentView: content.contentViewController.view > content.contentView > content.view || content
// bottomView: bottomView
@property (nonatomic, readonly, nullable) UIViewController *contentViewController;
@property (nonatomic, readonly, nullable) UIView *contentView, *bottomView;
- (void)setContentViewController:(nullable UIViewController *)contentViewController
                     contentView:(nullable UIView *)contentView;
- (void)setBottomView:(nullable UIView *)bottomView;

/**
 state 是 maximized 和 fullscreen 时，relativeRect 和 fixedAspectRatio 值无效
 relativeRect: CGRectNull - 默认位置、尺寸
 relativeRect.origin: BJLPointNull - 默认位置(目前为左上角)
 relativeRect.size: CGSizeZero - 尺寸(目前宽、高均为 superview 宽度的 1/4)
 x, y, width, height 取值范围：0.0 - 1.0，表示相对 superview 的比例
 */
@property (nonatomic) CGRect relativeRect; // default: CGRectNull

@property (nonatomic) CGFloat fixedAspectRatio; // default: 0.0, effective if > 0.0, for resizing

@property (nonatomic, copy, nullable) NSString *caption; // default: nil
@property (nonatomic) BOOL windowInterfaceEnabled;

@property (nonatomic) BOOL topBarBackgroundViewHidden, bottomBarBackgroundViewHidden, resizeHandleImageViewHidden; // default: NO
@property (nonatomic) BOOL maximizeButtonHidden, fullscreenButtonHidden, closeButtonHidden; // default: NO
@property (nonatomic) BOOL tapToBringToFront, doubleTapToMaximize, panToMove, panToResize; // default: YES
@property (nonatomic) CGFloat minWindowWidth, minWindowHeight; // default: 200.0, 100.0

#pragma mark - private

@property (nonatomic, readonly, weak) UIViewController *windowedParentViewController;
@property (nonatomic, readonly, nullable) UIView *windowedSuperview;
@property (nonatomic, readonly, weak) UIViewController *fullscreenParentViewController;
@property (nonatomic, readonly, nullable) UIView *fullscreenSuperview;

@property (nonatomic, readonly) UIView *backgroundView, *forgroundView;
@property (nonatomic, readonly) BJLIcWindowTopBar *topBar;
@property (nonatomic, readonly) BJLIcWindowBottomBar *bottomBar;

@property (nonatomic) NSMutableArray<UIGestureRecognizer *> *windowGestures;

@end

@interface BJLIcWindowViewController (protected)

#pragma mark - protected

// dx: dimension x, dy: dimension y
- (CGFloat)relativeDxWithDx:(CGFloat)dx;
- (CGFloat)relativeDyWithDy:(CGFloat)dy;

- (CGFloat)relativeWidthWithRelativeHeight:(CGFloat)relativeHeight aspectRatio:(CGFloat)aspectRatio;
- (CGFloat)relativeHeightWithRelativeWidth:(CGFloat)relativeWidth aspectRatio:(CGFloat)aspectRatio;

// CGFloat aspectRatio = (CGFloat)width / (CGFloat)height
- (CGFloat)relativeWidthWithRelativeHeight:(CGFloat)relativeHeight width:(CGFloat)width height:(CGFloat)height;
- (CGFloat)relativeHeightWithRelativeWidth:(CGFloat)relativeWidth width:(CGFloat)width height:(CGFloat)height;

- (CGRect)rectInBounds:(CGRect)rect;

- (void)requestUpdateWithAction:(NSString *)action;
- (void)setWindowGesturesEnabled:(BOOL)enabled;

#pragma mark - private

- (void)addHandlers;

- (void)makeObserveringForWindowState;
- (void)makeObserveringForContainer;
- (void)moveToParentViewControllerAndSuperview;

- (void)makeObserveringForContent;

@end

NS_ASSUME_NONNULL_END
