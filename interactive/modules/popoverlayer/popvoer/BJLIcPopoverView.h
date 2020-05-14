//
//  BJLIcPopoverView.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BJLIcPopoverViewType) {
    // exit
    BJLIcExitViewNormal,                                                 // 正常退出
    BJLIcExitViewKickOut,                                                // 被踢出
    BJLIcExitViewTimeOut,                                                // 超时退出
    BJLIcExitViewConnectFail,                                            // 连接失败退出
    BJLIcExitViewAppend,                                                 // 附加其他操作的退出
    // actions
    BJLIcKickOutUser,                                                    // 踢出用户
    BJLIcSwitchStage,                                                    // 切换上下台
    BJLIcFreeBlockedUser,                                                // 解除全员黑名单
    BJLIcStartCloudRecord,                                               // 云端录制
    BJLIcDisBandGroup,                                                   // 解散分组
    BJLIcRevokeWritingBoard,                                             // 撤销小黑板
    BJLIcClearWritingBoard,                                              // 清空小黑板
    BJLIcCloseWritingBoard,                                              // 关闭小黑板
    BJLIcCloseWebPage,                                                   // 关闭网页
    BJLIcCloseQuiz,                                                      // 关闭测验
    BJLIcHighLoassRate,                                                  // 弱网阻塞UI
    // default
    BJLIcPopoverViewDefaultType = BJLIcExitViewNormal,
};

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcPopoverView : UIView

/**
 取消
 */
@property (nonatomic, readonly) UIButton *cancelButton;

/**
 确认
 */
@property (nonatomic, readonly) UIButton *confirmButton;

/**
 附加操作
 */
@property (nonatomic, readonly, nullable) UIButton *appendButton;

/**
 具体消息，一般不用设置，存在默认信息
 */
@property (nonatomic, readonly) UILabel *messageLabel;

/**
 提示视图大小，默认为 BJLIcPopoverViewWidth 和 BJLIcPopoverViewHeight
 */
@property (nonatomic, readonly) CGSize viewSize;

/**
 提示视图
 
 @param type BJLIcPopoverViewType
 @return self
 */
- (instancetype)initWithType:(BJLIcPopoverViewType)type;

@end

NS_ASSUME_NONNULL_END
