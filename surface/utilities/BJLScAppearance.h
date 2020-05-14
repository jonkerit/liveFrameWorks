//
//  BJLScAppearance.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

#define BJLScOnePixel ({ \
static CGFloat _BJLScOnePixel; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_BJLScOnePixel = 1.0 / [UIScreen mainScreen].scale; \
}); \
_BJLScOnePixel; \
})

#define BJLScViewSpaceS   5.0
#define BJLScViewSpaceM   10.0
#define BJLScViewSpaceL   15.0

#define BJLScControlSize  44.0

#define BJLScButtonSizeS  30.0
#define BJLScButtonSizeM  36.0
#define BJLScButtonSizeL  46.0
#define BJLScButtonCornerRadius 3.0
#define BJLScRedDotWidth 18.0

#define BJLScBadgeSize    20.0
#define BJLScScrollIndicatorSize 8.5 // 8.5 = 2.5 + 3.0 * 2

#define BJLScAnimateDurationS 0.2
#define BJLScAnimateDurationM 0.4
#define BJLScRobotDelayS  1.0
#define BJLScRobotDelayM  2.0
#define BJLScRainDelay 3.0

#define BJLScTopBarHeight 32.0
#define BJLScSegmentWidth 240.0

#define BJLScSmallOverlayImageSizeIPhone 40.0
#define BJLScSmallOverlayImageSizeIPad 72.0
#define BJLScLargeOverlayImageSize 240.0

#define userWindowDefaultBarHeight 24.0
#define blackboardAspectRatio 4.0/3.0

#define answerOptionButtonHeight 40.0
#define BJLScUserOperateViewButtonHeight 50.0

// isNotchScreen
static inline BOOL bjlsc_iPhoneXSeries() {
    if (@available(iOS 11.0, *)) {
        static const CGFloat insetsLimit = 20.0;
        UIEdgeInsets insets = [UIViewController bjl_topViewController].view.window.safeAreaInsets;
        return (insets.top > insetsLimit
                || insets.left > insetsLimit
                || insets.right > insetsLimit
                || insets.bottom > insetsLimit);
    }
    return NO;
}

#pragma mark -

/** 窗口类型 */
typedef NS_ENUM(NSInteger, BJLScWindowType) {
    BJLScWindowType_ppt,                    // ppt窗口 或 老师辅助摄像头窗口，需要根据是否存在辅助摄像头视图来决定
    BJLScWindowType_userVideo,              // 除老师外的窗口
    BJLScWindowType_teacherVideo,           // 老师窗口
};

#pragma mark -

@interface UIColor (BJLSurfaceClass)

// common
@property (class, nonatomic, readonly) UIColor
*bjlsc_darkGrayBackgroundColor,
*bjlsc_lightGrayBackgroundColor,

*bjlsc_darkGrayTextColor,
*bjlsc_grayTextColor,
*bjlsc_lightGrayTextColor,

*bjlsc_grayBorderColor,
*bjlsc_grayLineColor,
*bjlsc_grayImagePlaceholderColor, // == bjlsc_grayLineColor

*bjlsc_blueBrandColor,
*bjlsc_orangeBrandColor,
*bjlsc_redColor;

// dim
@property (class, nonatomic, readonly) UIColor
*bjlsc_lightDimColor, // black-0.2
*bjlsc_dimColor,      // black-0.5
*bjlsc_darkDimColor;  // black-0.6

@end

#pragma mark -

@interface UIImage (BJLSurfaceClass)

+ (UIImage *)bjlsc_imageNamed:(NSString *)name;

@end

@interface UIView (BJLSurfaceClass)

- (void)bjlsc_drawRectCorners:(UIRectCorner)coners radius:(CGFloat)radius backgroundColor:(UIColor *)color size:(CGSize)size;

- (void)bjlsc_removeCorners;

@end

NS_ASSUME_NONNULL_END
