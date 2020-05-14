//
//  BJLUserListViewController.h
//  BJLiveUI
//
//  Created by fanyi on 2019/7/11.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLTableViewController.h"
#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

/** 大班课新版在线用户列表，支持展示分组信息 */
@interface BJLUserListViewController : BJLTableViewController <UITableViewDataSource,
UITableViewDelegate,
BJLRoomChildViewController>

@property (nonatomic, copy, nullable) void (^errorCallback)(NSString *errorMessage);

@end

NS_ASSUME_NONNULL_END
