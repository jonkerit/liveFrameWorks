//
//  BJLQuestionViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/1/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLViewControllerImports.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLQuestionViewController : BJLTableViewController <
UITableViewDataSource,
UITableViewDelegate,
BJLRoomChildViewController>

@property (nonatomic, nullable) void (^showMessageCallback)(NSString *message);
@property (nonatomic, nullable) void (^hideCallback)(void);

@end

NS_ASSUME_NONNULL_END
