//
//  BJLIcChatTableViewCell.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/11.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLMessage.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLIcReceiveTextCellReuseIdentifier,
* const BJLIcReceiveTextAndTranslationCellReuseIdentifier,
* const BJLIcReceiveImageCellReuseIdentifier,
* const BJLIcReceiveEmoticonCellReuseIdentifier,
* const BJLIcSendTextCellReuseIdentifier,
* const BJLIcSendTextAndTranslationCellReuseIdentifier,
* const BJLIcSendImageCellReuseIdentifier,
* const BJLIcSendEmoticonCellReuseIdentifier;

@interface BJLIcChatTableViewCell : UITableViewCell

/**
 刷新 cell 绑定的数据
 
 @param message BJLMessage
 @param cellWidth cell width
 */
- (void)updateWithMessage:(BJLMessage *)message cellWidth:(CGFloat)cellWidth;

/**
 显示消息的具体内容
 */
@property (nonatomic, nullable) void (^showChatDetailCallback)(BJLMessage *message);

/**
 可点击链接
 */
@property (nonatomic, copy, nullable) BOOL (^linkURLCallback)(BJLIcChatTableViewCell * _Nullable cell, NSURL *url);

/**
 单指点击回调
 */
@property (nonatomic, nullable) void (^singleTapCallback)(BJLMessage *message);

/**
 长按回调
 */
@property (nonatomic, nullable) void (^longPressCallback)(BJLMessage *message, UIImage * _Nullable image, CGPoint pointInCell);

@property (nonatomic, copy, nullable) void (^updateConstraintsCallback)(BJLIcChatTableViewCell * _Nullable cell);

+ (NSArray<NSString *> *)allCellIdentifiers;

@end

NS_ASSUME_NONNULL_END
