//
//  BJLScSpeakRequestUsersViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLTableViewController.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScSpeakRequestUsersViewController : BJLTableViewController

/**
 收到举手, 或者举手被处理的回调,count --> 当前举手用户数
 */
@property (nonatomic, nullable) void (^receiveSpeakingRequestCallback)( NSInteger count);

- (instancetype)initWithRoom:(BJLRoom *)room;

@end

NS_ASSUME_NONNULL_END
