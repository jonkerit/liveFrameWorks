//
//  BJLIcPromptViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/7.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveBase+UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcPromptViewController : BJLTableViewController

/**
 新增提示，默认时长 [BJLIcAppearance sharedAppearance].promptDuration，默认不重要

 @param prompt 提示文本
 */
- (void)enqueueWithPrompt:(NSString *)prompt;

/**
 新增提示，默认不重要

 @param prompt 提示文本
 @param duration 指定提示时长，传 <=0 的值代表不计时长
 */
- (void)enqueueWithPrompt:(NSString *)prompt duration:(NSInteger)duration;

/**
 新增提示

 @param prompt 提示文本
 @param duration 指定提示时长，传 <=0 的值代表不计时长
 @param important 是否是重要提示，重要提示标红显示
 */
- (void)enqueueWithPrompt:(NSString *)prompt duration:(NSInteger)duration important:(BOOL)important;


/**
 新增特殊提示，不在入队列中，始终在最上方

 @param prompt 提示文本
 @param duration 指定提示时长，传 <=0 的值代表不计时长
 @param important 是否是重要提示，重要提示标红显示
 */
- (void)enqueueWithSpecialPrompt:(NSString *)prompt duration:(NSInteger)duration important:(BOOL)important;


@end

NS_ASSUME_NONNULL_END
