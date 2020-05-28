//
//  BJLIcDocumentWindowViewController.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class BJLRoom;

@interface BJLIcDocumentWindowViewController : BJLIcWindowViewController

@property (nonatomic, readonly) NSString *documentID;
@property (nonatomic, readonly) NSInteger pageIndex;
@property (nonatomic, copy, nullable) void (^documentWindowCloseCallback)(NSString *documentID);

- (instancetype)initWithRoom:(BJLRoom *)room documentID:(NSString *)documentID;

- (instancetype)init NS_UNAVAILABLE;

- (void)startObserverForLaserPointView:(UIView *)laserPointView;
- (void)stopObserverForLaserPointView;

@end

NS_ASSUME_NONNULL_END
