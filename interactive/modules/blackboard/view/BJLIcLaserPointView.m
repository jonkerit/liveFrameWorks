//
//  BJLIcLaserPointView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/21.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/UIKit+BJLHandler.h>
#import <BJLiveBase/NSObject+BJL_M9Dev.h>

#import "BJLIcLaserPointView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLaserPointView ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) UIImageView *laserPointView;

@property (nonatomic) UIPanGestureRecognizer *laserPointMoveGesture;

@property (nonatomic, nullable) NSTimer *requestTimer;
@property (nonatomic) CGSize showSize;
@property (nonatomic) CGPoint laserPoint;

@end

@implementation BJLIcLaserPointView

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self->_room = room;
        self.documentID = BJLBlackboardID;
        self.pageIndex = 0;
        self.showSize = CGSizeZero;
        [self setupSubviews];
        [self setupLaserPointMoveGesture];
        [self setupObservers];
    }
    return self;
}

- (void)dealloc {
    [self.requestTimer invalidate];
    self.requestTimer = nil;
}

- (void)updateShapeShowSize:(CGSize)size {
    self.showSize = size;
    
    if (!self.laserPointView.hidden) {
        if (CGSizeEqualToSize(size, CGSizeZero)) {
            size = self.bounds.size;
        }

        CGPoint realLocation = CGPointMake(self.laserPoint.x * size.width, self.laserPoint.y * size.height);
        [self updateLaserPointToLocation:realLocation];
    }
}

#pragma mark - subviews

- (void)setupSubviews {
    self.laserPointView = ({
        UIImage *image = [UIImage bjlic_imageNamed:@"bjl_blackboard_laserpoint"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        imageView.hidden = YES;
        imageView;
    });
    [self addSubview:self.laserPointView];
}

#pragma mark - observers

- (void)setupObservers {
    bjl_weakify(self);
    
    [self bjl_observe:BJLMakeMethod(self.room.drawingVM, didLaserPointMoveToLocation:documentID:pageIndex:)
         observer:^BOOL(CGPoint location, NSString *documentID, NSUInteger pageIndex) {
             bjl_strongify(self);
             self.laserPoint = location;
             CGSize showSize = self.showSize;
             if (CGSizeEqualToSize(showSize, CGSizeZero)) {
                 showSize = self.bounds.size;
             }
             
             CGPoint realLocation = CGPointMake(location.x * showSize.width, location.y * showSize.height);
             [self updateLaserPointToLocation:realLocation];
             self.documentID = documentID;
             self.pageIndex = pageIndex;
             return YES;
         }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.room.drawingVM, drawingEnabled),
                         BJLMakeProperty(self.room.drawingVM, drawingShapeType)]
              observer:^(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  self.userInteractionEnabled = (self.room.drawingVM.drawingEnabled
                                                 && self.room.drawingVM.drawingShapeType == BJLDrawingShapeType_laserPoint);
              }];
}

#pragma mark - gesture

- (void)setupLaserPointMoveGesture {
    bjl_weakify(self);
    self.laserPointMoveGesture = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        CGPoint location = [gesture locationInView:gesture.view];
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [self moveLaserPointToLocation:location];
            [self requestUpdateLaserPoint];
            [self startRequestTimer];
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            [self moveLaserPointToLocation:location];
        }
        else if (gesture.state == UIGestureRecognizerStateEnded) {
            [self moveLaserPointToLocation:location];
            [self requestUpdateLaserPoint];
            [self stopRequestTimer];
        }
    }];
    [self addGestureRecognizer:self.laserPointMoveGesture];
}

#pragma mark - request timer

- (void)startRequestTimer {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideLaserPoint) object:nil];
    self.laserPointView.hidden = NO;
    if (self.requestTimer && self.requestTimer.isValid) {
        return;
    }
    
    bjl_weakify(self);
    self.requestTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        
        [self requestUpdateLaserPoint];
    }];
}

- (void)stopRequestTimer {
    [self.requestTimer invalidate];
    [self performSelector:@selector(hideLaserPoint) withObject:nil afterDelay:5.0];
}

#pragma mark - laser point view

- (void)moveLaserPointToLocation:(CGPoint)location {
    CGSize showSize = self.showSize;
    if (CGSizeEqualToSize(showSize, CGSizeZero)) {
        showSize = self.bounds.size;
    }
    CGSize pointSize = self.laserPointView.bounds.size;
    location.x = MIN(showSize.width - pointSize.width, MAX(location.x - 60.0, 0.0));
    location.y = MIN(showSize.height - pointSize.height, MAX(location.y - 60.0, 0.0));
    [self updateLaserPointToLocation:location];
}

- (void)updateLaserPointToLocation:(CGPoint)location {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideLaserPoint) object:nil];
    self.laserPointView.hidden = NO;
    // ceneter -> origin
    self.laserPointView.frame = bjl_set(self.laserPointView.frame, {
        set.origin.x = location.x - set.size.width / 2.0;
        set.origin.y = location.y - set.size.height / 2.0;
    });
    if (!self.requestTimer.isValid) {
        [self performSelector:@selector(hideLaserPoint) withObject:nil afterDelay:5.0];
    }
}

- (void)requestUpdateLaserPoint {
    CGSize showSize = self.showSize;
    if (CGSizeEqualToSize(showSize, CGSizeZero)) {
        showSize = self.bounds.size;
    }

    if (showSize.width <= 0.0 ||
        showSize.height <= 0.0) {
        return;
    }
    
    CGRect frame = self.laserPointView.frame;
    // origin -> center
    CGFloat pointX = frame.origin.x + frame.size.width / 2.0;
    CGFloat pointY = frame.origin.y + frame.size.height / 2.0;
    CGPoint relativePoint = CGPointMake(pointX / showSize.width,
                                        pointY / showSize.height);
    [self.room.drawingVM moveLaserPointToLocation:relativePoint
                                       documentID:self.documentID
                                        pageIndex:self.pageIndex];
}

- (void)hideLaserPoint {
    self.laserPointView.hidden = YES;
}

@end

NS_ASSUME_NONNULL_END
