//
//  BJLScAppearance.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScAppearance.h"
#import "BJLScRoomViewController.h"

#pragma mark -

@implementation UIColor (BJLSurfaceClass)

+ (UIColor *)bjlsc_darkGrayBackgroundColor {
    return [UIColor bjl_colorWithHex:0x1D1D1E];
}

+ (instancetype)bjlsc_lightGrayBackgroundColor {
    return [UIColor bjl_colorWithHex:0xF8F8F8];
}

+ (UIColor *)bjlsc_darkGrayTextColor {
    return [UIColor bjl_colorWithHex:0x3D3D3E];
}

+ (instancetype)bjlsc_grayTextColor {
    return [UIColor bjl_colorWithHex:0x6D6D6E];
}

+ (instancetype)bjlsc_lightGrayTextColor {
    return [UIColor bjl_colorWithHex:0x9D9D9E];
}

+ (instancetype)bjlsc_grayBorderColor {
    return [UIColor bjl_colorWithHex:0xCDCDCE];
}

+ (instancetype)bjlsc_grayLineColor {
    return [UIColor bjl_colorWithHex:0xDDDDDE];
}

+ (instancetype)bjlsc_grayImagePlaceholderColor {
    return [UIColor bjl_colorWithHex:0xEDEDEE];
}

+ (instancetype)bjlsc_blueBrandColor {
    return [UIColor bjl_colorWithHex:0x37A4F5];
}

+ (instancetype)bjlsc_orangeBrandColor {
    return [UIColor bjl_colorWithHex:0xFF9100];
}

+ (instancetype)bjlsc_redColor {
    return [UIColor bjl_colorWithHex:0xFF5850];
}

#pragma mark -

+ (UIColor *)bjlsc_lightDimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.2];
}

+ (instancetype)bjlsc_dimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.5];
}

+ (instancetype)bjlsc_darkDimColor {
    return [UIColor colorWithWhite:0.0 alpha:0.6];
}

@end

#pragma mark -

@implementation UIImage (BJLSurfaceClass)

+ (UIImage *)bjlsc_imageNamed:(NSString *)name {
    static NSString * const bundleName = @"BJLSurfaceClass", * const bundleType = @"bundle";
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *classBundle = [NSBundle bundleForClass:[BJLScRoomViewController class]];
        NSString *bundlePath = [classBundle pathForResource:bundleName ofType:bundleType];
        bundle = [NSBundle bundleWithPath:bundlePath];
    });
    return [self imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
}

@end


@implementation UIView (BJLSurfaceClass)

- (void)bjlsc_drawRectCorners:(UIRectCorner)coners radius:(CGFloat)radius backgroundColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef contextRef =  UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(contextRef, 1.0);
    CGContextSetStrokeColorWithColor(contextRef, color.CGColor);
    CGContextSetFillColorWithColor(contextRef, color.CGColor);
    
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    CGContextMoveToPoint(contextRef, 0, 0);
    if (coners & UIRectCornerTopRight) {
        CGContextAddArcToPoint(contextRef, width, 0, width, height, radius);  // 右上角
    }
    else {
        CGContextAddLineToPoint(contextRef, width, 0);
    }
    if (coners & UIRectCornerBottomRight) {
        CGContextAddArcToPoint(contextRef, width, height, 0, height, radius); // 右下角
    }
    else {
        CGContextAddLineToPoint(contextRef, width, height);
    }
    if (coners & UIRectCornerBottomLeft) {
        CGContextAddArcToPoint(contextRef, 0, height, 0, 0, radius); // 左下角
    }
    else {
        CGContextAddLineToPoint(contextRef, 0, height);
    }
    if (coners & UIRectCornerTopLeft) {
        CGContextAddArcToPoint(contextRef, 0, 0, width, 0, radius); // 左上角
    }
    else {
        CGContextAddLineToPoint(contextRef, 0, 0);
    }
    CGContextDrawPath(contextRef, kCGPathFillStroke);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.layer.contents = (__bridge id _Nullable)(image.CGImage);
}

- (void)bjlsc_removeCorners {
    self.layer.contents = nil;
}

@end

