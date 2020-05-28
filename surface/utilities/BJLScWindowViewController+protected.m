//
//  BJLScWindowViewController+protected.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-19.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScWindowViewController+protected.h"
#import "BJLScAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLScWindowViewController (protected)

- (CGFloat)relativeDxWithDx:(CGFloat)dx {
    return (self.view.superview
            ? dx / CGRectGetWidth(self.view.superview.bounds)
            : 0.0);
}

- (CGFloat)relativeDyWithDy:(CGFloat)dy {
    return (self.view.superview
            ? dy / CGRectGetHeight(self.view.superview.bounds)
            : 0.0);
}

- (CGFloat)relativeWidthWithRelativeHeight:(CGFloat)relativeHeight aspectRatio:(CGFloat)aspectRatio {
    CGFloat relativeWidth = relativeHeight / blackboardAspectRatio;
    return relativeWidth * aspectRatio;
}

- (CGFloat)relativeHeightWithRelativeWidth:(CGFloat)relativeWidth aspectRatio:(CGFloat)aspectRatio {
    CGFloat relativeHeight = relativeWidth * blackboardAspectRatio;
    return relativeHeight / aspectRatio;
}

- (CGFloat)relativeWidthWithRelativeHeight:(CGFloat)relativeHeight width:(CGFloat)width height:(CGFloat)height {
    return [self relativeWidthWithRelativeHeight:relativeHeight aspectRatio:width / height];
}

- (CGFloat)relativeHeightWithRelativeWidth:(CGFloat)relativeWidth width:(CGFloat)width height:(CGFloat)height {
    return [self relativeHeightWithRelativeWidth:relativeWidth aspectRatio:width / height];
}

- (CGRect)rectInBounds:(CGRect)rect {
    CGFloat originX = CGRectGetMinX(rect);
    CGFloat originY = CGRectGetMinY(rect);
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    if (width <= 0.0
        || height <= 0.0) {
        return rect;
    }
    CGFloat ratio = width / height;
    if (width > 1.0) {
        originX = originX / width;
        originY = originY / width;
        width = 1.0;
        height = width / ratio;
    }
    if (height > 1.0) {
        originX = originX / height;
        originY = originY / height;
        height = 1.0;
        width = height * ratio;
    }
    return CGRectMake(originX, originY, width, height);
}

#pragma mark - self

- (void)makeObserveringForWindowState {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self, state)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             switch (self.state) {
                 case BJLSWindowState_windowed:
                     self.topBar.maximizeButton.selected = NO;
                     self.topBar.fullscreenButton.selected = NO;
                     break;
                    
                 case BJLSWindowState_maximized:
                     self.topBar.maximizeButton.selected = YES;
                     self.topBar.fullscreenButton.selected = NO;
                     break;
                     
                case BJLSWindowState_fullscreen:
                     self.topBar.maximizeButton.selected = NO;
                     self.topBar.fullscreenButton.selected = YES;
                     break;
                     
                 default:
                     break;
             }
             return YES;
         }];
}

- (void)addHandlers {
    bjl_weakify(self);
    
    /* buttons */
    
    [self.topBar.maximizeButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [self bringToFront];
        self.topBar.maximizeButton.selected = !self.topBar.maximizeButton.selected;
        if (self.topBar.maximizeButton.selected) {
            [self maximize];
        }
        else {
            [self restore];
        }
    }];
    
    [self.topBar.fullscreenButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        [self bringToFront];
        self.topBar.fullscreenButton.selected = !self.topBar.fullscreenButton.selected;
        if (self.topBar.fullscreenButton.selected) {
            [self fullscreen];
        }
        else {
            [self restore];
        }
    }];
    
    [self.topBar.closeButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        // NO `[self bringToFront];`
        [self close];
    }];
    
    /* tap - bringToFront, doubleTap - maximize/restore, pan - moving */
    
    self.windowGestures = [NSMutableArray array];
    for (UIView *view in @[self.topBar, self.forgroundView]) {
        bjl_strongify(self);
        UITapGestureRecognizer *singleTap = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (self.singleTapGestureCallback) {
                self.singleTapGestureCallback([gesture locationInView:view]);
            }
            if (!self.tapToBringToFront) {
                return;
            }
            [self bringToFront];
        }];
        [self.windowGestures bjl_addObject:singleTap];
        
        UITapGestureRecognizer *doubleTap = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (!self.doubleTapToMaximize) {
                return;
            }
            [self bringToFront];
            if (self.state == BJLSWindowState_windowed) {
                [self maximize];
            }
            else if (self.state == BJLSWindowState_maximized) {
                [self restore];
            }
        }];
        doubleTap.numberOfTouchesRequired = 1;
        doubleTap.numberOfTapsRequired = 2;
        [self.windowGestures bjl_addObject:doubleTap];
        
        [view addGestureRecognizer:singleTap];
        [view addGestureRecognizer:doubleTap];
        [singleTap requireGestureRecognizerToFail:doubleTap];
        
        __block CGPoint originPoint = CGPointZero;
        __block CGPoint movingTranslation = CGPointZero;
        [view addGestureRecognizer:({
            UIPanGestureRecognizer *pan = [UIPanGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
                bjl_strongify(self);
                if (!self.panToMove) {
                    return;
                }
                
                if (self.state == BJLSWindowState_fullscreen
                    || self.state == BJLSWindowState_maximized) {
                    // 全屏和最大化状态下不处理 move
                    return;
                }
                
                [self bringToFrontWithoutRequest];
                
                BOOL finished = NO;
                
                if (gesture.state == UIGestureRecognizerStateBegan) {
                    originPoint = self.view.frame.origin;
                    [gesture setTranslation:CGPointMake(0.0, 0.0) inView:self.view];
                    movingTranslation = [gesture translationInView:self.view];
                    [self bringToFront];
                }
                else if (gesture.state == UIGestureRecognizerStateChanged) {
                    movingTranslation = [gesture translationInView:self.view];
                }
                else if (gesture.state == UIGestureRecognizerStateEnded) {
                    finished = YES;
                }
                else if (gesture.state == UIGestureRecognizerStateCancelled) {
                    finished = YES;
                }
                
                CGRect frame = bjl_set(self.view.frame, {
                    set.origin = CGPointMake(originPoint.x + movingTranslation.x,
                                             originPoint.y + movingTranslation.y);
                }), superBounds = self.view.superview.bounds;
                if (CGRectGetMinX(frame) < 0.0) {
                    frame.origin.x = 0.0;
                }
                if (CGRectGetMinY(frame) < 0.0) {
                    frame.origin.y = 0.0;
                }
                if (CGRectGetMaxX(frame) > CGRectGetMaxX(superBounds)) {
                    frame.origin.x = CGRectGetMaxX(superBounds) - CGRectGetWidth(frame);
                }
                if (CGRectGetMaxY(frame) > CGRectGetMaxY(superBounds)) {
                    frame.origin.y = CGRectGetMaxY(superBounds) - CGRectGetHeight(frame);
                }
                
                if (!finished) {
                    self->_tempFrame = frame;
                    [self updatePositionAndSize];
                }
                else {
                    self->_tempFrame = CGRectNull;
                    self.relativeRect = bjl_set(self.relativeRect, {
                        set.origin.x = [self relativeDxWithDx:CGRectGetMinX(frame)];
                        set.origin.y = [self relativeDyWithDy:CGRectGetMinY(frame)];
                    });
                    [self updatePositionAndSize];
                    [self requestUpdateWithAction:BJLWindowsUpdateAction_updateRect];
                }
            }];
            
            [self.windowGestures bjl_addObject:pan];
            bjl_return pan;
        })];
    }
    
    /* pan - resizing */
    
    __block CGSize originSize = CGSizeZero;
    __block CGPoint resizingTranslation = CGPointZero;
    [self.bottomBar.resizeHandleView addGestureRecognizer:({
        UIPanGestureRecognizer *pan = [UIPanGestureRecognizer bjl_gestureWithHandler:^(UIPanGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            if (!self.panToResize) {
                return;
            }
            
            if (self.state == BJLSWindowState_fullscreen
                || self.state == BJLSWindowState_maximized) {
                // 全屏和最大化状态下不处理 resize
                return;
            }
            
            [self bringToFront];
            
            BOOL finished = NO;
            
            if (gesture.state == UIGestureRecognizerStateBegan) {
                originSize = self.view.frame.size;
                [gesture setTranslation:CGPointMake(originSize.width, originSize.height) inView:self.view];
                resizingTranslation = [gesture translationInView:self.view];
            }
            else if (gesture.state == UIGestureRecognizerStateChanged) {
                resizingTranslation = [gesture translationInView:self.view];
            }
            else if (gesture.state == UIGestureRecognizerStateEnded) {
                finished = YES;
            }
            else if (gesture.state == UIGestureRecognizerStateCancelled) {
                finished = YES;
            }
            
            const CGFloat minWidth = self.minWindowWidth, minHeight = self.minWindowHeight;
            CGRect frame = bjl_set(self.view.frame, {
                if (self.fixedAspectRatio > CGFLOAT_MIN) {
                    CGFloat scale = (MAX(resizingTranslation.x, minWidth) + MAX(resizingTranslation.y, minHeight)) / (originSize.width + originSize.height);
                    CGFloat adjustedWidth = originSize.width * scale;
                    CGFloat adjustedHeight = adjustedWidth / self.fixedAspectRatio;
                    set.size = CGSizeMake(adjustedWidth, adjustedHeight);
                }
                else {
                    CGFloat adjustedWidth = MAX(resizingTranslation.x, minWidth);
                    CGFloat adjustedHeight = MAX(resizingTranslation.y, minHeight);
                    set.size = CGSizeMake(adjustedWidth, adjustedHeight);
                }
            }), superBounds = self.view.superview.bounds;
            if (CGRectGetMaxX(frame) > CGRectGetMaxX(superBounds)) {
                frame.size.width = CGRectGetMaxX(superBounds) - CGRectGetMinX(frame);
                if (self.fixedAspectRatio > CGFLOAT_MIN) {
                    frame.size.height = CGRectGetWidth(frame) / self.fixedAspectRatio;
                }
            }
            if (CGRectGetMaxY(frame) > CGRectGetMaxY(superBounds)) {
                frame.size.height = CGRectGetMaxY(superBounds) - CGRectGetMinY(frame);
                if (self.fixedAspectRatio > CGFLOAT_MIN) {
                    frame.size.width = CGRectGetHeight(frame) * self.fixedAspectRatio;
                }
            }
            
            if (!finished) {
                self->_tempFrame = frame;
                [self updatePositionAndSize];
            }
            else {
                self->_tempFrame = CGRectNull;
                self.relativeRect = bjl_set(self.relativeRect, {
                    set.size.width = [self relativeDxWithDx:CGRectGetWidth(frame)];
                    set.size.height = [self relativeDyWithDy:CGRectGetHeight(frame)];
                });
                [self updatePositionAndSize];
                [self requestUpdateWithAction:BJLWindowsUpdateAction_updateRect];
            }
        }];
        [self.windowGestures bjl_addObject:pan];
        bjl_return pan;
    })];
}

- (void)requestUpdateWithAction:(NSString *)action {
    if (self.state == BJLSWindowState_fullscreen
        || self.state == BJLSWindowState_maximized) {
        if ([action isEqualToString:BJLWindowsUpdateAction_updateRect]
            || [action isEqualToString:BJLWindowsUpdateAction_open]) {
            // !!!: 全屏、最大化状态下收到这 2 种 action 时，保持原状
            return;
        }
    }
    
    if (self.windowUpdateCallback) {
        self.windowUpdateCallback(action, self.relativeRect);
    }
}

- (void)setWindowGesturesEnabled:(BOOL)enabled {
    // 对于有窗口拖动权限的用户，才能开关手势的 enable 来实现画笔，点击窗口内部内容的功能，否则手势一直被设置成禁用的
    for (UIGestureRecognizer *gesture in self.windowGestures) {
        gesture.enabled = self.windowInterfaceEnabled && enabled;
    }
    // 对于 forgroundView 的可交互性，不受窗口拖动权限影响，当开启画笔，开启可操作PPT的状态时，都将设置为 NO 来穿透这个视图，传到底层视图
    self.forgroundView.userInteractionEnabled = enabled;
    // 当需要传递事件给底层内容视图时，隐藏 topBar 和 bottomBar
    self.topBar.hidden = !enabled;
    self.bottomBar.hidden = !enabled;
}

#pragma mark - parent

- (void)makeObserveringForContainer {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self, relativeRect)
           filter:^BOOL(id _Nullable now, NSValue * _Nullable old, BJLPropertyChange * _Nullable change) {
               bjl_strongify(self);
               if (old) {
                   CGRect oldRelativeRect = CGRectNull;
                   [old getValue:&oldRelativeRect];
                   return !CGRectEqualToRect(self.relativeRect, oldRelativeRect);
               }
               return now != old;
           }
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updatePositionAndSize];
             return YES;
         }];
}

- (void)moveToParentViewControllerAndSuperview {
    UIViewController *parentViewController = nil;
    UIView *superview = nil;
    if (self.state == BJLSWindowState_fullscreen) {
        parentViewController = self.fullscreenParentViewController;
        superview = self.fullscreenSuperview ?: parentViewController.view;
    }
    else {
        parentViewController = self.windowedParentViewController;
        superview = self.windowedSuperview ?: parentViewController.view;
    }
    if (!parentViewController && !superview) {
        return;
    }
    
    if (self.parentViewController != parentViewController
        || self.view.superview != superview) {
        [self bjl_removeFromParentViewControllerAndSuperiew];
        if (parentViewController) {
            [parentViewController bjl_addChildViewController:self superview:superview];
        }
        else {
            [superview addSubview:self.view];
        }
    }
    
    [self updatePositionAndSize];
}

- (void)updatePositionAndSize {
    if (!self.view.superview) {
        return;
    }
    
    [self.view bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        if (self.state == BJLSWindowState_maximized
            || self.state == BJLSWindowState_fullscreen) {
            make.edges.equalTo(self.view.superview);
            return;
        }
        else if (self.state != BJLSWindowState_windowed) {
            return;
        }
        
        if (!CGRectEqualToRect(self->_tempFrame, CGRectNull)
            && !CGRectEqualToRect(self->_tempFrame, CGRectZero)) {
            make.left.equalTo(@(self->_tempFrame.origin.x));
            make.top.equalTo(@(self->_tempFrame.origin.y));
            make.width.equalTo(@(self->_tempFrame.size.width));
            make.height.equalTo(@(self->_tempFrame.size.height));
            return;
        }
        
        CGPoint origin = self.relativeRect.origin;
        if (CGPointEqualToPoint(origin, BJLSPointNull)) {
            origin = CGPointZero;
        }
        make.left.equalTo(self.view.superview.bjl_right).multipliedBy(MAX(origin.x, FLT_MIN));
        make.top.equalTo(self.view.superview.bjl_bottom).multipliedBy(MAX(origin.y, FLT_MIN));
        
        CGSize size = self.relativeRect.size;
        if (CGSizeEqualToSize(size, CGSizeZero)) {
            size = CGSizeMake(0.25, 0.25);
        }
        CGFloat minWidthRatio = self.view.superview.bounds.size.width ? (self.minWindowWidth/self.view.superview.bounds.size.width) : size.width;
        CGFloat minHeightRatio = self.view.superview.bounds.size.height ? (self.minWindowHeight/self.view.superview.bounds.size.height) : size.height;
        
        make.width.equalTo(self.view.superview).multipliedBy(MAX(MAX(size.width, minWidthRatio), FLT_MIN));
        make.height.equalTo(self.view.superview).multipliedBy(MAX(MAX(size.height, minHeightRatio), FLT_MIN));
    }];
}

#pragma mark - content

- (void)makeObserveringForContent {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self, topBarBackgroundViewHidden)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old && now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.topBar.backgroundView.hidden = now.boolValue;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, caption)
           filter:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old && ![now isEqualToString:old];
           }
         observer:^BOOL(NSString * _Nullable now, NSString * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.topBar.captionLabel.text = now;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, maximizeButtonHidden)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old && now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.topBar.maximizeButton.hidden = (now.boolValue
                                                  || self.state == BJLSWindowState_fullscreen);
             [self.topBar setNeedsUpdateConstraints];
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self, fullscreenButtonHidden)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old && now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.topBar.fullscreenButton.hidden = now.boolValue;
             [self.topBar setNeedsUpdateConstraints];
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self, closeButtonHidden)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old && now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.topBar.closeButton.hidden = now.boolValue;
             [self.topBar setNeedsUpdateConstraints];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, bottomBarBackgroundViewHidden)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old && now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.bottomBar.backgroundView.hidden = now.boolValue;
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self, resizeHandleImageViewHidden)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old && now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.bottomBar.resizeHandleImageView.hidden = now.boolValue;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self, state)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now != old && now.integerValue != old.integerValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.topBar.maximizeButton.hidden = (self.maximizeButtonHidden
                                                  || self.state == BJLSWindowState_fullscreen);
             [self.topBar setNeedsUpdateConstraints];
             self.bottomBar.resizeHandleImageView.hidden = (self.resizeHandleImageViewHidden
                                                            || self.state == BJLSWindowState_fullscreen);
             return YES;
         }];
}

@end

NS_ASSUME_NONNULL_END
