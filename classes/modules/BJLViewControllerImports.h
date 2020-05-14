//
//  BJLViewControllerImports.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-02-08.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import <BJLiveBase/BJLiveBase+Foundation.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLTableViewController+style.h"

#import "BJLAppearance.h"
#import "BJLPlaceholderView.h"


NS_ASSUME_NONNULL_BEGIN

/**
 用于判断 BJLiveUI 是否使用横屏模式，BJLiveUI 以外可能不适用
 */
static inline BOOL BJLIsHorizontalUI(id<UITraitEnvironment> traitEnvironment) {
    return !(traitEnvironment.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact
             && traitEnvironment.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular);
}

static inline NSString * BJLVideoTitleWithMediaSource(BJLMediaSource mediaSource) {
    switch (mediaSource) {
        case BJLMediaSource_mainCamera:
            return @"摄像头";
            
        case BJLMediaSource_mediaFile:
            return @"媒体文件";
            
        case BJLMediaSource_extraCamera:
            return @"辅助摄像头";
            
        case BJLMediaSource_screenShare:
        case BJLMediaSource_extraScreenShare: {
            return @"屏幕共享";
        }
            
        case BJLMediaSource_all:
            return @"所有视频";
            
        default:
            return @"摄像头";
    }
}

@protocol BJLRoomChildViewController <NSObject>

@required

/** 初始化
 注意需要 KVO 监听 `room.vmsAvailable` 属性，当值为 YES 时 room 的 view-model 才可用
 *  bjl_weakify(self);
 *  [self bjl_kvo:BJLMakeProperty(self.room, vmsAvailable)
 *         filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
 *             // bjl_strongify(self);
 *             return now.boolValue;
 *         }
 *       observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
 *           bjl_strongify(self);
 *           // room 的 view-model 可用
 *           return NO; // 停止监听 vmsAvailable
 *       }];
 u need: 
 *  @property (nonatomic, readonly, weak) BJLRoom *room;
 *  self->_room = room;
 */
- (instancetype)initWithRoom:(BJLRoom *)room;

@end

@interface UIViewController (BJLRoomActions)

- (void)showProgressHUDWithText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
