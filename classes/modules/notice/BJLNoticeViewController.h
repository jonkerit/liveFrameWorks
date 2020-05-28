//
//  BJLNoticeViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-08.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

/** 学生角色，仅展示公告 & 通知 */
@interface BJLNoticeViewController : BJLScrollViewController <
UIScrollViewDelegate,
BJLRoomChildViewController>

@end

NS_ASSUME_NONNULL_END
