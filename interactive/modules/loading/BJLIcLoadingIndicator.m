//
//  BJLIcLoadingIndicator.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/6.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcLoadingIndicator.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLoadingIndicator ()

@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) UIView *indicatorView;
@property (nonatomic) UILabel *label;
@property (nonatomic) CAShapeLayer *triangleLayer;

@property (nonatomic) UIColor *loadingIndicatoColor;

@end

@implementation BJLIcLoadingIndicator

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self makeSubviewsAndConstraints];
        [self makeObserving];
    }
    return self;
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = NO;
    
    self.loadingIndicatoColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    self.indicatorView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self addSubview:self.indicatorView];
    [self.indicatorView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self);
        make.centerX.equalTo(self.bjl_left);
    }];

    self.label = ({
        UILabel *label = [UILabel new];
        label.text = @"0%";
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = self.loadingIndicatoColor;
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [self.indicatorView addSubview:self.label];
    [self.label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.top.equalTo(self.indicatorView);
    }];
}

- (void)createTriangleLayer {
    // [self.triangleLayer removeFromSuperlayer];
    // self.triangleLayer = nil;
    self.triangleLayer = ({
        CAShapeLayer *layer = [CAShapeLayer layer];
        UIBezierPath *trianglePath = [UIBezierPath bezierPath];
        [trianglePath moveToPoint:CGPointMake(/* self.width * self.currentProgress */ - loadingBarHeight / 2.0, self.height - loadingBarHeight)];
        [trianglePath addLineToPoint:CGPointMake(/* self.width * self.currentProgress */ + loadingBarHeight / 2.0, self.height - loadingBarHeight)];
        [trianglePath addLineToPoint:CGPointMake(/* self.width * self.currentProgress */ - 0.0, self.height)];
        [trianglePath closePath];
        layer.path = trianglePath.CGPath;
        layer.cornerRadius = loadingBarHeight;
        layer.fillColor = self.loadingIndicatoColor.CGColor;
        layer;
    });
    [self.indicatorView.layer addSublayer:self.triangleLayer];
}

- (void)makeFailedAnimation {
    self.label.textColor = [UIColor redColor];
    self.triangleLayer.fillColor = [UIColor redColor].CGColor;
    CGAffineTransform transform;
    if (self.currentProgress < 0.5) {
        // 右倾斜
       transform  = CGAffineTransformMakeRotation(10.0 * (M_PI / 180.0f));
    }
    else {
        // 左倾斜
        transform = CGAffineTransformMakeRotation(-10.0 * (M_PI / 180.0f));
    }
    self.indicatorView.transform = transform;
}

- (void)resume {
    [super resume];
    self.indicatorView.transform = CGAffineTransformIdentity;
    self.triangleLayer.fillColor = self.loadingIndicatoColor.CGColor;
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self, bounds)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (!self.bounds.size.width) {
                 return YES;
             }
             self.width = self.bounds.size.width;
             self.height = self.bounds.size.height;
             [self createTriangleLayer];
             return NO;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, currentProgress)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.label.textColor = self.loadingIndicatoColor;
             self.triangleLayer.fillColor = self.loadingIndicatoColor.CGColor;

             self.label.text = [NSString stringWithFormat:@"%ld%%", (long)(self.currentProgress * 100)];
             self.indicatorView.center = CGPointMake(self.width * self.currentProgress, self.label.center.y);
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, progressState)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.progressState == BJLIcLoadingStateFailed) {
                 [self makeFailedAnimation];
             }
             return YES;
         }];
}

#pragma mark - public
- (void)updateLoadingInficatorColor:(UIColor *)color {
    if(color) {
        self.loadingIndicatoColor = color;
    }
}

@end

NS_ASSUME_NONNULL_END
