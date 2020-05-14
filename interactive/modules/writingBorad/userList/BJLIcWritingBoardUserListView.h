//
//  BJLIcWritingBoardUserListView.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BJLIcWritingBoardUserTableViewCellIdentifier;

@interface BJLIcWritingBoardUserListView : BJLHitTestView

@property (nonatomic, readonly) UITableView *tableView;

@property (nonatomic) void(^closeListCallBack)(void);

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
