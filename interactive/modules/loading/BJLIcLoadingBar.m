//
//  BJLIcLoadingBar.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/6.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase+Foundation.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcLoadingBar.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLoadingBar ()

@property (nonatomic) CGFloat width;
@property (nonatomic) CAShapeLayer *loadinglayer;
@property (nonatomic) CALayer *flowLayer;
@property (nonatomic, nullable) NSTimer *flowTimer;
@property (nonatomic) UIColor *loadingColor;

@end

@implementation BJLIcLoadingBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self makeSubviewsAndConstraints];
        [self makeObserving];
    }
    return self;
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.layer.masksToBounds = NO;
    self.layer.backgroundColor = [UIColor bjl_colorWithHexString:@"#4A4A4A" alpha:1.0].CGColor;
    self.layer.cornerRadius = loadingBarHeight;
    self.loadingColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    
    self.loadinglayer = ({
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.cornerRadius = loadingBarHeight;
        layer.fillColor = self.loadingColor.CGColor;
        layer;
    });
    [self.layer addSublayer:self.loadinglayer];
}

- (void)makeFailedAnimation {
    // 缺口
    CAShapeLayer *triangleLayer = ({
        CAShapeLayer *layer = [CAShapeLayer layer];
        UIBezierPath *trianglePath = [UIBezierPath bezierPath];
        [trianglePath moveToPoint:CGPointMake(self.width * self.currentProgress - loadingBarHeight / 2, loadingBarHeight)];
        [trianglePath addLineToPoint:CGPointMake(self.width * self.currentProgress + loadingBarHeight / 2, loadingBarHeight)];
        [trianglePath addLineToPoint:CGPointMake(self.width * self.currentProgress, 0)];
        [trianglePath closePath];
        layer.path = trianglePath.CGPath;
        [layer setFillColor:self.loadingColor.CGColor];
        layer;
    });
    [self.layer addSublayer:triangleLayer];
    // 缺口损坏粒子
    CAEmitterLayer *emitter = ({
        CAEmitterLayer *emitter = [CAEmitterLayer layer];
        emitter.emitterPosition = CGPointMake(self.width * self.currentProgress, loadingBarHeight);
        emitter.emitterSize = CGSizeMake(10, 10);
        emitter.backgroundColor =  self.loadingColor.CGColor;
        emitter.emitterShape = kCAEmitterLayerPoint; // 这里是设置发射器的形状，具体效果和发射器的大小有关
        emitter.renderMode = kCAEmitterLayerBackToFront; // 渲染模式，定义如何将粒子合成到图层中
        emitter.emitterMode = kCAEmitterLayerPoints; // 根据发射形状创建粒子
        emitter;
    });
    [self.layer addSublayer:emitter];
    
    CAEmitterCell *leftCell = [[CAEmitterCell alloc] init];
    CAEmitterCell *rightCell = [[CAEmitterCell alloc] init];
    UIImage *image = [UIImage bjl_imageWithColor:self.loadingColor];
    leftCell.contents = (__bridge id)image.CGImage;
    leftCell.birthRate = 2.0;  // 产生粒子数
    leftCell.lifetime = 1.0; // 生命期
    leftCell.velocity = 30; // 粒子的初始速度
    leftCell.emissionRange = M_PI / 10; // 粒子分布在这个发射角度的锥形区域
    leftCell.emissionLongitude = M_PI / 8 * 3; // 粒子在xy平面的发射角度
    
    rightCell.contents = (__bridge id)image.CGImage;
    rightCell.birthRate = 2.0;
    rightCell.lifetime = 1.0;
    rightCell.velocity = 30;
    rightCell.emissionRange = M_PI / 10;
    rightCell.emissionLongitude = M_PI / 8 * 5;
    
    emitter.emitterCells = @[leftCell,rightCell];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        // 移除粒子, 缺口
        [triangleLayer removeFromSuperlayer];
        [emitter removeFromSuperlayer];
        [self makeFlowAnimation];
    });
}

- (void)makeFlowAnimation {
    // 流水
    self.flowLayer = ({
        CALayer *layer = [CALayer layer];
        layer.cornerRadius = loadingBarHeight;
        layer.anchorPoint = CGPointMake(0, 0);
        layer.position = CGPointMake(self.width * self.currentProgress - loadingBarHeight / 2, loadingBarHeight / 2);
        layer.bounds = CGRectMake(0, 0, loadingBarHeight, 0);
        [layer setBackgroundColor:self.loadingColor.CGColor];
        layer;
    });
    [self.layer addSublayer:self.flowLayer];
    [self startFlowTimer];
}

- (void)resume {
    [super resume];
    [self stopFlowTimer];
    [self.flowLayer removeFromSuperlayer];
}

#pragma mark - timer

- (void)startFlowTimer {
    [self stopFlowTimer];
    __block CGFloat rate = 0.2;
    bjl_weakify(self);
    self.flowTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        // loading
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, loadingBarHeight * rate, self.currentProgress * self.width, loadingBarHeight * (1.0 - rate)) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(loadingBarHeight * (1.0 - rate), loadingBarHeight * (1.0 - rate))];
        self.loadinglayer.path = path.CGPath;
        // flow
        CGRect bounds = self.flowLayer.bounds;
        bounds.size = CGSizeMake(loadingBarHeight * (1.0 - rate) , self.width * self.currentProgress * rate);
        self.flowLayer.bounds = bounds;

        rate += 0.2;
        if (rate > 1.0) {
            [self stopFlowTimer];
            [self.flowLayer removeFromSuperlayer];
        }
    }];
}

- (void)stopFlowTimer {
    [self.flowTimer invalidate];
    self.flowTimer = nil;
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
             return NO;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, currentProgress)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.currentProgress * self.width, loadingBarHeight) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(loadingBarHeight, loadingBarHeight)];
             self.loadinglayer.path = path.CGPath;
             self.loadinglayer.fillColor = self.loadingColor.CGColor;
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

#pragma mark -public
- (void)updateLoadingColor:(UIColor *)color {
    if(color) {
        self.loadingColor = color;
    }
}

@end

NS_ASSUME_NONNULL_END
