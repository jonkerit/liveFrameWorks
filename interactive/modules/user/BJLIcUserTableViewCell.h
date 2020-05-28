//
//  BJLIcUserTableViewCell.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/25.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLUser.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLIcOnStageTableViewCellReuseIdentifier,
* const BJLIcDownStageTableViewCellReuseIdentifier,
* const BJLIcBlockedUserTableViewCellReuseIdentifier,
* const BJLIcOnlineUserTableViewCellReuseIdentifier,
* const BJLIcSpeakRequestUserTableViewCellReuseIdentifier;

@interface BJLIcUserTableViewCell : UITableViewCell

/**
 更新cell绑定的数据

 @param user BJLUser
 @param disableOptions YES --> 禁用禁言，踢出教室的操作 NO --> 不禁用
 @param canSwitchStage 禁用操作的情况下，是否允许切换上下台，非禁用操作的情况下忽略这个参数，默认允许 YES --> 允许 NO --> 不允许
 */
- (void)updateWithUser:(BJLUser *)user
        disableOptions:(BOOL)disableOptions
        canSwitchStage:(BOOL)canSwitchStage
             groupInfo:(nullable BJLUserGroup *)groupInfo;

/**
 更新禁言状态

 @param forbid 禁言
 */
- (void)updateChatForbid:(BOOL)forbid;

/**
 接受举手, 打开音视频
 */
@property (nonatomic, nullable) void (^allowSpeakRequestCallback)(BJLUser *user);

/**
 拒绝举手，关闭音视频
 */
@property (nonatomic, nullable) void (^refuseSpeakRequestCallback)(BJLUser *user);

/**
 上台, 允许视频区显示该用户的视频或者占位图
 */
@property (nonatomic, nullable) void (^goOnStageCallback)(BJLUser *user);

/**
 下台, 移除视频区该用户的视频或占位图
 */
@property (nonatomic, nullable) void (^goDownStageCallback)(BJLUser *user);

/**
 禁止聊天
 */
@property (nonatomic, nullable) void (^forbidChatCallback)(BJLUser *user, BOOL forbid);

/**
 踢出教室
 */
@property (nonatomic, nullable) void (^blockUserCallback)(BJLUser *user);

/**
解除黑名单
*/
@property (nonatomic, nullable) void (^freeBlockedUserCallback)(BJLUser *user);

@end

NS_ASSUME_NONNULL_END
