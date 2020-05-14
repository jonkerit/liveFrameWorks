//
//  BJLIcChatInputViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/15.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcChatInputViewController : UIViewController

/**
 输入框初始化

 @param text 初始默认文本
 */
- (instancetype)initWithText:(NSString *)text;

/**
 编辑结束的回调
 */
@property (nonatomic, nullable) void (^editCallback)(NSString *text);

@end

NS_ASSUME_NONNULL_END
