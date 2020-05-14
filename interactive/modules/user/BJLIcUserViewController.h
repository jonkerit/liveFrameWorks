//
//  BJLIcUserViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/10.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcPopoverViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserViewController : UIViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

/**
 禁止举手
 */
@property (nonatomic, nullable) BOOL (^forbidSpeakRequestCallback)(BOOL forbid);

/**
 收到举手, 或者举手被处理的回调, user --> 举手用户, finish --> 该用户举手是否已经被处理(拒绝，同意，用户取消), count --> 当前举手用户数
 */
@property (nonatomic, nullable) void (^receiveSpeakingRequestCallback)(BJLUser *user, BOOL finish, NSInteger count);

/**
 移除某个用户
 */
@property (nonatomic, nullable) void (^blockUserCallback)(BJLUser *user);

/**
 显示错误信息
 */
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);

/**
 上台已满时 显示切换上下台提示
 */
@property (nonatomic, nullable) void (^showSwitchStageTipViewCallback)(void);


/**
 解除全员黑名单提示
 */
@property (nonatomic, nullable) void (^showFreeAllBlockedUserCallback)(void);

/**
 关闭用户列表
 */
@property (nonatomic, nullable) void (^closeCallback)(void);

/**
 切换到上台用户列表
 */
- (void)switchToOnStageListTableView;

@end

NS_ASSUME_NONNULL_END
