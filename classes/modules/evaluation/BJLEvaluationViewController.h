//
//  BJLEvaluationViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/10/10.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLEvaluationViewController : BJLWebViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

@property (nonatomic, copy, nullable) void (^closeEvaluationCallback)(void);

@end

NS_ASSUME_NONNULL_END
