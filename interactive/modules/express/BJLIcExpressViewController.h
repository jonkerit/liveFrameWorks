//
//  BJLIcExpressViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/8/15.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLWebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcExpressViewController : BJLWebViewController

@property (nonatomic, nullable) void (^showExpressExportCallback)(void);

@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);

@property (nonatomic, nullable) void (^closeCallback)(void);

@property (nonatomic, nullable) void (^shareCallback)(NSString *contentURLString, NSString *firstExpressURLString, NSString *userName);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
