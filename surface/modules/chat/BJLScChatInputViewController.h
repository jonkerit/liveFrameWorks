//
//  BJLScChatInputViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJL_iCloudLoading.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScChatInputViewController : UIViewController

@property (nonatomic, copy, nullable) void (^selectImageFileCallback)(ICLImageFile *file, UIImage * _Nullable image);

@property (nonatomic, copy, nullable) void (^finishCallback)(NSString * _Nullable errorMessage);

@property (nonatomic, copy, nullable) void (^changeChatStatusCallback)(BJLChatStatus chatStatus, BJLUser * _Nullable targetUser);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (void)updateChatStatus:(BJLChatStatus)chatStatus withTargetUser:(nullable BJLUser *)targetUser;
- (void)showWhisperChatList;

@end

NS_ASSUME_NONNULL_END
