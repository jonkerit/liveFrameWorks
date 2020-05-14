//
//  BJLHeaderRefresh.h
//  BJLiveUI
//
//  Created by 辛亚鹏 on 2020/3/14.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLHeaderRefresh : UIRefreshControl

/// 实例化, 控件高度默认30
/// @param target target description
/// @param action action description
- (instancetype)initWithTargrt:(id)target action:(SEL)action;

/// 实例化
/// @param target target description
/// @param action action description
/// @param height 控件的高度, 即下拉多大距离后释放触发刷新,  可选范围: [30:60]
- (instancetype)initWithTargrt:(id)target action:(SEL)action height:(CGFloat)height;

/// 结束刷新
- (void)endRefreshing;

@end

NS_ASSUME_NONNULL_END
