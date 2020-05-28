//
//  BJLAppearance.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-02-10.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import "BJLAppearance.h"

#import "BJLRoomViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIColor (BJLColorLegend)

+ (UIColor *)bjl_darkGrayBackgroundColor {
    return [UIColor bjl_colorWithHex:0x1D1D1E];
}

+ (instancetype)bjl_lightGrayBackgroundColor {
    return [UIColor bjl_colorWithHex:0xF8F8F8];
}

+ (UIColor *)bjl_darkGrayTextColor {
    return [UIColor bjl_colorWithHex:0x3D3D3E];
}

+ (instancetype)bjl_grayTextColor {
    return [UIColor bjl_colorWithHex:0x6D6D6E];
}

+ (instancetype)bjl_lightGrayTextColor {
    return [UIColor bjl_colorWithHex:0x9D9D9E];
}

+ (instancetype)bjl_grayBorderColor {
    return [UIColor bjl_colorWithHex:0xCDCDCE];
}

+ (instancetype)bjl_grayLineColor {
    return [UIColor bjl_colorWithHex:0xDDDDDE];
}

+ (instancetype)bjl_grayImagePlaceholderColor {
    return [UIColor bjl_colorWithHex:0xEDEDEE];
}

+ (instancetype)bjl_blueBrandColor {
    return [UIColor bjl_colorWithHex:0x37A4F5];
}

+ (instancetype)bjl_orangeBrandColor {
    return [UIColor bjl_colorWithHex:0xFF9100];
}

+ (instancetype)bjl_redColor {
    return [UIColor bjl_colorWithHex:0xFF5850];
}

#pragma mark -

+ (UIColor *)bjl_lightDimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.2];
}

+ (instancetype)bjl_dimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.5];
}

+ (instancetype)bjl_darkDimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.6];
}

#pragma mark -

+ (UIColor *)bjl_quiteBadNetColor {
    return [UIColor bjl_colorWithHex:0xF5A623];
}

+ (UIColor *)bjl_extremeBadNetColor {
    return [UIColor bjl_colorWithHex:0xFF0000];
}

@end

#pragma mark -

@implementation UIImage (BJLiveUI)

+ (UIImage *)bjl_imageNamed:(NSString *)name {
    static NSString * const bundleName = @"BJLiveUI", * const bundleType = @"bundle";
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *classBundle = [NSBundle bundleForClass:[BJLRoomViewController class]];
        NSString *bundlePath = [classBundle pathForResource:bundleName ofType:bundleType];
        bundle = [NSBundle bundleWithPath:bundlePath];
    });
    return [self imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

@end

#pragma mark -

@implementation UIButton (BJLButtons)

+ (instancetype)makeTextButtonDestructive:(BOOL)destructive {
    UIButton *button = [self new];
    UIColor *titleColor = destructive ? [UIColor bjl_redColor] : [UIColor bjl_blueBrandColor];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    [button setTitleColor:[titleColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    button.titleLabel.font = [UIFont systemFontOfSize:15.0];
    return button;
}

+ (instancetype)makeRoundedRectButtonHighlighted:(BOOL)highlighted {
    UIButton *button = [self new];
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    if (highlighted) {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor bjl_blueBrandColor];
    }
    else {
        [button setTitleColor:[UIColor bjl_grayTextColor] forState:UIControlStateNormal];
        button.layer.borderWidth = BJLOnePixel;
        button.layer.borderColor = [UIColor bjl_grayBorderColor].CGColor;
    }
    button.layer.cornerRadius = BJLButtonCornerRadius;
    button.layer.masksToBounds = YES;
    return button;
}

@end

@implementation UIImageView (BJLiveUI)

- (UIPanGestureRecognizer *)bjl_makePanGestureToHide:(nullable void (^)(void))hideHander customerHander:(nullable void (^)(UIPanGestureRecognizer * _Nullable))customerHander parentView:(UIView *)parentView {
    __block CGPoint originOffsetPoint = CGPointZero;
    __block CGPoint movingTranslation = CGPointZero;
    __block CGFloat originHeight = 0.0;
    __block CGFloat originWidth = 0.0;
    
    bjl_weakify(self);
    UIPanGestureRecognizer *panGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIPanGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if (customerHander) {
            customerHander(gesture);
        }
        UIView *gestureView = self;
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [gesture setTranslation:CGPointZero inView:parentView];
            originHeight = gestureView.frame.size.height;
            originWidth = gestureView.frame.size.width;
            originOffsetPoint = CGPointMake(gestureView.frame.origin.x, gestureView.frame.origin.y);
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            movingTranslation = [gesture translationInView:parentView];
            CGFloat offsetX = originOffsetPoint.x + movingTranslation.x;
            CGFloat offsetY = originOffsetPoint.y + movingTranslation.y;
            CGFloat scaleRatio = MIN(1.0, 1.5 - offsetY / parentView.frame.size.height);
            CGFloat alphaRatio = 1.0 - offsetY / parentView.frame.size.height;
            parentView.alpha = alphaRatio;
            CGRect rect = CGRectMake(offsetX + (originWidth * (1 - scaleRatio)) / 2.0, offsetY, originWidth * scaleRatio, originHeight * scaleRatio);
            gestureView.frame = rect;
        }
        else if (gesture.state == UIGestureRecognizerStateEnded) {
            movingTranslation = [gesture translationInView:parentView];
            CGFloat offsetY = originOffsetPoint.y + movingTranslation.y;
            BOOL hidden = offsetY > parentView.frame.size.height * 0.2;
            if (hidden && hideHander) {
                hideHander();
            }
            else {
                parentView.alpha = 1.0;
                self.frame = CGRectMake(originOffsetPoint.x, originOffsetPoint.y, originWidth, originHeight);
            }
        }
        else if (gesture.state == UIGestureRecognizerStateCancelled) {
            parentView.alpha = 1.0;
            self.frame = CGRectMake(originOffsetPoint.x, originOffsetPoint.y, originWidth, originHeight);
        }
    }];
    [self addGestureRecognizer:panGesture];
    return panGesture;
}

@end

NS_ASSUME_NONNULL_END
