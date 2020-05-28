//
//  BJLIcPopoverViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLIcPopoverView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 任意按钮被点击都将 remove self, 点击事件不穿透
 */
@interface BJLIcPopoverViewController : UIViewController

/**
 init

 @param type BJLIcPopoverViewType
 @return self
 */
- (instancetype)initWithPopoverViewType:(BJLIcPopoverViewType)type;

/**
 init

 @param type BJLIcPopoverViewType
 @param message 提示消息
 @return self
 */
- (instancetype)initWithPopoverViewType:(BJLIcPopoverViewType)type message:(NSString *)message;

/**
 取消提示框 block
 */
@property (nonatomic, nullable) void (^cancelCallback)(void);

/**
 确认提示框 block, 单个按钮只需设置这个回调
 */
@property (nonatomic, nullable) void (^confirmCallback)(void);

/**
 附加提示框 block
 */
@property (nonatomic, nullable) void (^appendCallback)(void);

/** 弹窗类型 */
@property (nonatomic, readonly) BJLIcPopoverViewType type;

/** 是否显示毛玻璃效果 */
- (void)updateEffectHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
