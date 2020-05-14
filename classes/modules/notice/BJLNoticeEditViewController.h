//
//  BJLNoticeEditViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-08.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

/**
 老师/助教角色，仅可以对公告和通知进行编辑
 全体公告由大班助教/老师进行编辑，全部成员可见
 小组通知为组内成员可见，由分组的助教（小班老师）进行编辑，其他组不可见
 */

@interface BJLNoticeEditViewController : BJLScrollViewController <
UIScrollViewDelegate,
UITextFieldDelegate,
UITextViewDelegate,
BJLRoomChildViewController>

@property (nonatomic, copy, nullable) void (^errorCallback)(NSString *errorMessage);

@end

NS_ASSUME_NONNULL_END
