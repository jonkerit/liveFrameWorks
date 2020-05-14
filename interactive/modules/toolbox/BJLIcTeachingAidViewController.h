//
//  BJLIcTeachingAidViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/21.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcTeachingAidViewController : UIViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

// 打开网页
@property (nonatomic) void(^openWebViewCallback)(void);

// 小黑板
@property (nonatomic) void(^clickWritingBoardCallback)(void);

// 答题器
@property (nonatomic) void(^questionAnswerCallback)(void);

// 抢答题
@property (nonatomic) void(^questionResponderCallback)(void);

// 计时器
@property (nonatomic) void(^countDownCallback)(void);

// hiden
@property (nonatomic) void(^hideCallback)(void);

@end

NS_ASSUME_NONNULL_END
