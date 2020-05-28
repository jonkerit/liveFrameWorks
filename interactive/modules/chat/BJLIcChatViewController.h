//
//  BJLIcChatViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/10.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveBase/BJLTableViewController.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcChatViewController : BJLTableViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

/**
 显示输入栏界面
 */
@property (nonatomic, nullable) void (^showChatInputViewCallback)(NSString *text);

/**
 显示消息的详细信息界面
 */
@property (nonatomic, nullable) void (^showChatDetailViewCallback)(BJLMessage *message, NSArray<BJLMessage *> *imageMessages);

/**
 收到未读消息
 */
@property (nonatomic, nullable) void (^receiveUnreadMessageCallback)(NSArray<BJLMessage *> *unreadMessage);

/**
 开启，关闭禁止聊天
 */
@property (nonatomic, nullable) BOOL (^forbidChatCallback)(BOOL forbid);

/**
 关闭聊天列表
 */
@property (nonatomic, nullable) void (^closeCallback)(void);

/**
 显示错误信息
 */
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);

/**
 发送文字消息

 @param text NSString
 */
- (void)sendText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
