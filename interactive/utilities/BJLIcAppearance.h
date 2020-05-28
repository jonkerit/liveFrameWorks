//
//  BJLIcAppearance.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcAppearance : NSObject

+ (instancetype)sharedAppearanceWithTemplateType:(BJLIcTemplateType)type videoDefinition:(BJLVideoDefinition)videoDefinition;

+ (instancetype)sharedAppearance;
+ (void)destory;

@property (nonatomic) CGFloat layoutWidth;
@property (nonatomic) CGFloat layoutHeight;
@property (nonatomic) CGFloat layoutRatio;
@property (nonatomic) CGFloat videoAspectRatio;
@property (nonatomic) NSInteger fullSizedVideosCount;
@property (nonatomic) CGFloat blackboardAspectRatio;
@property (nonatomic) CGFloat blackboardHeightFraction;
@property (nonatomic) CGFloat blackboardWidthFraction;
@property (nonatomic) CGFloat statusBarHeightFraction;
@property (nonatomic) CGFloat videosHeightFraction;
@property (nonatomic) CGFloat videosWidthFraction;
@property (nonatomic) CGFloat toolbarHeightFraction;
@property (nonatomic) CGFloat layoutContainerHeightFraction;
@property (nonatomic) CGFloat toolboxHeightFraction;
@property (nonatomic) CGFloat widgetWidthFraction;
@property (nonatomic) CGFloat statusBarHeight;
@property (nonatomic) CGFloat toolboxWidth;
@property (nonatomic) CGFloat toolbarWidth;
@property (nonatomic) CGFloat buttonSize;
@property (nonatomic) CGFloat liveStartButtonWidth;
@property (nonatomic) CGFloat liveStartButtonHeight;
@property (nonatomic) CGFloat liveStartViewSpace;
@property (nonatomic) CGFloat popoverViewWidth;
@property (nonatomic) CGFloat popoverViewHeight;
@property (nonatomic) CGFloat popoverImageSize;
@property (nonatomic) CGFloat popoverViewSpace;
@property (nonatomic) CGFloat promptCellHeiht;
@property (nonatomic) CGFloat promptCellSmallSpace;
@property (nonatomic) CGFloat promptCellLargeSpace;
@property (nonatomic) NSInteger promptDuration;
@property (nonatomic) NSInteger promptCellMaxCount;
@property (nonatomic) CGFloat promptViewHeight;
@property (nonatomic) CGFloat toolboxButtonSpace;
@property (nonatomic) CGFloat documentFileCellWidth;
@property (nonatomic) CGFloat documentFileCellHeight;
@property (nonatomic) CGFloat documentFileCellImageSize;
@property (nonatomic) CGFloat documentFileDisplayListWidth;
@property (nonatomic) CGFloat toolbarButtonWidth;
@property (nonatomic) CGFloat toolbarLargeSpace;
@property (nonatomic) CGFloat toolbarMediumSpace;
@property (nonatomic) CGFloat toolbarSmallSpace;
@property (nonatomic) CGFloat writingBoradToolbarButtonWidth;
@property (nonatomic) CGFloat writingBoradToolbarLargeSpace;
@property (nonatomic) CGFloat writingBoradToolbarSmallSpace;
@property (nonatomic) CGFloat questionAnswerOptionButtonWidth;
@property (nonatomic) CGFloat questionAnswerOptionButtonHeight;
@property (nonatomic) CGFloat chatViewLargeSpace;
@property (nonatomic) CGFloat chatViewMediumSpace;
@property (nonatomic) CGFloat chatViewSmallSpace;
@property (nonatomic) CGFloat chatCellMaxWidth;
@property (nonatomic) CGFloat chatCellMaxTextHeight;
@property (nonatomic) CGFloat chatCellMinTextHeight;
@property (nonatomic) CGFloat chatCellMinUserInOutTextHeight;
@property (nonatomic) CGFloat chatCellMinTextWidth;
@property (nonatomic) CGFloat chatCellMaxImageHeight;
@property (nonatomic) CGFloat userViewLargeSpace;
@property (nonatomic) CGFloat userViewMediumSpace;
@property (nonatomic) CGFloat userViewSmallSpace;
@property (nonatomic) CGFloat userTableViewCellHeight;
@property (nonatomic) CGFloat userCellAvatarSize;
@property (nonatomic) CGFloat userCellButtonSize;
@property (nonatomic) CGFloat userOptionViewHeight;
@property (nonatomic) CGFloat userWindowDefaultBarHeight;
@property (nonatomic) CGFloat fullScreenRequestSpeakButtonWidth;
@property (nonatomic) CGFloat robotDelayS;
@property (nonatomic) CGFloat robotDelayM;
@property (nonatomic) NSInteger maxReloadTimes;

@end

#pragma mark -
@interface UIColor (BJLInteractiveClass)

// networkloss
@property (class, nonatomic, readonly) UIColor
*bjl_ic_quiteBadNetColor,
*bjl_ic_extremelyBadNetColor;

@end

#pragma mark -

@interface UIImage (BJLInteractiveClass)

/**
 获取image

 @param name image name
 @return image
 */
+ (UIImage *)bjlic_imageNamed:(NSString *)name;

@end

typedef NS_OPTIONS(NSInteger, BJLIcRectPosition) {
    BJLIcRectPosition_top       = 1 << 0,
    BJLIcRectPosition_bottom    = 1 << 1,
    BJLIcRectPosition_left      = 1 << 2,
    BJLIcRectPosition_right     = 1 << 3,
    BJLIcRectPosition_all       = (1 << 4) - 1
};

@interface UIView (BJLInteractiveClass)

/**
 绘制内阴影，绘制新的内阴影时会自动移除上一个内阴影

 #param alpha alpha
 #param cornerRadius cornerRadius
 #return layer
 #discussion no offset, must draw after set the view size
 */
- (CAShapeLayer *)bjlic_drawInnerShadowAlpha:(CGFloat)alpha cornerRadius:(CGFloat)cornerRadius;

/**
 绘制圆角

 #param coners UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight | UIRectCornerAllCorners
 #param cornerRadii cornerRadii
 #discussion must draw after set the view size
 */
- (void)bjlic_drawRectCorners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii;

/**
 绘制边框，绘制新的边框的时候会自动移除上一个边框
 
 #param borderWidth borderWidth
 #param borderColor borderColor
 #param coners coners
 #param cornerRadii cornerRadii
 #return layer
 */
- (CAShapeLayer *)bjlic_drawBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor corners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii;

/**
 绘制边框，绘制新的边框的时候会自动移除上一个边框

 @param borderWidth borderWidth
 @param borderColor borderColor
 @param position BJLIcRectPosition
 @return layer
 */
- (CAShapeLayer *)bjlic_drawBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor position:(BJLIcRectPosition)position;

@end

NS_ASSUME_NONNULL_END
