//
//  BJLScUserOperateView.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/3/9.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLUser.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScUserOperateView : UIView

// 是否为要隐藏邀请发言按钮
@property (nonatomic, assign) BOOL disableinviteSpeakButton;

// 是否为要隐藏禁止聊天按钮
@property (nonatomic, assign) BOOL disableForbidChatButton;

// 是否为要隐藏剔出教室聊天按钮
@property (nonatomic, assign) BOOL disableKickoutButton;

// 是否强制上麦
@property (nonatomic, assign) BOOL forceSpeak;

// 是否禁止聊天
@property (nonatomic, assign) BOOL forbidChat;

// 是否禁止私聊
@property (nonatomic, assign) BOOL enableWhisper;

// 是否正在麦上
@property (nonatomic, assign) BOOL speakingEnable;

// 是否正在邀请中
@property (nonatomic, assign) BOOL isInviting;

@property (nonatomic, copy, nullable) BOOL(^kickoutCallback)(void);
@property (nonatomic, copy, nullable) BOOL(^whisperCallback)(void);
@property (nonatomic, copy, nullable) BOOL(^forbidChatCallback)(BOOL forbid);
@property (nonatomic, copy, nullable) BOOL(^invateSpeakCallback)(BOOL force);

@property (nonatomic, readonly) NSArray <UIButton *> *buttons;

- (instancetype)initWithUser:(BJLUser *)user;
- (void)updateButtonConstraints;

@end

NS_ASSUME_NONNULL_END
