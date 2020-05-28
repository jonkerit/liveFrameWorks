//
//  BJLIcAppearance.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <objc/runtime.h>

#import "BJLIcAppearance.h"
#import "BJLIcRoomViewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -

@implementation BJLIcAppearance

static BJLIcAppearance * _Nullable sharedInstance = nil;
static dispatch_once_t onceToken;

+ (instancetype)sharedAppearanceWithTemplateType:(BJLIcTemplateType)type videoDefinition:(BJLVideoDefinition)videoDefinition {
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BJLIcAppearance alloc] initWithTemplateType:type videoDefinition:videoDefinition];
    });
    return sharedInstance;
}

+ (instancetype)sharedAppearance {
    if (sharedInstance) {
        return sharedInstance;
    }
    else {
        return [self sharedAppearanceWithTemplateType:BJLIcTemplateType_userVideoUpside videoDefinition:BJLVideoDefinition_default];
    }
}

+ (void)destory {
    sharedInstance = nil;
    onceToken = 0;
}

- (instancetype)initWithTemplateType:(BJLIcTemplateType)type videoDefinition:(BJLVideoDefinition)videoDefinition {
    if (self = [super init]) {
        BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        
        // BJLIcTemplateType_1v1
        
        if (type == BJLIcTemplateType_1v1) {
            self.layoutWidth = 16.0;
            self.layoutHeight = iPhone ? 9.0 : 12.0;
            self.layoutRatio = self.layoutWidth / self.layoutHeight;
            self.blackboardAspectRatio = 4.0 / 3.0;
            self.blackboardWidthFraction = 12.0 / self.layoutWidth;
            self.videosWidthFraction = 4.0 / self.layoutWidth;
            self.toolboxHeightFraction = 1.5 / self.layoutHeight;
            self.statusBarHeight = 24.0;
            self.toolbarWidth = 44.0;
            self.toolbarButtonWidth = 44.0;
        }
        
        // BJLIcTemplateType_userVideoDownside
        
        else if (type == BJLIcTemplateType_userVideoDownside) {
            self.layoutWidth = 16.0;
            self.layoutHeight = 12.0;
            self.layoutRatio = self.layoutWidth / self.layoutHeight;
            self.blackboardAspectRatio = 2.0 / 1;
            self.blackboardHeightFraction = self.layoutRatio * self.blackboardAspectRatio;
            self.videosHeightFraction = 1.875 / self.layoutHeight;
            self.toolbarHeightFraction = 2.125 / self.layoutHeight;
            self.layoutContainerHeightFraction = (8 + 1.875 ) / self.layoutHeight;
            self.statusBarHeight = 20.0;
            self.toolbarButtonWidth = 64.0;
        }
        
        // BJLIcTemplateType_userVideoUpside
        
        else {
            self.layoutWidth = 16.0;
            self.layoutHeight = iPhone ? 10.0 : 12.0;
            self.layoutRatio = self.layoutWidth / self.layoutHeight;
            self.blackboardAspectRatio = 2.0 / 1;
            self.blackboardHeightFraction = self.layoutRatio * self.blackboardAspectRatio;
            self.statusBarHeightFraction = iPhone ? 0.5 / self.layoutHeight : 0.75 / self.layoutHeight;
            self.videosHeightFraction = 1.5 / self.layoutHeight;
            self.toolbarHeightFraction = iPhone ? 1.0 / self.layoutHeight : 1.75 / self.layoutHeight;
            self.toolbarButtonWidth = 64.0;
        }
        
        // common
        self.widgetWidthFraction = 5.0 / self.layoutWidth;
        [self updateVideoAspectRatioWithVideoDefinition:videoDefinition];

        self.buttonSize = 44.0;
        self.toolboxWidth = 44.0;
        self.liveStartButtonWidth = 243.0;
        self.liveStartButtonHeight = 54.0;
        self.liveStartViewSpace = 14.0;
        self.popoverViewWidth = 422.0;
        self.popoverViewHeight = 216.0;
        self.popoverImageSize = 44.0;
        self.popoverViewSpace = 20.0;
        self.promptCellHeiht = 42.0;
        self.promptCellSmallSpace = 6.0;
        self.promptCellLargeSpace = 12.0;
        self.promptDuration = 3;
        self.promptCellMaxCount = 3;
        self.promptViewHeight = 138.0;
        self.toolboxButtonSpace = 8.0;
        self.documentFileCellWidth = 96.0;
        self.documentFileCellHeight = 106.0;
        self.documentFileCellImageSize = 64.0;
        self.documentFileDisplayListWidth = 142.0;
        self.toolbarLargeSpace = 40.0;
        self.toolbarMediumSpace = 20.0;
        self.toolbarSmallSpace = 10.0;
        self.writingBoradToolbarButtonWidth = 80.0;
        self.writingBoradToolbarLargeSpace = 40.0;
        self.writingBoradToolbarSmallSpace = 10.0;
        self.questionAnswerOptionButtonWidth = 34.0;
        self.questionAnswerOptionButtonHeight = 37.0;
        self.chatViewLargeSpace = 12.0;
        self.chatViewMediumSpace = 10.0;
        self.chatViewSmallSpace = 6.0;
        self.chatCellMaxWidth = 220.0;
        self.chatCellMaxTextHeight = 256.0;
        self.chatCellMinTextHeight = 40.0;
        self.chatCellMinUserInOutTextHeight = 26;
        self.chatCellMinTextWidth = 36.0;
        self.chatCellMaxImageHeight = 165.0;
        self.userViewLargeSpace = 12.0;
        self.userViewMediumSpace = 10.0;
        self.userViewSmallSpace = 6.0;
        self.userTableViewCellHeight = 52.0;
        self.userCellAvatarSize = 40.0;
        self.userCellButtonSize = 32.0;
        self.userOptionViewHeight = 40.0;
        self.userWindowDefaultBarHeight = 24.0;
        self.fullScreenRequestSpeakButtonWidth = 48.0;
        self.robotDelayS = 1;
        self.robotDelayM = 2;
        self.maxReloadTimes = 7;
        
    }
    return self;
}

- (void)updateVideoAspectRatioWithVideoDefinition:(BJLVideoDefinition)videoDefinition {
    CGFloat videoAspectRatio = 16.0 / 9.0;
    NSInteger fullSizedVideosCount = 6;
    if (videoDefinition < BJLVideoDefinition_720p) {
        videoAspectRatio = 4.0 / 3.0;
        fullSizedVideosCount = 8;
    }
    self.videoAspectRatio = videoAspectRatio;
    self.fullSizedVideosCount = fullSizedVideosCount;
}

- (instancetype)init {
    return [self initWithTemplateType:BJLIcTemplateType_userVideoUpside videoDefinition:BJLVideoDefinition_default];
}

@end

#pragma mark -

@implementation UIColor (BJLInteractiveClass)

+ (UIColor *)bjl_ic_quiteBadNetColor {
    return [UIColor bjl_colorWithHex:0xF5A623];
}

+ (UIColor *)bjl_ic_extremelyBadNetColor {
    return [UIColor bjl_colorWithHex:0xFF0000];
}

@end

#pragma mark -

@implementation UIImage (BJLInteractiveClass)

+ (UIImage *)bjlic_imageNamed:(NSString *)name {
    static NSString * const bundleName = @"BJLInteractiveClass", * const bundleType = @"bundle";
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *classBundle = [NSBundle bundleForClass:[BJLIcRoomViewController class]];
        NSString *bundlePath = [classBundle pathForResource:bundleName ofType:bundleType];
        bundle = [NSBundle bundleWithPath:bundlePath];
    });
    return [self imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

@end

#pragma mark -

@implementation UIView (BJLInteractiveClass)

#if ! defined(__LP64__) || ! __LP64__ // #see CGFloat
+ (void)load {
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    if (BJLVersionGE(systemVersion, @"10")
        && BJLVersionLT(systemVersion, @"11")) {
        BJLSwizzleMethod(self, @selector(removeFromSuperview), @selector(_bjlic_removeFromSuperview));
    }
}
- (void)_bjlic_removeFromSuperview {
    if (![self isKindOfClass:[UINavigationBar class]]) {
        [self _bjlic_removeSuperviewConstraints];
    }
    [self _bjlic_removeFromSuperview];
}
- (void)_bjlic_removeSuperviewConstraints {
    UIView *superview = self;
    while ((superview = superview.superview)) {
        for (NSLayoutConstraint *constraint in superview.constraints) {
            if (constraint.firstItem == self || constraint.secondItem == self) {
                [superview removeConstraint:constraint];
            }
        }
    }
}
#endif

- (CAShapeLayer *)bjlic_borderLayer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBjlic_borderLayer:(nullable CAShapeLayer *)borderLayer {
    objc_setAssociatedObject(self, @selector(bjlic_borderLayer), borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CAShapeLayer *)bjlic_shadowLayer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBjlic_shadowLayer:(nullable CAShapeLayer *)shadowLayer {
    objc_setAssociatedObject(self, @selector(bjlic_shadowLayer), shadowLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CAShapeLayer *)bjlic_drawInnerShadowAlpha:(CGFloat)alpha cornerRadius:(CGFloat)cornerRadius {
    if (self.bjlic_shadowLayer && self.bjlic_shadowLayer.superlayer) {
        [self.bjlic_shadowLayer removeFromSuperlayer];
        self.bjlic_shadowLayer = nil;
    }
    CAShapeLayer *shadowLayer = [CAShapeLayer layer];
    shadowLayer.frame = self.bounds;
    shadowLayer.shadowOpacity = alpha;
    shadowLayer.shadowColor = [UIColor colorWithWhite:1.0 alpha:alpha].CGColor;
    shadowLayer.shadowOffset = CGSizeMake(0.0, 0.0);
    shadowLayer.fillRule = kCAFillRuleEvenOdd;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(self.bounds, cornerRadius, cornerRadius));
    CGPathRef innerPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:cornerRadius].CGPath;
    CGPathAddPath(path, NULL, innerPath);
    CGPathCloseSubpath(path);
    shadowLayer.path = path;
    CGPathRelease(path);
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = innerPath;
    shadowLayer.mask = maskLayer;
    [self.layer addSublayer:shadowLayer];
    self.bjlic_shadowLayer = shadowLayer;
    return shadowLayer;
}

- (void)bjlic_drawRectCorners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii {
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:coners cornerRadii:cornerRadii];
    shapeLayer.frame = self.bounds;
    shapeLayer.path = path.CGPath;
    self.layer.mask = shapeLayer;
}

- (CAShapeLayer *)bjlic_drawBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor corners:(UIRectCorner)coners cornerRadii:(CGSize)cornerRadii {
    if (self.bjlic_borderLayer && self.bjlic_borderLayer.superlayer) {
        [self.bjlic_borderLayer removeFromSuperlayer];
        self.bjlic_borderLayer = nil;
    }
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:coners cornerRadii:cornerRadii];
    shapeLayer.frame = self.bounds;
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeColor = borderColor.CGColor;
    shapeLayer.fillColor = nil;
    shapeLayer.lineWidth = borderWidth;
    [self.layer addSublayer:shapeLayer];
    self.bjlic_borderLayer = shapeLayer;
    return shapeLayer;
}

- (CAShapeLayer *)bjlic_drawBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor position:(BJLIcRectPosition)position {
    if (self.bjlic_borderLayer && self.bjlic_borderLayer.superlayer) {
        [self.bjlic_borderLayer removeFromSuperlayer];
        self.bjlic_borderLayer = nil;
    }
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);

    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    
    if (position & BJLIcRectPosition_top) {
        CALayer *topLayer = [CALayer layer];
        topLayer.frame = CGRectMake(0.0, 0.0, width, borderWidth);
        topLayer.backgroundColor = borderColor.CGColor;
        [shapeLayer addSublayer:topLayer];
    }
    
    if (position & BJLIcRectPosition_bottom) {
        CALayer *bottomLayer = [CALayer layer];
        bottomLayer.frame = CGRectMake(0.0, height, width, borderWidth);
        bottomLayer.backgroundColor = borderColor.CGColor;
        [shapeLayer addSublayer:bottomLayer];
    }
    
    if (position & BJLIcRectPosition_left) {
        CALayer *leftLayer = [CALayer layer];
        leftLayer.frame = CGRectMake(0.0, 0.0, borderWidth, height);
        leftLayer.backgroundColor = borderColor.CGColor;
        [shapeLayer addSublayer:leftLayer];
    }
    
    if (position & BJLIcRectPosition_right) {
        CALayer *rightLayer = [CALayer layer];
        rightLayer.frame = CGRectMake(width, 0.0, borderWidth, height);
        rightLayer.backgroundColor = borderColor.CGColor;
        [shapeLayer addSublayer:rightLayer];
    }
    
    [self.layer addSublayer:shapeLayer];
    self.bjlic_borderLayer = shapeLayer;
    return shapeLayer;
}

@end

NS_ASSUME_NONNULL_END
