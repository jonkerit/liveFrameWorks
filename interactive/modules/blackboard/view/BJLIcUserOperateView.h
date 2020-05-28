//
//  BJLIcUserOperateView.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/30.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcUserOperateViewType) {
    BJLIcUserOperateViewStudent,
    BJLIcUserOperateViewTeacher,
    BJLIcUserOperateViewSelf
};

@interface BJLIcUserOperateView : UIView

- (instancetype)initWithType:(BJLIcUserOperateViewType)type;
- (void)updateButtonConstraints;

@property (nonatomic) BOOL videoOn;
@property (nonatomic) BOOL cameraOn;
@property (nonatomic) BOOL microphoneOn;
@property (nonatomic) BOOL drawingGranted;
@property (nonatomic) BOOL webPPTAuthorized;
@property (nonatomic) BOOL extraCameraAuthorized;
@property (nonatomic) BOOL ScreenShareAuthorized;
@property (nonatomic) BOOL enableStudentExtraCameraAndScreenShare;
@property (nonatomic) BOOL isTeacher;
@property (nonatomic) BOOL isAssistant;
@property (nonatomic) BJLVideoDefinition maxVideoDefinition;
@property (nonatomic) BJLVideoDefinition currentVideoDefinition;

@property (nonatomic, nullable) void (^updateDefinitionCallback)(BJLVideoDefinition definition);
@property (nonatomic, nullable) void (^updateVideoCallback)(BOOL on);
@property (nonatomic, nullable) void (^switchCameraCallback)(void);
@property (nonatomic, nullable) void (^updateCameraCallback)(BOOL on);
@property (nonatomic, nullable) void (^updateMicrophoneCallback)(BOOL on);
@property (nonatomic, nullable) void (^grantDrawingCallback)(BOOL granted);
@property (nonatomic, nullable) void (^authorizeWebPPTCallback)(BOOL authorized);
@property (nonatomic, nullable) void (^authorizeExtraCameraCallback)(BOOL authorized);
@property (nonatomic, nullable) void (^authorizeScreenShareCallback)(BOOL authorized);
@property (nonatomic, nullable) void (^sendLikeCallback)(void);
@property (nonatomic, nullable) void (^blockUserCallback)(void);

@end

NS_ASSUME_NONNULL_END
