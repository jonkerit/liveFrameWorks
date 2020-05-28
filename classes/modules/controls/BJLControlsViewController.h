//
//  BJLControlsViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-02-15.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLControlsViewController : UIViewController <BJLRoomChildViewController>

@property (nonatomic, readonly) BJLConstraintTarget *rightLayoutGuide, *bottomLayoutGuide;
@property (nonatomic, readonly) UIButton *micButton, *cameraButton;

@property (nonatomic, copy, nullable, setter=setPPTCallback:) void (^pptCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^handCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^penCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^usersCallback)(UIButton * _Nullable button);

@property (nonatomic, copy, nullable) void (^moreCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^rotateCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^micCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^cameraCallback)(UIButton * _Nullable button);

@property (nonatomic, copy, nullable) void (^chatCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^questionCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^pptRemarkCallback)(UIButton * _Nullable button);
@property (nonatomic, copy, nullable) void (^countDownTimerCallback)(UIButton * _Nullable button);

@property (nonatomic, readonly) UIView *questionRedDot;

@end

NS_ASSUME_NONNULL_END
