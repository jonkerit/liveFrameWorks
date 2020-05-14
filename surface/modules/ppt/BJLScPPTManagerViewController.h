//
//  BJLScPPTManagerViewController.h
//  BJLiveUI
//
//  Created by fanyi on 2019/9/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScPPTManagerViewController : BJLTableViewController

@property (nonatomic, copy, nullable) void (^uploadingCallback)(NSInteger failedCount, void (^ _Nullable retry)(void));

- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithRoom:(BJLRoom *)room NS_DESIGNATED_INITIALIZER;

- (void)startAllUploadingTasks;

@end

NS_ASSUME_NONNULL_END
